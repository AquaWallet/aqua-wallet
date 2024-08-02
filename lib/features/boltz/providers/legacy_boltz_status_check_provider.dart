import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

@Deprecated(
    'Needed for pending legacy swaps. Can be removed after one app upgrade cycle')
final boltzStatusCheckProvider = Provider<BoltzStatusCheckService>((ref) {
  return BoltzStatusCheckService(ref);
});

/// Opens status check streams with boltz.exchange for all swaps in a `isPending` state, or needs a claim or refund
/// NOTE: This class just opens the streams. The updating of statuses and actions to take claims or refunds happens in [boltzDataProvider].
@Deprecated(
    'Needed for pending legacy swaps. Can be removed after one app upgrade cycle')
class BoltzStatusCheckService {
  final ProviderRef ref;

  BoltzStatusCheckService(this.ref);

  /// Fetch all incomplete boltz swaps and check their status
  Future<void> streamAllPendingSwaps() async {
    final normalSwaps = await ref
        .read(boltzDataProvider)
        .getAllSwaps(onlyIncompleteSwaps: true);
    final reverseSwaps = await ref
        .read(boltzDataProvider)
        .getAllReverseSwaps(onlyIncompleteSwaps: true);
    logger.d(
        "[BOLTZ] checkAllSwaps - fetch pending: ${normalSwaps.length} normal found - ${reverseSwaps.length} reverse found");

    // normal swaps

    // Note: For normal swaps, boltz does not monitor for refund txs. So if paying an invoice fails the boltz status will always be `invoiceFailedToPay` even
    // after we claimed the refund tx. Therefore we needs to check if we have a cached refundTx, and if yes, filter these out. In case the status is `invoiceFailedToPay` but
    // the refund tx fails, we need to filter these out after 336 hours so we don't constantly try to broadcast refund txs.
    final filteredNormalSwaps = normalSwaps
        .where((swap) =>
            (swap.swapStatus.isPending || swap.swapStatus.needsRefund) &&
            (swap.refundTx == null || swap.refundTx!.isEmpty) &&
            (swap.created == null ||
                (swap.created != null &&
                    DateTime.now().difference(swap.created!).inHours <=
                        336))) // swap.created == null accounts for previous version that didn't have this property
        .toList();

    for (final swap in filteredNormalSwaps) {
      final _ = ref
          .read(legacyBoltzProvider)
          .getLegacySwapStatusStream(swap.response.id, forceNewStream: true)
          .listen((event) {
        logger.d(
            "[BOLTZ] checkAllSwaps - normal swap status ${swap.response.id}: ${event.status}");
        if (event.status.needsRefund) {
          logger.d(
              "[BOLTZ] --- swap needs refund --- : ${swap.response.id}:: ${event.status}");
        }
      }, onError: (e) {
        logger.e(
            "[BOLTZ] checkAllSwaps - normal swap status error ${swap.response.id}: $e");
      });
    }

    // reverse swaps

    final filteredReverseSwaps = reverseSwaps
        .where((swap) =>
            (swap.swapStatus.isPending || swap.swapStatus.needsClaim) &&
            (swap.claimTx == null || swap.claimTx!.isEmpty) &&
            (swap.created == null ||
                (swap.created != null &&
                    DateTime.now().difference(swap.created!).inHours <= 72)))
        .toList();

    for (final swap in filteredReverseSwaps) {
      final _ = ref
          .read(legacyBoltzProvider)
          .getLegacySwapStatusStream(swap.response.id, forceNewStream: true)
          .listen((event) {
        logger.d(
            "[BOLTZ] checkAllSwaps - reverse swap status  ${swap.response.id}:: ${event.status}");
        if (event.status.needsClaim) {
          logger.d(
              "[BOLTZ] --- swap needs claim --- : ${swap.response.id}:: ${event.status}");
        }
      }, onError: (e) {
        logger.e(
            "[BOLTZ] checkAllSwaps - reverse swap status error ${swap.response.id}: $e");
      });
    }

    logger.d(
        "[BOLTZ] checkAllSwaps - filtered: ${filteredNormalSwaps.length} normal filtered - ${filteredReverseSwaps.length} reverse filtered");
  }

  /// Stream status check for a single swap
  Future<void> streamSingleSwapStatus(String swapId) async {
    final _ = ref
        .read(legacyBoltzProvider)
        .getLegacySwapStatusStream(swapId)
        .listen((event) {
      logger
          .d("[BOLTZ] checkSingleSwap - swap status $swapId: ${event.status}");
    }, onError: (e) {
      logger.e("[BOLTZ] checkSingleSwap - swap status error $swapId: $e");
    });
  }
}
