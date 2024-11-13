import 'package:freezed_annotation/freezed_annotation.dart';

/// See Boltz docs: https://docs.boltz.exchange/v/api/lifecycle
enum BoltzSwapStatus {
  created('swap.created'),
  transactionMempool('transaction.mempool'),
  transactionConfirmed('transaction.confirmed'),
  swapExpired('swap.expired'),
  swapRefunded('swap.refunded'),
  invoiceSet('invoice.set'),
  invoicePending('invoice.pending'),
  invoiceFailedToPay('invoice.failedToPay'),
  invoiceExpired('invoice.expired'),
  transactionLockupFailed('transaction.lockupFailed'),
  invoiceSettled('invoice.settled'),

  /// This is our own added state to indicate that we've successfully broadcasted the submarine swap tx,
  /// and we're waiting for a status update from Boltz.
  /// This is needed for the lowball no-mempool issue so we can mark send submarine lockup txs so we don't double-pay.
  submarineBroadcasted('submarine.broadcasted'),

  /// This status indicates that Boltz is ready for the creation of a cooperative signature for a keypath spend. Taproot Swaps are not claimed immediately by Boltz after the invoice has been paid, but instead Boltz waits for the API client to post a signature for a key path spend. If the API client does not cooperate in a key path spend, Boltz will eventually claim via the script path.
  transactionClaimPending('transaction.claim.pending'),
  transactionClaimed('transaction.claimed'),
  transactionRefunded('transaction.refunded'),

  /// "In the unlikely event that Boltz is unable to send the agreed amount of chain bitcoin after the user set up the payment to the provided Lightning invoice, the status of the swap will be transaction.failed and the pending Lightning HTLC will be cancelled. The Lightning bitcoin automatically bounce back to the user, no further action or refund is required and the user didn't pay any fees."
  transactionFailed('transaction.failed');

  const BoltzSwapStatus(this.value);

  final String value;

  static BoltzSwapStatus? getByValue(String value) =>
      BoltzSwapStatus.values.firstWhere((status) => status.value == value);
}

extension SwapStatusExtension on BoltzSwapStatus {
  /// A submarine swap before the initial lockup tx is sent
  bool get isSubmarineUnpaid {
    return this == BoltzSwapStatus.created ||
        this == BoltzSwapStatus.invoicePending ||
        this == BoltzSwapStatus.invoiceSet;
  }

  /// Pending state for normal or reverse swaps
  bool get isPending {
    return this == BoltzSwapStatus.created ||
        this == BoltzSwapStatus.invoicePending ||
        this == BoltzSwapStatus.invoiceSet ||
        this == BoltzSwapStatus.transactionConfirmed ||
        this == BoltzSwapStatus.transactionMempool ||
        this == BoltzSwapStatus.transactionClaimPending;
  }

  /// A reverse swap is ready for a claim tx
  bool get needsClaim {
    return this == BoltzSwapStatus.transactionConfirmed ||
        this == BoltzSwapStatus.transactionMempool ||
        this == BoltzSwapStatus.invoiceSettled;
  }

  /// A normal swap failed, and needs a refund
  bool get needsRefund {
    return this != BoltzSwapStatus.transactionClaimed &&
        (this == BoltzSwapStatus.invoiceFailedToPay ||
            this == BoltzSwapStatus.transactionLockupFailed ||
            this == BoltzSwapStatus.swapExpired);
  }

  bool get isFailed {
    return this == BoltzSwapStatus.swapExpired ||
        this == BoltzSwapStatus.swapRefunded ||
        this ==
            BoltzSwapStatus
                .invoiceFailedToPay || // `invoiceFailedToPay` state needs a refund, is not final
        this == BoltzSwapStatus.invoiceExpired ||
        this == BoltzSwapStatus.transactionLockupFailed ||
        this == BoltzSwapStatus.transactionRefunded ||
        this == BoltzSwapStatus.transactionFailed;
  }

  bool get isSuccess {
    return this == BoltzSwapStatus.invoiceSettled ||
        this == BoltzSwapStatus.transactionClaimed;
  }

  bool get isFinal {
    // swapExpired is not final, it needs a refund
    return isSuccess ||
        this == BoltzSwapStatus.swapRefunded ||
        this == BoltzSwapStatus.invoiceExpired ||
        this == BoltzSwapStatus.transactionRefunded ||
        this == BoltzSwapStatus.transactionClaimed ||
        this == BoltzSwapStatus.transactionFailed;
  }
}

class BoltzSwapStatusConverter
    implements JsonConverter<BoltzSwapStatus, String> {
  const BoltzSwapStatusConverter();

  @override
  BoltzSwapStatus fromJson(String json) {
    return BoltzSwapStatus.getByValue(json) ?? BoltzSwapStatus.created;
  }

  @override
  String toJson(BoltzSwapStatus status) {
    return status.value;
  }
}
