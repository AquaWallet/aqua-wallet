enum BoltzSwapStatus {
  created('swap.created'),
  transactionMempool('transaction.mempool'),
  transactionConfirmed('transaction.confirmed'),
  swapExpired('swap.expired'),
  swapRefunded('swap.refunded'),
  invoicePending('invoice.pending'),
  invoiceFailedToPay('invoice.failedToPay'),
  transactionLockupFailed('transaction.lockupFailed'),
  invoiceSettled('invoice.settled'),
  transactionClaimed('transaction.claimed');

  const BoltzSwapStatus(this.value);

  final String value;

  static BoltzSwapStatus? getByValue(String value) =>
      BoltzSwapStatus.values.firstWhere((status) => status.value == value);
}

extension SwapStatusExtension on BoltzSwapStatus {
  bool get isPending {
    return this == BoltzSwapStatus.created ||
        this == BoltzSwapStatus.invoicePending ||
        this == BoltzSwapStatus.transactionConfirmed ||
        this == BoltzSwapStatus.transactionMempool;
  }

  bool get isFailed {
    return this == BoltzSwapStatus.swapExpired ||
        this == BoltzSwapStatus.swapRefunded ||
        this == BoltzSwapStatus.invoiceFailedToPay ||
        this == BoltzSwapStatus.transactionLockupFailed;
  }

  bool get isSuccess {
    return this == BoltzSwapStatus.invoiceSettled ||
        this == BoltzSwapStatus.transactionClaimed;
  }

  bool get isFinal {
    return isFailed || isSuccess;
  }
}
