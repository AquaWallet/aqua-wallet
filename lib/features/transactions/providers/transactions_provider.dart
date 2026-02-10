import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.transactions);

final transactionsProvider = AsyncNotifierProvider.family
    .autoDispose<TransactionsNotifier, List<TransactionUiModel>, Asset>(
        TransactionsNotifier.new);

// Responsible for fetching and creating transaction UI models for a given asset.
//
// This provider orchestrates transaction builders which fetch and process:
// - Network transactions (from GDK)
// - Local database transactions
// - Pending swaps, pegs, and ghost transactions
class TransactionsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<TransactionUiModel>, Asset> {
  @override
  Future<List<TransactionUiModel>> build(Asset arg) async {
    final asset = arg;

    final assets = ref.watch(availableAssetsProvider).valueOrNull ?? [];
    final networkTxns =
        ref.watch(networkTransactionsProvider(asset)).valueOrNull ?? [];
    final localDbTxns = ref.watch(transactionStorageProvider).valueOrNull ?? [];

    _logger.debug('''
      Fetched transactions data:
      - ${networkTxns.length} network transactions
      - ${localDbTxns.length} local db transactions
      ''');

    final args = TransactionBuilderArgs(
      asset: asset,
      networkTxns: networkTxns,
      localDbTxns: localDbTxns,
      availableAssets: assets,
    );

    final items = await Future.wait([
      ref.read(pendingTransactionUiModelsProvider).build(args),
      ref.read(confirmedTransactionUiModelsProvider).build(args),
    ]);
    return items.expand((uiModels) => uiModels).toList();
  }

  /// Finds a Lightning transaction by matching it with a Boltz order's claimTxId.
  ///
  /// This method is used for Lightning receive transactions where the transaction
  /// ID is not immediately available but can be found through the Boltz order status.
  TransactionUiModel? findLightningTransactionWithBoltzOrder(
    String? boltzOrderId,
  ) {
    if (boltzOrderId == null) return null;

    final uiModels = state.valueOrNull;
    if (uiModels == null) return null;

    final boltzOrder = ref
        .read(boltzStorageProvider)
        .valueOrNull
        ?.firstWhereOrNull((order) => order.boltzId == boltzOrderId);

    if (boltzOrder?.claimTxId != null && boltzOrder!.claimTxId!.isNotEmpty) {
      return uiModels.firstWhereOrNull((t) {
        final transactionId = t.mapOrNull(
          normal: (model) => model.transaction.txhash,
          pending: (model) => model.dbTransaction?.txhash,
        );
        return transactionId == boltzOrder.claimTxId;
      });
    }

    return null;
  }
}
