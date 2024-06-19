import 'package:aqua/features/boltz/api_models/boltz_api_models.dart';
import 'package:aqua/features/boltz/boltz_provider.dart';

/// Request body for `POST /createswap` type `normal`

class BoltzCreateSwapRequest {
  final SwapType type;
  final PairId pairId;
  final OrderSide orderSide;
  final String refundPublicKey;
  final String invoice;
  final String? pairHash;
  final String? referralId;

  BoltzCreateSwapRequest({
    required this.type,
    required this.pairId,
    required this.orderSide,
    required this.refundPublicKey,
    required this.invoice,
    this.pairHash,
    this.referralId = boltzReferralId,
  });

  factory BoltzCreateSwapRequest.fromJson(Map<String, dynamic> json) {
    return BoltzCreateSwapRequest(
      type: SwapType.values.firstWhere((e) => e.name == json['type']),
      pairId: PairId.values.firstWhere((e) => e.jsonValue == json['pairId']),
      orderSide:
          OrderSide.values.firstWhere((e) => e.name == json['orderSide']),
      refundPublicKey: json['refundPublicKey'] as String,
      invoice: json['invoice'] as String,
      pairHash: json['pairHash'] as String?,
      referralId: json['referralId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'type': type.name,
      'pairId': pairId.jsonValue,
      'orderSide': orderSide.name,
      'refundPublicKey': refundPublicKey,
      'invoice': invoice,
    };

    if (pairHash != null) {
      json['pairHash'] = pairHash;
    }

    if (referralId != null) {
      json['referralId'] = referralId;
    }

    return json;
  }
}
