import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

final rawTransactionsProvider =
    StreamProvider.family<List<GdkTransaction>, Asset>((ref, asset) async* {
  final networkProvider = asset.isBTC ? bitcoinProvider : liquidProvider;
  final rawTxs = ref
      .read(networkProvider)
      .transactionEventSubject
      .startWith(null)
      .asyncMap((_) =>
          ref.read(networkProvider).getTransactions(requiresRefresh: true))
      .map((transactions) => transactions ?? []);

  if (!asset.isBTC) {
    yield* rawTxs.map((transactions) => transactions
        .where((transaction) => transaction.satoshi?[asset.id] != null)
        .toList());
  }

  yield* rawTxs;
});

final _rateStreamProvider = StreamProvider.autoDispose((ref) async* {
  yield* ref.read(fiatProvider).rateStream.distinctUnique();
});

final _currentBlockHeightProvider =
    StreamProvider.autoDispose.family<int, Asset>((ref, asset) {
  return asset.isBTC
      ? ref.read(bitcoinProvider).blockHeightEventSubject
      : ref.read(liquidProvider).blockHeightEventSubject;
});

final fiatAmountProvider = FutureProvider.autoDispose
    .family<String, TransactionUiModel>((ref, model) async {
  final rate = ref.watch(_rateStreamProvider).asData?.value;

  final fiats = ref.read(fiatProvider);
  if (rate != null) {
    final amount = model.map(
      normal: (model) => model.transaction.satoshi?[model.asset.id] as int,
      ghost: (model) => model.dbTransaction!.ghostTxnAmount!,
    );
    final fiat = fiats.satoshiToFiat(model.asset, amount, rate);
    final formattedFiat = fiats.formattedFiat(fiat);
    final currency = await fiats.currencyStream.first;
    return '$currency $formattedFiat';
  } else {
    return '';
  }
});

final transactionsProvider = FutureProvider.autoDispose
    .family<List<TransactionUiModel>, Asset>((ref, asset) async {
  final rawTxns = ref.watch(rawTransactionsProvider(asset)).asData?.value ?? [];
  final recordedTxns =
      ref.watch(transactionStorageProvider).asData?.value ?? [];
  final ghostTxns = recordedTxns.where((t) => t.isGhost).toList();

  // Ghost transactions that have been discovered by GDK and can now be removed
  final discoveredGhostTxns = ghostTxns.where((ghostTxn) {
    return rawTxns.any((rawTxn) => rawTxn.txhash == ghostTxn.txhash);
  });

  logger.d('[Transactions] '
      'Ghost: ${ghostTxns.length}, '
      'Discovered: ${discoveredGhostTxns.length}');

  // Unmark discovered ghost transactions
  for (final txn in discoveredGhostTxns) {
    logger.d('[Transactions] Unmarking ghost transaction: $txn');
    await ref
        .read(transactionStorageProvider.notifier)
        .save(txn.copyWith(isGhost: false));
  }

  final ghostTxnUiModels = ghostTxns
      .whereNot((ghostTxn) => discoveredGhostTxns.contains(ghostTxn))
      .where((ghostTxn) {
    //NOTE - Can't rely on asset ID matching for Boltz
    final isLightningGhostTxn = asset.isLayerTwo &&
        (ghostTxn.isBoltzReverseSwap || ghostTxn.isBoltzSwap);
    return ghostTxn.assetId == asset.id || isLightningGhostTxn;
  }).map((txn) {
    final createdAt = DateFormat.yMMMd().format(txn.ghostTxnCreatedAt!);
    final cryptoAmount = txn.ghostTxnAmount != null
        ? ref.read(formatterProvider).signedFormatAssetAmount(
              amount: txn.ghostTxnAmount!,
              precision: asset.precision,
            )
        : '-';
    // TODO: Add support for other transaction types as support grows
    final icon = switch (txn) {
      _ when (txn.isAquaSend) => Svgs.outgoing,
      _ when (txn.isBoltzSwap) => Svgs.outgoing,
      _ when (txn.isBoltzReverseSwap) => Svgs.incoming,
      _ => Svgs.exchange,
    };

    return TransactionUiModel.ghost(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      icon: icon,
      asset: asset,
      dbTransaction: txn,
    );
  });

  final rawTxnUiModels = await Future.wait(rawTxns.map((txn) async {
    final boltzSwapData =
        ref.watch(boltzSwapFromTxHashProvider(txn.txhash ?? '')).asData?.value;
    final boltzRevSwapData = ref
        .watch(boltzReverseSwapFromTxHashProvider(txn.txhash ?? ''))
        .asData
        ?.value;

    final dbTransaction = switch (null) {
      _ when (boltzSwapData != null) => TransactionDbModel.fromBoltzSwap(
          txhash: txn.txhash ?? '',
          assetId: asset.id,
          swap: boltzSwapData,
        ),
      _ when (boltzRevSwapData != null) => TransactionDbModel.fromBoltzRevSwap(
          txhash: txn.txhash ?? '',
          assetId: asset.id,
          swap: boltzRevSwapData,
        ),
      _ => recordedTxns.firstWhereOrNull((dbTxn) => dbTxn.txhash == txn.txhash),
    };

    final currentBlockHeight =
        ref.watch(_currentBlockHeightProvider(asset)).asData?.value ?? 0;
    final transactionBlockHeight = txn.blockHeight ?? 0;
    final confirmationCount = transactionBlockHeight == 0
        ? 0
        : currentBlockHeight - transactionBlockHeight + 1;
    final pending = asset.isBTC
        ? confirmationCount < onchainConfirmationBlockCount
        : confirmationCount < liquidConfirmationBlockCount;
    final assetIcon = switch (txn.type) {
      _ when (pending) => Svgs.pending,
      _ when (dbTransaction?.isBoltzSwap == true) => Svgs.outgoing,
      _ when (dbTransaction?.isBoltzReverseSwap == true) => Svgs.incoming,
      _ when (dbTransaction != null) => Svgs.exchange,
      GdkTransactionTypeEnum.incoming => Svgs.incoming,
      GdkTransactionTypeEnum.outgoing => Svgs.outgoing,
      GdkTransactionTypeEnum.redeposit ||
      GdkTransactionTypeEnum.swap =>
        Svgs.exchange,
      _ => throw AssetTransactionsInvalidTypeException(),
    };
    final createdAt = txn.createdAtTs != null
        ? DateFormat.yMMMd()
            .format(DateTime.fromMicrosecondsSinceEpoch(txn.createdAtTs!))
        : '';
    final formatter = ref.read(formatterProvider);
    final amount = txn.satoshi?[asset.id] as int;
    final formattedAmount = switch (txn.type) {
      GdkTransactionTypeEnum.swap ||
      GdkTransactionTypeEnum.incoming ||
      GdkTransactionTypeEnum.outgoing ||
      GdkTransactionTypeEnum.redeposit =>
        formatter.signedFormatAssetAmount(
          amount: amount,
          precision: asset.precision,
        ),
      _ => throw AssetTransactionsInvalidTypeException(),
    };
    final cryptoAmount = formattedAmount;

    final otherAsset = txn.type == GdkTransactionTypeEnum.swap
        ? () {
            final assets =
                ref.read(availableAssetsProvider).asData?.value ?? [];
            final otherAsset = asset.id == txn.swapOutgoingAssetId
                ? assets
                    .firstWhereOrNull((a) => a.id == txn.swapIncomingAssetId)
                : assets
                    .firstWhereOrNull((a) => a.id == txn.swapOutgoingAssetId);
            return otherAsset;
          }()
        : null;

    return TransactionUiModel.normal(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      icon: assetIcon,
      asset: asset,
      otherAsset: otherAsset,
      transaction: txn,
      dbTransaction: dbTransaction,
    );
  }).toList());

  return [...ghostTxnUiModels, ...rawTxnUiModels];
});

final completedTransactionProvider = FutureProvider.autoDispose
    .family<GdkTransaction, String>((ref, txId) async {
  final stream = ref.read(liquidProvider).transactionEventSubject;

  await for (var event in stream) {
    if (event != null && event.txhash == txId) {
      final transaction =
          await ref.read(_matchingTransactionProvider(txId).future);
      if (transaction == null) {
        throw AssetTransactionsBroadcastTxFetchException();
      }
      return Future.value(transaction);
    }
  }
  throw Exception("Transaction with txId $txId not found");
});

final _matchingTransactionProvider = FutureProvider.autoDispose
    .family<GdkTransaction?, String>((ref, txnId) async {
  final transactions =
      await ref.read(liquidProvider).getTransactions(requiresRefresh: true) ??
          [];
  return transactions.firstWhereOrNull((txn) => txnId == txn.txhash);
});

class AssetTransactionsInvalidTypeException implements Exception {}

class AssetTransactionsBroadcastTxFetchException implements Exception {}
