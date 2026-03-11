import 'package:aqua/data/data.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PegSidesLookup = ({
  GdkTransaction? sendTxn,
  GdkTransaction? receiveTxn,
});

final pegSwapMatcherProvider = Provider.autoDispose<PegSwapMatcher>(
  (ref) => const PegSwapMatcher(),
);

/// Bidirectional matcher for peg transactions.
///
/// Matches incoming transactions to their corresponding peg orders:
/// - BTC incoming → peg-out order (LBTC→BTC) → creates BTC receive side
/// - LBTC incoming → peg-in order (BTC→LBTC) → creates LBTC receive side
class PegSwapMatcher {
  const PegSwapMatcher();

  /// Looks up both sides of a peg transaction.
  ///
  /// Given a peg order and the network transactions for both sides,
  /// finds the send and receive transactions for fee calculation.
  PegSidesLookup lookupPegSides({
    required TransactionDbModel pegOrder,
    required List<GdkTransaction> sendNetworkTxns,
    required List<GdkTransaction> receiveNetworkTxns,
  }) {
    const noMatch = (sendTxn: null, receiveTxn: null);

    if (!pegOrder.isPeg || pegOrder.receiveAddress == null) {
      return noMatch;
    }

    // Find send transaction by txhash first, fallback to deposit address match
    var sendTxn = sendNetworkTxns.firstWhereOrNull(
      (t) => t.txhash == pegOrder.txhash,
    );

    // Fallback: match by deposit address (serviceAddress) if txhash lookup failed
    if (sendTxn == null && pegOrder.serviceAddress != null) {
      sendTxn = sendNetworkTxns.firstWhereOrNull((t) {
        final outputAddresses = t.outputs
                ?.where((o) => o.address != null && o.address!.isNotEmpty)
                .map((o) => o.address!)
                .toList() ??
            [];
        return outputAddresses.contains(pegOrder.serviceAddress);
      });
    }

    // Find receive transaction by matching output address
    final receiveTxn = receiveNetworkTxns.firstWhereOrNull((t) {
      final outputAddresses = t.outputs
              ?.where((o) => o.address != null && o.address!.isNotEmpty)
              .map((o) => o.address!)
              .toList() ??
          [];
      return outputAddresses.contains(pegOrder.receiveAddress);
    });

    return (sendTxn: sendTxn, receiveTxn: receiveTxn);
  }
}
