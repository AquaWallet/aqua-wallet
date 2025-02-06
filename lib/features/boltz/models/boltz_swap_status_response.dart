import 'package:aqua/features/boltz/models/boltz_swap_status.dart';
import 'package:aqua/features/boltz/models/boltz_transaction.dart';

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
