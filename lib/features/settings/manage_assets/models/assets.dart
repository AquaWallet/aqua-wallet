import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'assets.freezed.dart';
part 'assets.g.dart';

class AssetIds {
  static const btc = 'btc';
  static const lightning = 'lightning';
  static const usdtEth = 'eth-usdt';
  static const usdtTrx = 'trx-usdt';
  static const usdtBep = 'bep-usdt';
  static const usdtSol = 'sol-usdt';
  static const usdtPol = 'pol-usdt';
  static const usdtTon = 'ton-usdt';

  static String getAssetId(AssetType type, LiquidNetworkEnumType networkType) {
    switch (type) {
      case AssetType.usdtliquid:
        return switch (networkType) {
          LiquidNetworkEnumType.mainnet =>
            'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2',
          LiquidNetworkEnumType.testnet =>
            'b612eb46313a2cd6ebabd8b7a8eed5696e29898b87a43bff41c94f51acef9d73',
          _ =>
            'a0682b2b1493596f93cea5f4582df6a900b5e1a491d5ac39dea4bb39d0a45bbf',
        };
      case AssetType.lbtc:
        return switch (networkType) {
          LiquidNetworkEnumType.mainnet =>
            '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d',
          _ =>
            '144c654344aa716d6f3abcc1ca90e5641e4e2a7f633bc09fe3baf64585819a49',
        };
      case AssetType.mexas:
        return switch (networkType) {
          LiquidNetworkEnumType.mainnet =>
            '26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e',
          _ =>
            '485ff8a902ad063bd8886ef8cfc0d22a068d14dcbe6ae06cf3f904dc581fbd2b',
        };
      case AssetType.depix:
        return switch (networkType) {
          LiquidNetworkEnumType.mainnet =>
            '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
          _ => '', // testnet currently not available
        };
      case AssetType.eurx:
        return switch (networkType) {
          LiquidNetworkEnumType.mainnet =>
            '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec',
          _ =>
            '58af36e1b529b42f3e4ccce812924380058cae18b2ad26c89805813a9db25980',
        };
    }
  }
}

enum AssetType { usdtliquid, lbtc, mexas, depix, eurx }

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

const kLayer2BitcoinId = 'Layer2Bitcoin';
const liquidId = 'LiquidBitcoin';

@freezed
class Asset with _$Asset {
  factory Asset({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Ticker') required String ticker,
    @JsonKey(name: 'Logo') required String logoUrl,
    @JsonKey(name: 'Default') @Default(false) bool isDefaultAsset,
    @JsonKey(name: 'IsRemovable') @Default(true) bool isRemovable,
    String? domain,
    @Default(0) int amount,
    @Default(8) int precision,
    @Default(false) bool isLiquid,
    @Default(false) bool isLBTC,
    @Default(false) bool isUSDt,
    @Default('') String displayUnitPrefix,
  }) = _Asset;

  factory Asset.usdtLiquid({int amount = 0}) => Asset(
        id: AssetIds.getAssetId(
            AssetType.usdtliquid, LiquidNetworkEnumType.mainnet),
        name: 'Liquid USDt',
        ticker: 'USDt',
        logoUrl: Svgs.usdtAsset,
        isLiquid: true,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.lbtc({int amount = 0}) => Asset(
        id: AssetIds.getAssetId(AssetType.lbtc, LiquidNetworkEnumType.mainnet),
        name: 'Liquid Bitcoin',
        ticker: 'L-BTC',
        logoUrl: Svgs.liquidAsset,
        isLiquid: true,
        isLBTC: true,
        amount: amount,
        displayUnitPrefix: 'L-',
      );

  factory Asset.btc({int amount = 0}) => Asset(
        name: 'Bitcoin',
        id: AssetIds.btc,
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
        id: AssetIds.usdtEth,
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
        id: AssetIds.usdtTrx,
        ticker: 'USDt',
        logoUrl: Svgs.tronUsdtAsset,
        isLiquid: false,
        isDefaultAsset: false,
        isLBTC: false,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.usdtBep({int amount = 0}) => Asset(
        name: 'Tether USDt',
        id: AssetIds.usdtBep,
        ticker: 'USDt',
        logoUrl: Svgs.bepUsdtAsset,
        isLiquid: false,
        isDefaultAsset: false,
        isLBTC: false,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.usdtSol({int amount = 0}) => Asset(
        name: 'Tether USDt',
        id: AssetIds.usdtSol,
        ticker: 'USDt',
        logoUrl: Svgs.solUsdtAsset,
        isLiquid: false,
        isDefaultAsset: false,
        isLBTC: false,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.usdtPol({int amount = 0}) => Asset(
        name: 'Tether USDt',
        id: AssetIds.usdtPol,
        ticker: 'USDt',
        logoUrl: Svgs.polUsdtAsset,
        isLiquid: false,
        isDefaultAsset: false,
        isLBTC: false,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.usdtTon({int amount = 0}) => Asset(
        name: 'Tether USDt',
        id: AssetIds.usdtTon,
        ticker: 'USDt',
        logoUrl: Svgs.tonUsdtAsset,
        isLiquid: false,
        isDefaultAsset: false,
        isLBTC: false,
        isUSDt: true,
        amount: amount,
      );

  factory Asset.lightning({int amount = 0}) => Asset(
        name: 'Lightning',
        id: AssetIds.lightning,
        ticker: 'Sats',
        logoUrl: Svgs.lightningAsset,
        isDefaultAsset: true,
        isLiquid: false,
        isLBTC: false,
        isUSDt: false,
        amount: amount,
        precision: 0,
      );

  // Testnet asset
  factory Asset.liquidTest() => Asset(
        logoUrl: Svgs.unknownAsset,
        id: '38fca2d939696061a8f76d4e6b5eecd54e3b4221c846f24a6b279e79952850a5',
        name: 'Testnet Asset',
        ticker: 'TEST',
        isDefaultAsset: true,
        isRemovable: true,
        isLiquid: true,
      );

  factory Asset.unknown() => Asset(
        logoUrl: Svgs.unknownAsset,
        id: '',
        name: '',
        ticker: '',
        isLiquid: false,
        isLBTC: false,
        isUSDt: false,
      );

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);
}

extension AssetExt on Asset {
  static String get lBtcMainnetTicker => 'L-BTC';
  static String get lBtcTestnetTicker => 'tL-BTC';

  bool get isBTC => id == AssetIds.btc;
  bool get isLBTC => ticker == lBtcMainnetTicker || ticker == lBtcTestnetTicker;
  bool get isLightning => this == Asset.lightning();

  bool get isSwappable => isBTC || isLBTC;
  bool get isInternal => isSwappable || isUsdtLiquid;

  /// `isLayerTwo` only counts lightning or lbtc - no other liquid assets
  bool get isLayerTwo => isLightning || isLBTC;

  /// any asset not denominated in sats
  bool get isNonSatsAsset => !isBTC && !isLBTC && !isLightning;

  bool get isUnknown => logoUrl == Svgs.unknownAsset;
  bool get selectable => !isBTC && !isLBTC && !isUSDt;
  bool get hasFiatRate => isBTC || isLBTC || isLightning;

  String get network => switch (this) {
        _ when isEth => 'Ethereum',
        _ when isTrx => 'Tron',
        _ when isBep => 'Binance',
        _ when isSol => 'Solana',
        _ when isPol => 'Polygon',
        _ when isTon => 'TON',
        _ => isBTC ? 'Bitcoin' : 'Liquid',
      };

  NetworkType get networkType =>
      isBTC ? NetworkType.bitcoin : NetworkType.liquid;

  FeeAsset get defaultFeeAsset => switch (this) {
        _ when (isBTC) => FeeAsset.btc,
        _ when (isAnyUsdt) => FeeAsset.tetherUsdt,
        _ => FeeAsset.lbtc,
      };

  // display name
  String get displayName {
    if (isBTC) return 'BTC';
    if (isLBTC) return 'L-BTC';
    if (isLightning) return 'Sats';
    if (isUSDt) return 'USDt';
    return ticker;
  }
}

extension AssetUsdtExt on Asset {
  int get usdtLiquidPrecision => 8;

  bool get isUsdtLiquid => isUSDt && isLiquid;

  bool get isEth => id == AssetIds.usdtEth;
  bool get isTrx => id == AssetIds.usdtTrx;
  bool get isBep => id == AssetIds.usdtBep;
  bool get isSol => id == AssetIds.usdtSol;
  bool get isPol => id == AssetIds.usdtPol;
  bool get isTon => id == AssetIds.usdtTon;

  bool get isAnyUsdt => isUsdtLiquid || isAltUsdt;
  bool get isAltUsdt => isEth || isTrx || isBep || isSol || isPol || isTon;

  UsdtOption get usdtOption {
    if (isUsdtLiquid) return UsdtOption.liquid;
    if (isEth) return UsdtOption.eth;
    if (isTrx) return UsdtOption.trx;
    if (isBep) return UsdtOption.bep;
    if (isSol) return UsdtOption.sol;
    if (isPol) return UsdtOption.pol;
    if (isTon) return UsdtOption.ton;
    return UsdtOption.trx;
  }

  // should show conversion
  bool get shouldShowConversionOnSend {
    return isBTC || isLBTC || isLightning;
  }

  // should LN/LQ toggle button
  bool get shouldLNLQToggleButton {
    return isLBTC || isLightning;
  }

  // allow usd toggle
  bool get shouldAllowUsdToggleOnSend {
    return isBTC || isLBTC;
  }

  // should show use all funds button
  bool get shouldShowUseAllFundsButton {
    return !isLightning;
  }

  // fee currency symbol
  String get feeCurrencySymbol {
    if (isUSDt) {
      return 'USDt';
    }
    return 'USD';
  }

  // provider name
  String get providerName {
    if (isLightning) {
      return 'Boltz';
    } else if (isAltUsdt) {
      return 'Shift';
    }
    return '';
  }
}

enum UsdtOption { liquid, trx, eth, bep, sol, ton, pol }

extension UsdtOptionExtension on UsdtOption {
  String networkLabel(BuildContext context) => switch (this) {
        UsdtOption.eth => context.loc.eth,
        UsdtOption.trx => context.loc.tron,
        UsdtOption.bep => context.loc.binance,
        UsdtOption.sol => context.loc.solana,
        UsdtOption.ton => context.loc.ton,
        UsdtOption.pol => context.loc.polygon,
        _ => context.loc.liquid,
      };
}

extension CompatibleExt on Asset {
  /// Returns true if the asset is compatible with the other asset, meaning we want to treat them as interchangeable in certain scenarios
  /// such as sending or receiving.
  bool isCompatibleWith(Asset other) {
    if (isLayerTwo) {
      return other.isLayerTwo;
    } else if (isBTC) {
      return other.isLightning || other.isBTC;
    } else if (isAnyUsdt) {
      return other.isAnyUsdt;
    } else {
      return this == other;
    }
  }

  bool get hasCompatibleAssets => isLayerTwo || isAnyUsdt;
}
