import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_assets.dart';

class MockAutoDisposeRef extends Mock implements AutoDisposeRef {}

class MockLiquidProvider extends Mock implements LiquidProvider {}

final mockSwapAssets = [
  SideSwapAsset(assetId: lbtcAsset.id),
  SideSwapAsset(assetId: usdtAsset.id),
  SideSwapAsset(assetId: infAsset.id),
  SideSwapAsset(assetId: jpysAsset.id),
  SideSwapAsset(assetId: eurxAsset.id),
  SideSwapAsset(assetId: mexAsset.id),
  SideSwapAsset(assetId: depixAsset.id),
];

void main() {
  late SwapAssetsNotifier notifier;
  late MockAutoDisposeRef mockRef;
  late MockLiquidProvider mockLiquidProvider;

  setUp(() {
    mockRef = MockAutoDisposeRef();
    mockLiquidProvider = MockLiquidProvider();

    when(() => mockLiquidProvider.depixId).thenReturn(depixAsset.id);
    when(() => mockLiquidProvider.eurXId).thenReturn(eurxAsset.id);
    when(() => mockLiquidProvider.mexasId).thenReturn(mexAsset.id);

    when(() => mockRef.read(liquidProvider)).thenReturn(mockLiquidProvider);
    when(() => mockRef.watch(assetsProvider)).thenReturn(AsyncValue.data([
      btcAsset,
      lbtcAsset,
      usdtAsset,
      infAsset,
      jpysAsset,
      eurxAsset,
      mexAsset,
      depixAsset,
    ]));

    notifier = SwapAssetsNotifier(mockRef);
    notifier.addAssets(mockSwapAssets);
  });

  group('SwapAssetsNotifier', () {
    test('isSwappable returns true for valid swap pairs', () {
      expect(notifier.isSwappable(btcAsset, lbtcAsset), true);
      expect(notifier.isSwappable(lbtcAsset, btcAsset), true);
    });

    test('isSwappable returns false for invalid swap pairs', () {
      expect(notifier.isSwappable(btcAsset, usdtAsset), false);
      expect(notifier.isSwappable(usdtAsset, btcAsset), false);
    });

    group('swappableAssets', () {
      test('returns correct assets for BTC', () {
        final swappableAssets = notifier.swappableAssets(btcAsset);
        expect(swappableAssets, [lbtcAsset]);
      });

      test('returns correct assets for L-BTC', () {
        when(() => mockLiquidProvider.depixId).thenReturn(depixAsset.id);
        when(() => mockLiquidProvider.eurXId).thenReturn(eurxAsset.id);
        when(() => mockLiquidProvider.mexasId).thenReturn(mexAsset.id);

        final swappableAssets = notifier.swappableAssets(lbtcAsset);
        expect(swappableAssets, [btcAsset, usdtAsset, depixAsset, eurxAsset]);
      });

      test('returns correct assets for USDt', () {
        final swappableAssets = notifier.swappableAssets(usdtAsset);
        expect(swappableAssets, [lbtcAsset]);
      });

      test('returns correct assets for DEPIX and EURX', () {
        when(() => mockLiquidProvider.depixId).thenReturn(depixAsset.id);
        when(() => mockLiquidProvider.eurXId).thenReturn(eurxAsset.id);

        expect(notifier.swappableAssets(depixAsset), [lbtcAsset]);
        expect(notifier.swappableAssets(eurxAsset), [lbtcAsset]);
      });

      test('returns empty list for unsupported assets', () {
        final unsupportedAsset = Asset(
          id: 'unsupported',
          name: 'Unsupported',
          ticker: 'UNSUPPORTED',
          logoUrl: '',
        );

        final swappableAssets = notifier.swappableAssets(unsupportedAsset);
        expect(swappableAssets, isEmpty);
      });

      test('returns empty list for null asset', () {
        final swappableAssets = notifier.swappableAssets(null);
        expect(swappableAssets, isEmpty);
      });
    });
  });
}
