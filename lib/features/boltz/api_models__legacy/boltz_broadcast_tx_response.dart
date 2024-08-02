/// Response body for `POST /broadcasttransaction`
class BoltzBroadcastTransactionResponse {
  final String transactionId;

  BoltzBroadcastTransactionResponse({required this.transactionId});

  factory BoltzBroadcastTransactionResponse.fromJson(
      Map<String, dynamic> json) {
    return BoltzBroadcastTransactionResponse(
      transactionId: json['transactionId'],
    );
  }
}

class BoltzBroadcastTransactionErrorResponse {
  final String error;
  final int timeoutEta;
  final int timeoutBlockHeight;

  BoltzBroadcastTransactionErrorResponse({
    required this.error,
    required this.timeoutEta,
    required this.timeoutBlockHeight,
  });

  factory BoltzBroadcastTransactionErrorResponse.fromJson(
      Map<String, dynamic> json) {
    return BoltzBroadcastTransactionErrorResponse(
      error: json['error'],
      timeoutEta: json['timeoutEta'],
      timeoutBlockHeight: json['timeoutBlockHeight'],
    );
  }
}
