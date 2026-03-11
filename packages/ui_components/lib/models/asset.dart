//NOTE - Ideally, should use the Asset from the Aqua Dev or have it moved to a
//separate aqua-core package

import 'package:ui_components/shared/shared.dart';

class AssetUiModel {
  AssetUiModel({
    required this.assetId,
    required this.name,
    required this.subtitle,
    required this.amount,
    this.amountFiat,
    this.iconUrl,
    this.standard,
    this.isUSDt = false,
    this.isLBTC = false,
  });

  final String assetId;
  final String name;
  final String subtitle;
  final String amount;
  final String? amountFiat;
  final String? iconUrl;
  final String? standard;
  final bool isUSDt;
  final bool isLBTC;

  AssetUiModel copyWith({
    String? assetId,
    String? name,
    String? subtitle,
    String? amount,
    String? amountFiat,
    String? iconUrl,
    String? standard,
    bool? isUSDt,
    bool? isLBTC,
  }) =>
      AssetUiModel(
        assetId: assetId ?? this.assetId,
        name: name ?? this.name,
        subtitle: subtitle ?? this.subtitle,
        amount: amount ?? this.amount,
        amountFiat: amountFiat ?? this.amountFiat,
        iconUrl: iconUrl ?? this.iconUrl,
        standard: standard ?? this.standard,
        isUSDt: isUSDt ?? this.isUSDt,
        isLBTC: isLBTC ?? this.isLBTC,
      );
}

extension AssetUiModelX on AssetUiModel {
  bool get isRemoteIcon =>
      (iconUrl?.isNotEmpty ?? false) &&
      switch (assetId) {
        AssetIds.layer2 || _ when (AssetIds.lbtc.contains(assetId)) => false,
        AssetIds.btc => false,
        _ when (AssetIds.lbtc.contains(assetId)) => false,
        AssetIds.lightning => false,
        AssetIds.usdtEth => false,
        _ when (AssetIds.usdtliquid.contains(assetId)) => false,
        AssetIds.usdtTrx => false,
        AssetIds.usdtBep => false,
        AssetIds.usdtSol => false,
        AssetIds.usdtPol => false,
        AssetIds.usdtTon => false,
        AssetIds.usdtTether => false,
        _ => true,
      };
}
