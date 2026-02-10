import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';

final confirmedTransactionUiModelsProvider = Provider.autoDispose((ref) {
  return ConfirmedTransactionUiModelsBuilder(
    confirmationService: ref.read(confirmationServiceProvider),
    strategyFactory: ref.read(transactionUiModelsFactoryProvider),
    pegStorage: ref.read(pegStorageProvider.notifier),
  );
});

// Builds confirmed transaction UI models
//
// This builder processes incoming, outgoing, and redeposit transactions
// that have sufficient confirmations and are not in pending state.
class ConfirmedTransactionUiModelsBuilder implements TransactionUiModelBuilder {
  const ConfirmedTransactionUiModelsBuilder({
    required this.confirmationService,
    required this.strategyFactory,
    required this.pegStorage,
  });

  final ConfirmationService confirmationService;
  final TransactionStrategyFactory strategyFactory;
  final PegOrderStorage pegStorage;

  @override
  Future<List<TransactionUiModel>> build(TransactionBuilderArgs args) async {
    final uiModels = <TransactionUiModel>[];
    final pegOrders =
        args.asset.isSwappable ? await pegStorage.getAllPegOrders() : null;

    for (final txn in args.networkTxns) {
      TransactionDbModel? dbTxn =
          args.localDbTxns.firstWhereOrNull((t) => t.txhash == txn.txhash);

      // Check if this transaction matches a direct peg-in order
      if (dbTxn == null && pegOrders != null) {
        final pegOrder = pegOrders.findMatchingOrder(
          transactionId: txn.txhash!,
          asset: args.asset,
          outputs: txn.outputs,
        );
        if (pegOrder != null) {
          dbTxn = TransactionDbModel.fromPegOrderDbModel(
            pegOrder,
            walletId: pegOrder.walletId ?? '',
          );
        }
      }

      final isPending = await confirmationService.isTransactionPending(
        transaction: txn,
        asset: args.asset,
        dbTransaction: dbTxn,
      );

      if (isPending) {
        // No-op: Skip because still pending (not enough confirmations)
        continue;
      }

      if (txn.type != GdkTransactionTypeEnum.swap &&
          txn.type != GdkTransactionTypeEnum.incoming &&
          txn.type != GdkTransactionTypeEnum.outgoing &&
          txn.type != GdkTransactionTypeEnum.redeposit) {
        // No-op: Skip if the transaction is not a valid type
        continue;
      }

      final strategy = strategyFactory.create(
        dbTransaction: dbTxn,
        networkTransaction: txn,
        asset: args.asset,
      );

      final transactionArgs = TransactionStrategyArgs(
        asset: args.asset,
        availableAssets: args.availableAssets,
        dbTransaction: dbTxn,
        networkTransaction: txn,
      );
      final baseUiModel = strategy.createConfirmedListItems(transactionArgs);
      if (baseUiModel == null) {
        continue;
      }

      final uiModel = baseUiModel.applyFeeTransactionFlag(
        txn,
        args.asset,
        args.availableAssets,
      );
      uiModels.add(uiModel);
    }

    return uiModels;
  }
}
