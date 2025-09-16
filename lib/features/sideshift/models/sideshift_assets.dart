import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:coin_cz/features/swaps/models/swap_models.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/data/provider/liquid_provider.dart';

part 'sideshift_assets.freezed.dart';
part 'sideshift_assets.g.dart';

@freezed
class SideshiftAssetResponse with _$SideshiftAssetResponse {
  factory SideshiftAssetResponse({
    required String coin,
    required List<String> networks,
    required String name,
    bool? hasMemo,
  }) = _SideshiftAssetResponse;

  factory SideshiftAssetResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftAssetResponseFromJson(json);
}

@freezed
class SideshiftAsset with _$SideshiftAsset {
  factory SideshiftAsset({
    required String id,
    required String coin,
    required String network,
    required String name,
    bool? hasMemo,
  }) = _SideshiftAsset;

  /// Create from a SideshiftAssetResponse
  factory SideshiftAsset.create(
    SideshiftAssetResponse response, {
    required String network,
  }) {
    return SideshiftAsset(
      id: '${response.coin.toLowerCase()}-${network.toLowerCase()}',
      coin: response.coin,
      network: network,
      name: response.name,
      hasMemo: response.hasMemo,
    );
  }

  // Factory instances for USDT coins
  factory SideshiftAsset.usdtEth() => SideshiftAsset(
        id: 'usdt-ethereum',
        coin: 'USDT',
        network: 'ethereum',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtTron() => SideshiftAsset(
        id: 'usdt-tron',
        coin: 'USDT',
        network: 'tron',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtBep() => SideshiftAsset(
        id: 'usdt-bsc',
        coin: 'USDT',
        network: 'bsc',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtSol() => SideshiftAsset(
        id: 'usdt-solana',
        coin: 'USDT',
        network: 'solana',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtPol() => SideshiftAsset(
        id: 'usdt-polygon',
        coin: 'USDT',
        network: 'polygon',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtTon() => SideshiftAsset(
        id: 'usdt-ton',
        coin: 'USDT',
        network: 'ton',
        name: 'Tether',
      );

  factory SideshiftAsset.usdtLiquid() => SideshiftAsset(
        id: 'usdt-liquid',
        coin: 'USDT',
        network: 'liquid',
        name: 'Tether',
      );

  factory SideshiftAsset.bitcoin() => SideshiftAsset(
        id: 'btc-bitcoin',
        coin: 'BTC',
        network: 'bitcoin',
        name: 'Bitcoin',
      );
}

extension SideshiftAssetExt on SideshiftAsset {
  static SideshiftAsset fromSwapAsset(SwapAsset asset) {
    switch (asset.id) {
      case AssetIds.usdtEth:
        return SideshiftAsset.usdtEth();
      case AssetIds.usdtTrx:
        return SideshiftAsset.usdtTron();
      case AssetIds.usdtBep:
        return SideshiftAsset.usdtBep();
      case AssetIds.usdtSol:
        return SideshiftAsset.usdtSol();
      case AssetIds.usdtPol:
        return SideshiftAsset.usdtPol();
      case AssetIds.usdtTon:
        return SideshiftAsset.usdtTon();
      default:
        if (asset.id ==
            AssetIds.getAssetId(
                AssetType.usdtliquid, LiquidNetworkEnumType.mainnet)) {
          return SideshiftAsset.usdtLiquid();
        } else if (asset.id == AssetIds.btc) {
          return SideshiftAsset.bitcoin();
        } else {
          throw ArgumentError('Unsupported SwapAsset: ${asset.id}');
        }
    }
  }

  static String getNetworkString(String assetId) {
    if (assetId ==
            AssetIds.getAssetId(
                AssetType.lbtc, LiquidNetworkEnumType.mainnet) ||
        assetId ==
            AssetIds.getAssetId(
                AssetType.usdtliquid, LiquidNetworkEnumType.mainnet)) {
      return 'liquid';
    }

    switch (assetId) {
      case AssetIds.usdtEth:
        return 'ethereum';
      case AssetIds.usdtTrx:
        return 'tron';
      case AssetIds.usdtBep:
        return 'bsc';
      case AssetIds.usdtSol:
        return 'solana';
      case AssetIds.usdtPol:
        return 'polygon';
      case AssetIds.usdtTon:
        return 'ton';
      case AssetIds.btc:
        return 'bitcoin';
      default:
        if (assetId ==
            AssetIds.getAssetId(
                AssetType.usdtliquid, LiquidNetworkEnumType.mainnet)) {
          return 'liquid';
        } else {
          throw ArgumentError('Unsupported asset ID: $assetId');
        }
    }
  }
}

@freezed
class SideshiftAssetPair with _$SideshiftAssetPair {
  const factory SideshiftAssetPair({
    required SideshiftAsset from,
    required SideshiftAsset to,
  }) = _SideshiftAssetPair;
}

@freezed
class SideShiftAssetPairInfo with _$SideShiftAssetPairInfo {
  const factory SideShiftAssetPairInfo({
    required String rate,
    required String min,
    required String max,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
  }) = _SideShiftAssetPairInfo;

  factory SideShiftAssetPairInfo.fromJson(Map<String, dynamic> json) =>
      _$SideShiftAssetPairInfoFromJson(json);
}
