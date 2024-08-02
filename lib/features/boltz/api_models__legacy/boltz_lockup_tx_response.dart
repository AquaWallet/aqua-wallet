import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_lockup_tx_response.freezed.dart';
part 'boltz_lockup_tx_response.g.dart';

@freezed
class LockupTransactionResponse with _$LockupTransactionResponse {
  const factory LockupTransactionResponse({
    required String transactionHex,
    required int timeoutBlockHeight,
    int?
        timeoutEta, // Optional since it may not be present if the HTLC has timed out
  }) = _LockupTransactionResponse;

  factory LockupTransactionResponse.fromJson(Map<String, dynamic> json) =>
      _$LockupTransactionResponseFromJson(json);
}
