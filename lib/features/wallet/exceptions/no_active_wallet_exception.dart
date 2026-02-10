class NoActiveWalletException implements Exception {
  final String message;
  const NoActiveWalletException([this.message = 'No active wallet']);
  @override
  String toString() => 'NoActiveWalletException: $message';
}
