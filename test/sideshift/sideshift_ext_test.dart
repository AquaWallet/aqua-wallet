import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua/features/sideshift/models/sideshift_ext.dart';
import 'package:aqua/features/sideshift/models/sideshift_assets.dart';

void main() {
  group('SideshiftAssetSwapExt', () {
    test('toSwapAsset converts LBTC correctly', () {
      final sideshiftAsset = SideshiftAsset(
        id: 'btc',
        coin: 'L-BTC',
        network: 'liquid',
        name: 'Liquid Bitcoin',
      );

      final swapAsset = sideshiftAsset.toSwapAsset();

      expect(
          swapAsset.id,
          equals(AssetIds.getAssetId(
              AssetType.lbtc, LiquidNetworkEnumType.mainnet)));
      expect(swapAsset.name, equals('Liquid Bitcoin'));
      expect(swapAsset.ticker, equals('L-BTC'));
    });

    test('toSwapAsset converts USDT Liquid correctly', () {
      final sideshiftAsset = SideshiftAsset(
        id: 'usdt',
        coin: 'USDt',
        network: 'liquid',
        name: 'Liquid Tether',
      );

      final swapAsset = sideshiftAsset.toSwapAsset();

      expect(
          swapAsset.id,
          equals(AssetIds.getAssetId(
              AssetType.usdtliquid, LiquidNetworkEnumType.mainnet)));
      expect(swapAsset.name, equals('Liquid Tether'));
      expect(swapAsset.ticker, equals('USDt'));
    });

    test('toSwapAsset converts regular asset correctly', () {
      final sideshiftAsset = SideshiftAsset(
        id: 'eth',
        coin: 'ETH',
        network: 'ethereum',
        name: 'Ethereum',
      );

      final swapAsset = sideshiftAsset.toSwapAsset();

      expect(swapAsset.id, equals('eth'));
      expect(swapAsset.name, equals('Ethereum'));
      expect(swapAsset.ticker, equals('ETH'));
    });

    test('fromSwapAsset converts LBTC correctly', () {
      final swapAsset = SwapAsset(
        id: AssetIds.getAssetId(AssetType.lbtc, LiquidNetworkEnumType.mainnet),
        name: 'Liquid Bitcoin',
        ticker: 'L-BTC',
      );

      final sideshiftAsset = SideshiftAssetSwapExt.fromSwapAsset(swapAsset);

      expect(sideshiftAsset.id, equals('btc'));
      expect(sideshiftAsset.name, equals('Liquid Bitcoin'));
      expect(sideshiftAsset.coin, equals('L-BTC'));
      expect(sideshiftAsset.network, equals('liquid'));
    });

    test('fromSwapAsset converts USDT Liquid correctly', () {
      final swapAsset = SwapAsset(
        id: AssetIds.getAssetId(
            AssetType.usdtliquid, LiquidNetworkEnumType.mainnet),
        name: 'Liquid Tether',
        ticker: 'USDt',
      );

      final sideshiftAsset = SideshiftAssetSwapExt.fromSwapAsset(swapAsset);

      expect(sideshiftAsset.id, equals('usdt'));
      expect(sideshiftAsset.name, equals('Liquid Tether'));
      expect(sideshiftAsset.coin, equals('USDt'));
      expect(sideshiftAsset.network, equals('liquid'));
    });
  });
}
