import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/constants.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/providers/peg_storage_provider.dart';
import 'package:coin_cz/features/swaps/providers/swap_storage_provider.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/logger.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

final _logger = CustomLogger(FeatureFlag.transactions);

final transactionsProvider = AsyncNotifierProvider.family
    .autoDispose<TransactionsNotifier, List<TransactionUiModel>, Asset>(
        TransactionsNotifier.new);

/// `rawTxns` are the transactions that are returned by the network provider
/// `recordedTxns` are the transactions that are stored locally in the database
/// `ghostTxns` are the transactions that are marked as ghost in the database
/// `pendingSettlementSwapTxns` are the transactions that are pending swaps
/// `pendingSettlementPegTxns` are the transactions that are pending pegs
class TransactionsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<TransactionUiModel>, Asset> {
  @override
  Future<List<TransactionUiModel>> build(Asset arg) async {
    final asset = arg;

    // - Fetch various transaction data
    final networkTxns =
        ref.watch(networkTransactionsProvider(asset)).asData?.value ?? [];
    final localDbTxns =
        ref.watch(transactionStorageProvider).asData?.value ?? [];
    final ghostTxns = localDbTxns.where((t) => t.isGhost).toList();

    //HERE - AWAITs TWICE
    final pendingSettlementSwapTxns =
        await _fetchPendingSettlementSwapTransactions(asset);
    final pendingSettlementPegTxns =
        await _fetchPendingSettlementPegTransactions();
    _logger.debug('''
      Fetched transactions data:
      - ${networkTxns.length} network transactions
      - ${localDbTxns.length} local db transactions
      - ${ghostTxns.length} ghost transactions
      - ${pendingSettlementPegTxns.length} pending peg transactions
      - ${pendingSettlementSwapTxns.length} pending swap transactions
      ''');

    //HERE - AWAITs
    // - Discover and unmark ghost transactions
    final discoveredGhostTxns = await _discoverAndUnmarkGhostTransactions(
      ghostTxns,
      networkTxns,
    );

    // - Create ghost transaction UI models
    final combinedGhostTxns = [
      ...pendingSettlementPegTxns,
      ...pendingSettlementSwapTxns,
      ...ghostTxns,
    ];
    _logger.debug(
        "Combined ghost transactions count: ${combinedGhostTxns.length}");

    final ghostTxnUiModels = combinedGhostTxns
        .whereNot((ghostTxn) => discoveredGhostTxns.contains(ghostTxn))
        .where((ghostTxn) => _filterGhostTxnsToDisplay(ghostTxn, asset))
        .map((ghostTxn) => _createGhostTxTransactionUiModel(ghostTxn, asset))
        .where((uiModel) => uiModel != null)
        .cast<TransactionUiModel>()
        .toList();

    // - Create raw transaction UI models
    final rawTxnUiModels = await _createRawTransactionUiModels(
      networkTxns,
      localDbTxns,
      asset,
    );

    _logger.debug(
        "Total transactions UI models created: ${ghostTxnUiModels.length + rawTxnUiModels.length}");
    return [...ghostTxnUiModels, ...rawTxnUiModels];
  }

  Future<List<TransactionDbModel>> _fetchPendingSettlementSwapTransactions(
      Asset asset) async {
    final pendingSettlementSwapOrders = await ref
        .read(swapStorageProvider.notifier)
        .getPendingSettlementSwapsForAssets(
          settleAsset: asset,
        );
    return pendingSettlementSwapOrders
        .map((order) => TransactionDbModel.fromSwapOrderDbModel(order))
        .toList();
  }

  Future<List<TransactionDbModel>>
      _fetchPendingSettlementPegTransactions() async {
    final pendingPegOrders = await ref
        .read(pegStorageProvider.notifier)
        .getAllPendingSettlementPegOrders();
    return pendingPegOrders
        .map((order) => TransactionDbModel.fromPegOrderDbModel(order)
            .copyWith(isGhost: true, ghostTxnAmount: order.amount))
        .toList();
  }

  Future<List<TransactionDbModel>> _discoverAndUnmarkGhostTransactions(
    List<TransactionDbModel> ghostTxns,
    List<GdkTransaction> networkTxns,
  ) async {
    final discoveredGhostTxns = ghostTxns.where((ghostTxn) {
      return networkTxns
          .any((networkTxn) => networkTxn.txhash == ghostTxn.txhash);
    }).toList();

    _logger.debug(
        "Discovered ${discoveredGhostTxns.length} ghost transactions to unmark");

    for (final txn in discoveredGhostTxns) {
      await ref
          .read(transactionStorageProvider.notifier)
          .save(txn.copyWith(isGhost: false));
      _logger.debug("Unmarked ghost transaction: ${txn.txhash}");
    }

    return discoveredGhostTxns;
  }

  Future<List<TransactionUiModel>> _createRawTransactionUiModels(
    List<GdkTransaction> networkTxns,
    List<TransactionDbModel> localDbTxns,
    Asset asset,
  ) async {
    return await Future.wait(networkTxns.map((txn) async {
      final dbTransaction =
          localDbTxns.firstWhereOrNull((dbTxn) => dbTxn.txhash == txn.txhash);

      final confirmationCount = await ref
          .watch(aquaProvider)
          .getConfirmationCount(
              asset: asset, transactionBlockHeight: txn.blockHeight ?? 0)
          .first;

      final isPending = confirmationCount <
          (asset.isBTC
              ? onchainConfirmationBlockCount
              : liquidConfirmationBlockCount);

      final assetIcon = switch (txn.type) {
        _ when (isPending) => Svgs.pending,
        _ when (dbTransaction?.isTopUp == true) => Svgs.creditCard,
        _ when (dbTransaction?.isAquaSend == true) => Svgs.outgoing,
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
  }

  bool _filterGhostTxnsToDisplay(TransactionDbModel ghostTxn, Asset asset) {
    // Filter for ghost transactions to show for this asset
    // NOTE: swaps will be filtered for settle asset because in the db model the settle asset is stored as assetId
    final isCurrentAssetGhostTxn = ghostTxn.assetId == asset.id;
    final isLightningGhostTxn = asset.isLayerTwo &&
        (ghostTxn.isBoltzReverseSwap || ghostTxn.isBoltzSwap);
    final isPegOutGhostTxn = asset.isBTC && ghostTxn.isPegOut;
    final isPegInGhostTxn = asset.isLBTC && ghostTxn.isPegIn;
    return isCurrentAssetGhostTxn ||
        isLightningGhostTxn ||
        isPegOutGhostTxn ||
        isPegInGhostTxn;
  }

  TransactionUiModel? _createGhostTxTransactionUiModel(
      TransactionDbModel ghostTxn, Asset asset) {
    try {
      final formatter = ref.read(formatterProvider);
      final assetPrecision = asset.precision;

      final createdAt = DateFormat.yMMMd().format(ghostTxn.ghostTxnCreatedAt!);
      final cryptoAmount = ghostTxn.ghostTxnAmount != null
          ? formatter.signedFormatAssetAmount(
              amount: ghostTxn.ghostTxnAmount!,
              precision: assetPrecision,
            )
          : '-';
      final icon = switch (ghostTxn) {
        _ when (ghostTxn.isTopUp) => Svgs.creditCard,
        _ when (ghostTxn.isAquaSend) => Svgs.outgoing,
        _ when (ghostTxn.isBoltzSwap) => Svgs.outgoing,
        _ when (ghostTxn.isBoltzReverseSwap) => Svgs.incoming,
        _ => Svgs.exchange,
      };

      return TransactionUiModel.ghost(
        createdAt: createdAt,
        cryptoAmount: cryptoAmount,
        icon: icon,
        asset: asset,
        dbTransaction: ghostTxn,
      );
    } catch (e, st) {
      _logger.error("Error creating ghost transaction UI model", e, st);
      return null;
    }
  }
}

// -----------------------------------------------------------------------------------
// --- Helper Providers ----------------------------------------------------------------
// -----------------------------------------------------------------------------------
final _rateStreamProvider = StreamProvider.autoDispose((ref) async* {
  yield* ref.read(fiatProvider).rateStream.distinctUnique();
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
    final fiat = fiats.satoshiToFiat(model.asset, amount, rate.$1);
    final formattedFiat = fiats.formattedFiat(fiat);
    return '${rate.$2} $formattedFiat';
  } else {
    return '';
  }
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
