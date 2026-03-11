/// Text strings required by [AquaSwapTransactionSummary].
///
/// This class encapsulates all the Text strings needed by the transaction
/// summary component, making it independent of any specific Text system.
class TransactionSummaryText {
  const TransactionSummaryText({
    required this.from,
    required this.to,
  });

  final String from;
  final String to;
}
