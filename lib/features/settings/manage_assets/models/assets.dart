import 'package:aqua/config/config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'assets.freezed.dart';
part 'assets.g.dart';

@freezed
class AssetsResponse with _$AssetsResponse {
  factory AssetsResponse({
    @JsonKey(name: 'QueryResponse') AssetsResponseItem? data,
  }) = _AssetsResponse;

  factory AssetsResponse.fromJson(Map<String, dynamic> json) =>
      _$AssetsResponseFromJson(json);
}

@freezed
class AssetsResponseItem with _$AssetsResponseItem {
  factory AssetsResponseItem({
    @Default([]) @JsonKey(name: 'Assets') List<Asset> assets,
  }) = _AssetsResponseItem;

  factory AssetsResponseItem.fromJson(Map<String, dynamic> json) =>
      _$AssetsResponseItemFromJson(json);
}

@freezed
class Asset with _$Asset {
  factory Asset({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Ticker') required String ticker,
    @JsonKey(name: 'Logo') required String logoUrl,
    @JsonKey(name: 'Default') @Default(false) bool isDefaultAsset,
    String? domain,
    @Default(0) int amount,
    @Default(8) int precision,
    @Default(false) bool isLiquid,
    @Default(false) bool isLBTC,
    @Default(false) bool isUSDt,
  }) = _Asset;

  factory Asset.btc({int amount = 0}) => Asset(
        name: 'Bitcoin',
        id: 'btc',
        ticker: 'BTC',
        logoUrl: Svgs.btcAsset,
        isDefaultAsset: true,
        isLiquid: false,
        isLBTC: false,
        isUSDt: false,
        amount: amount,
      );

  factory Asset.usdtEth({int amount = 0}) => Asset(
        name: 'Tether USDt',
        id: 'eth-usdt',
        ticker: 'USDt',
        logoUrl: Svgs.ethUsdtAsset,
        isDefaultAsset: false,
        isLiquid: false,
        isLBTC: false,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.usdtTrx({int amount = 0}) => Asset(
        name: 'Tether USDt',
        id: 'trx-usdt',
        ticker: 'USDt',
        logoUrl: Svgs.tronUsdtAsset,
        isLiquid: false,
        isDefaultAsset: false,
        isLBTC: false,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.lightning({int amount = 0}) => Asset(
      name: 'Lightning',
      id: 'lightning',
      ticker: 'Sats',
      logoUrl: Svgs.lightningAsset,
      isDefaultAsset: true,
      isLiquid: false,
      isLBTC: false,
      isUSDt: false,
      amount: amount,
      precision: 0);

  factory Asset.liquid() => Asset(
        logoUrl: Svgs.unknownAsset,
        id: '',
        name: '',
        ticker: '',
        isLiquid: true,
        isLBTC: true,
        isUSDt: false,
      );

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}

extension AssetExt on Asset {
  bool get isBTC => id == 'btc';

  bool get isLBTC => ticker == 'L-BTC';

  bool get isUsdtLiquid => isUSDt && isLiquid;

  bool get isLightning => this == Asset.lightning();

  bool get isSideshift => this == Asset.usdtEth() || this == Asset.usdtTrx();

  bool get isEth => this == Asset.usdtEth();

  bool get isTrx => this == Asset.usdtTrx();

  /// `isLayerTwo` only counts lightning or lbtc - no other liquid assets
  bool get isLayerTwo => isLightning || isLBTC;

  bool get isAnyUsdt => isUsdtLiquid || isEth || isTrx;

  bool get isUnknown => logoUrl == Svgs.unknownAsset;

  bool get selectable => !isBTC && !isLBTC && !isUSDt;

  bool get hasFiatRate => isBTC || isLBTC || isLightning;
}
