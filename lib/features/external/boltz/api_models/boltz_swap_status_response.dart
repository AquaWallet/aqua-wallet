import 'package:aqua/features/external/boltz/api_models/boltz_swap_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_swap_status_response.freezed.dart';
part 'boltz_swap_status_response.g.dart';

/// Response for `POST /swapstatus`
class BoltzSwapStatusResponse {
  final BoltzSwapStatus status;
  final BoltzTransaction? transaction;
  final String? failureReason;

  BoltzSwapStatusResponse({
    required this.status,
    this.transaction,
    this.failureReason,
  });

  factory BoltzSwapStatusResponse.fromJson(Map<String, dynamic> json) {
    return BoltzSwapStatusResponse(
      status:
          BoltzSwapStatus.values.firstWhere((e) => e.value == json['status']),
      transaction: json['transaction'] != null
          ? BoltzTransaction.fromJson(json['transaction'])
          : null,
      failureReason: json['failureReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'status': status.value,
    };

    if (transaction != null) {
      json['transaction'] = transaction!.toJson();
    }

    if (failureReason != null) {
      json['failureReason'] = failureReason;
    }

    return json;
  }
}

@freezed
class BoltzTransaction with _$BoltzTransaction {
  const factory BoltzTransaction({
    required String id,
    final String? hex,
    final int? eta,
    final bool? zeroConfRejected,
  }) = _BoltzTransaction;

  factory BoltzTransaction.fromJson(Map<String, dynamic> json) =>
      _$BoltzTransactionFromJson(json);
}
