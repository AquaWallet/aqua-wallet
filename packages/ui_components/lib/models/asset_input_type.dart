enum AquaAssetInputType {
  crypto,
  fiat,
}

extension AquaAssetInputTypeX on AquaAssetInputType {
  bool get isCrypto => this == AquaAssetInputType.crypto;
  bool get isFiat => this == AquaAssetInputType.fiat;
}
