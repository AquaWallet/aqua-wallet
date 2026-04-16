/// Exception thrown when a transaction is not found in the database
class TransactionNotFoundException implements Exception {
  final String txHash;
  final String? walletId;

  TransactionNotFoundException(this.txHash, {this.walletId});

  @override
  String toString() =>
      'TransactionNotFoundException: Transaction $txHash not found${walletId != null ? ' in wallet $walletId' : ''}';
}
