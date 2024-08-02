import 'package:aqua/features/boltz/boltz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'boltz_claim_data.freezed.dart';
part 'boltz_claim_data.g.dart';

/// Data that needs to be passed to `claim()` function to be able to broadcast the claim tx
@freezed
class BoltzClaimData with _$BoltzClaimData {
  const factory BoltzClaimData({
    required String id,
    @Default('L-BTC') String asset,
    required String redeemScript,
    required String privateKey,
    required String? preimage,
    required String onchainAddress,
    required String blindingKey,
    required int feeBudget,
    required String
        transaction, // This is retrieved from the boltz `transaction.mempool` swap status update
  }) = _BoltzClaimData;

  factory BoltzClaimData.fromJson(Map<String, dynamic> json) =>
      _$BoltzClaimDataFromJson(json);

  factory BoltzClaimData.fromReverseSwapData(
      BoltzReverseSwapData reverseSwapData, String mempoolTx, int feeBudget) {
    return BoltzClaimData(
      id: reverseSwapData.response.id,
      redeemScript: reverseSwapData.response.redeemScript,
      privateKey: reverseSwapData.secureData.privateKeyHex,
      preimage: reverseSwapData.secureData.preimageHex,
      onchainAddress: reverseSwapData.response.lockupAddress,
      blindingKey: reverseSwapData.response.blindingKey,
      feeBudget: feeBudget,
      transaction: mempoolTx,
    );
  }
}
