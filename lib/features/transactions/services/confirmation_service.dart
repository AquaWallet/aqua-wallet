import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/models/peg_status_state.dart';
import 'package:aqua/features/sideswap/providers/peg_storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final confirmationServiceProvider = Provider.autoDispose((ref) {
  return ConfirmationService(
    ref.read(aquaProvider),
    ref.read(pegStorageProvider.notifier),
  );
});

// Handles confirmation count logic and pending state determination
//
// This service centralizes all logic related to transaction confirmations
// and determining whether a transaction should be considered pending.
class ConfirmationService {
  const ConfirmationService(
    this.aquaProvider,
    this.pegStorage,
  );

  final AquaProvider aquaProvider;
  final PegOrderStorageNotifier pegStorage;

  Future<int> getConfirmationCount(Asset asset, int blockHeight) => aquaProvider
      .getConfirmationCount(
        asset: asset,
        transactionBlockHeight: blockHeight,
      )
      .first;

  int getRequiredConfirmationCount(Asset asset) {
    return asset.isBTC
        ? onchainConfirmationBlockCount
        : liquidConfirmationBlockCount;
  }

  // Determines if a transaction is still pending
  //
  // Checks both confirmation count and special statuses (e.g., peg orders)
  // Works for all transaction types: incoming, outgoing, swaps, redeposits
  Future<bool> isTransactionPending({
    required GdkTransaction transaction,
    required Asset asset,
    TransactionDbModel? dbTransaction,
  }) async {
    final confirmationCount = await getConfirmationCount(
      asset,
      transaction.blockHeight ?? 0,
    );
    final requiredCount = getRequiredConfirmationCount(asset);
    final isEnoughConfirmations = confirmationCount >= requiredCount;

    // For peg transactions, also check peg status - they should remain pending until status is 'done'
    final isPegOrder = dbTransaction?.isPeg == true;
    final pegOrderId = dbTransaction?.serviceOrderId;
    if (!isPegOrder || pegOrderId == null) {
      // For non-peg transactions, verifying confirmation count is enough
      return !isEnoughConfirmations;
    }
    final pegOrder = await pegStorage.getOrderById(pegOrderId);
    if (pegOrder == null) {
      return !isEnoughConfirmations;
    }
    final consolidatedStatus = pegOrder.status.getConsolidatedStatus();
    final status = PegStatusState(consolidatedStatus: consolidatedStatus);

    return !isEnoughConfirmations || status.isPending;
  }
}
