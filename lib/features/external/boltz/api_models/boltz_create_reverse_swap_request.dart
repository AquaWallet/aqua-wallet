import 'package:aqua/features/external/boltz/api_models/boltz_api_models.dart';

/// Request body for `POST /createswap` type `reverse`

// Note: Not using @freezed because we need manual `toJson` and `fromJson` method for `PairId` resolution
class BoltzCreateReverseSwapRequest {
  final SwapType type;
  final PairId pairId;
  final OrderSide orderSide;
  final int invoiceAmount;
  final String claimPublicKey;
  final String preimageHash;
  final String? pairHash;

  BoltzCreateReverseSwapRequest({
    required this.type,
    required this.pairId,
    required this.orderSide,
    required this.invoiceAmount,
    required this.claimPublicKey,
    required this.preimageHash,
    this.pairHash,
  });

  factory BoltzCreateReverseSwapRequest.fromJson(Map<String, dynamic> json) {
    return BoltzCreateReverseSwapRequest(
      type: SwapType.values.firstWhere((e) => e.name == json['type']),
      pairId: PairId.values.firstWhere((e) => e.jsonValue == json['pairId']),
      orderSide:
          OrderSide.values.firstWhere((e) => e.name == json['orderSide']),
      invoiceAmount: json['invoiceAmount'] as int,
      claimPublicKey: json['claimPublicKey'] as String,
      preimageHash: json['preimageHash'] as String,
      pairHash: json['pairHash'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'type': type.name,
      'pairId': pairId.jsonValue,
      'orderSide': orderSide.name,
      'invoiceAmount': invoiceAmount,
      'claimPublicKey': claimPublicKey,
      'preimageHash': preimageHash,
    };

    if (pairHash != null) {
      json['pairHash'] = pairHash;
    }

    return json;
  }
}
