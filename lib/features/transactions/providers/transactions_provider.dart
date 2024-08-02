import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
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

final _transactionOtherAssetProvider = FutureProvider.autoDispose
    .family<Asset?, (Asset, GdkTransaction)>((ref, tuple) async {
  final asset = tuple.$1;
  final transaction = tuple.$2;

  if (transaction.type == GdkTransactionTypeEnum.swap) {
    final assets = ref.read(assetsProvider).asData?.value ?? [];

    if (asset.id == transaction.swapOutgoingAssetId) {
      final rawAsset = await ref
          .read(aquaProvider)
          .gdkRawAssetForAssetId(transaction.swapIncomingAssetId!);
      return assets.firstWhereOrNull((asset) => asset.id == rawAsset?.assetId);
    }

    final rawAsset = await ref
        .read(aquaProvider)
        .gdkRawAssetForAssetId(transaction.swapOutgoingAssetId!);
    return assets.firstWhereOrNull((asset) => asset.id == rawAsset?.assetId);
  }

  return null;
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
    final amount = model.transaction.satoshi?[model.asset.id] as int;
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
  final rawTransactions =
      ref.watch(rawTransactionsProvider(asset)).asData?.value ?? [];
  final recordedTransactions =
      ref.watch(transactionStorageProvider).asData?.value ?? [];

  return Future.wait(rawTransactions.mapIndexed((index, transaction) async {
    //TODO - Unify Boltz storage and DB storage
    final boltzSwapData = ref
        .watch(boltzSwapFromTxHashProvider(transaction.txhash ?? ''))
        .asData
        ?.value;
    final boltzRevSwapData = ref
        .watch(boltzReverseSwapFromTxHashProvider(transaction.txhash ?? ''))
        .asData
        ?.value;

    final dbTransaction = switch (null) {
      _ when (boltzSwapData != null) => TransactionDbModel.fromBoltzSwap(
          txhash: transaction.txhash ?? '',
          assetId: asset.id,
          swap: boltzSwapData,
        ),
      _ when (boltzRevSwapData != null) => TransactionDbModel.fromBoltzRevSwap(
          txhash: transaction.txhash ?? '',
          assetId: asset.id,
          swap: boltzRevSwapData,
        ),
      _ => recordedTransactions
          .firstWhereOrNull((dbTxn) => dbTxn.txhash == transaction.txhash),
    };

    final currentBlockHeight =
        ref.watch(_currentBlockHeightProvider(asset)).asData?.value ?? 0;
    final transactionBlockHeight = transaction.blockHeight ?? 0;
    final confirmationCount = transactionBlockHeight == 0
        ? 0
        : currentBlockHeight - transactionBlockHeight + 1;
    final pending = asset.isBTC
        ? confirmationCount < onchainConfirmationBlockCount
        : confirmationCount < liquidConfirmationBlockCount;
    final assetIcon = switch (transaction.type) {
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
    final createdAt = transaction.createdAtTs != null
        ? DateFormat.yMMMd().format(
            DateTime.fromMicrosecondsSinceEpoch(transaction.createdAtTs!))
        : '';
    final formatter = ref.read(formatterProvider);
    final amount = transaction.satoshi?[asset.id] as int;
    final formattedAmount = switch (transaction.type) {
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

    final otherAsset = ref
        .watch(_transactionOtherAssetProvider((asset, transaction)))
        .asData
        ?.value;

    return TransactionUiModel(
      createdAt: createdAt,
      cryptoAmount: cryptoAmount,
      icon: assetIcon,
      asset: asset,
      otherAsset: otherAsset,
      transaction: transaction,
      dbTransaction: dbTransaction,
    );
  }).toList());
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
