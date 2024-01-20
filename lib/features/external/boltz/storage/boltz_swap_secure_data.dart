class BoltzSwapSecureData {
  final String privateKeyHex;
  final String? preimageHex;

  BoltzSwapSecureData({required this.privateKeyHex, this.preimageHex});

  factory BoltzSwapSecureData.fromJson(Map<String, dynamic> json) {
    return BoltzSwapSecureData(
      privateKeyHex: json['privateKeyHex'],
      preimageHex: json['preimageHex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'privateKeyHex': privateKeyHex,
    };

    if (preimageHex != null) {
      data['preimageHex'] = preimageHex!;
    }

    return data;
  }
}
