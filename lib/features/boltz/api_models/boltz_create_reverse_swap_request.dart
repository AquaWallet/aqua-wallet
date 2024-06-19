import 'package:aqua/features/boltz/api_models/boltz_api_models.dart';
import 'package:aqua/features/boltz/boltz_provider.dart';

/// Request body for `POST /createswap` type `reverse`

// Note: Not using @freezed because we need manual `toJson` and `fromJson` method for `PairId` resolution
class BoltzCreateReverseSwapRequest {
  final SwapType type;
  final PairId pairId;
  final OrderSide orderSide;
  final int invoiceAmount;
  final String claimPublicKey;
  final String preimageHash;
  final String? address;
  final String? addressSignature;
  final String? pairHash;
  final String? referralId;

  BoltzCreateReverseSwapRequest({
    required this.type,
    required this.pairId,
    required this.orderSide,
    required this.invoiceAmount,
    required this.claimPublicKey,
    required this.preimageHash,
    this.address,
    this.addressSignature,
    this.pairHash,
    this.referralId = boltzReferralId,
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
      address: json['address'] as String?,
      addressSignature: json['addressSignature'] as String?,
      pairHash: json['pairHash'] as String?,
      referralId: json['referralId'] as String?,
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

    if (address != null) json['address'] = address;
    if (addressSignature != null) json['addressSignature'] = addressSignature;
    if (pairHash != null) json['pairHash'] = pairHash;
    if (referralId != null) json['referralId'] = referralId;

    return json;
  }
}
