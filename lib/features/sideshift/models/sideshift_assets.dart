import 'package:freezed_annotation/freezed_annotation.dart';

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

  /// Factory instances for USDT coins
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

  factory SideshiftAsset.usdtLiquid() => SideshiftAsset(
        id: 'usdt-liquid',
        coin: 'USDT',
        network: 'liquid',
        name: 'Tether',
      );
}

@freezed
class SideshiftAssetPair with _$SideshiftAssetPair {
  const factory SideshiftAssetPair({
    required SideshiftAsset from,
    required SideshiftAsset to,
  }) = _SideshiftAssetPair;

  // Factory methods for predefined pairs
  factory SideshiftAssetPair.fromUsdtLiquidToUsdtEth() => SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(), to: SideshiftAsset.usdtEth());

  factory SideshiftAssetPair.fromUsdtLiquidToUsdtTron() => SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(), to: SideshiftAsset.usdtTron());

  factory SideshiftAssetPair.fromUsdtEthToUsdtLiquid() => SideshiftAssetPair(
      from: SideshiftAsset.usdtEth(), to: SideshiftAsset.usdtLiquid());

  factory SideshiftAssetPair.fromUsdtTronToUsdtLiquid() => SideshiftAssetPair(
      from: SideshiftAsset.usdtTron(), to: SideshiftAsset.usdtLiquid());
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
