/// Response body for `GET /getPairs`

class BoltzGetPairsResponse {
  final double reversePercentage;
  final int reverseClaimFee;
  final int reverseLockupFee;

  BoltzGetPairsResponse(
      {required this.reversePercentage,
      required this.reverseClaimFee,
      required this.reverseLockupFee});

  factory BoltzGetPairsResponse.fromJson(Map<String, dynamic> json) {
    return BoltzGetPairsResponse(
      reversePercentage: json['pairs']["L-BTC/BTC"]["fees"]["percentage"],
      reverseClaimFee: json['pairs']["L-BTC/BTC"]["fees"]["minerFees"]
          ["baseAsset"]["reverse"]["claim"],
      reverseLockupFee: json['pairs']["L-BTC/BTC"]["fees"]["minerFees"]
          ["baseAsset"]["reverse"]["lockup"],
    );
  }
}
