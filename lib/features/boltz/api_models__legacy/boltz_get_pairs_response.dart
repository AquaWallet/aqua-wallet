/// Response body for `GET /getPairs`
class BoltzGetPairsResponse {
  final double reversePercentage;
  final int reverseClaimFee;
  final int reverseLockupFee;
  final int normalFee;

  BoltzGetPairsResponse(
      {required this.reversePercentage,
      required this.reverseClaimFee,
      required this.reverseLockupFee,
      required this.normalFee});

  factory BoltzGetPairsResponse.fromJson(Map<String, dynamic> json) {
    return BoltzGetPairsResponse(
      reversePercentage: json['pairs']["L-BTC/BTC"]["fees"]["percentage"],
      reverseClaimFee: json['pairs']["L-BTC/BTC"]["fees"]["minerFees"]
          ["baseAsset"]["reverse"]["claim"],
      reverseLockupFee: json['pairs']["L-BTC/BTC"]["fees"]["minerFees"]
          ["baseAsset"]["reverse"]["lockup"],
      normalFee: json['pairs']["L-BTC/BTC"]["fees"]["minerFees"]["baseAsset"]
          ["normal"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pairs': {
        "L-BTC/BTC": {
          "fees": {
            "percentage": reversePercentage,
            "minerFees": {
              "baseAsset": {
                "reverse": {
                  "claim": reverseClaimFee,
                  "lockup": reverseLockupFee,
                },
                "normal": normalFee,
              }
            }
          }
        }
      }
    };
  }
}
