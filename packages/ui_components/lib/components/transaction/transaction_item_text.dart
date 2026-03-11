/// Text strings required by [AquaTransactionItem].
///
/// This class encapsulates all the Text strings needed by the transaction
/// item component, making it independent of any specific Text system.
class TransactionItemText {
  const TransactionItemText({
    required this.failed,
    required this.insufficientFunds,
    required this.addFunds,
    required this.redeposited,
    required this.refund,
    required this.toppingUp,
    required this.sending,
    required this.sent,
    required this.receiving,
    required this.received,
    required this.swapping,
    required this.swapped,
  });

  final String failed;
  final String insufficientFunds;
  final String addFunds;
  final String redeposited;
  final String refund;
  final String toppingUp;
  final String sending;
  final String sent;
  final String receiving;
  final String received;
  final String swapping;
  final String swapped;
}
