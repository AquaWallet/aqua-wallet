import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/marketplace/api_services/marketplace_service.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http; // For http.Response
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/market_place_service_mocks.dart';

class FakeEnvNotifier extends EnvNotifier {
  FakeEnvNotifier(super.prefs);
}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLiquidProvider extends Mock implements LiquidProvider {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late MockMarketplaceService mockMarketplaceService;

  const kLbtcId =
      '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';
  const kUsdtId =
      'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';

  setUp(() {
    mockMarketplaceService = MockMarketplaceService();
    final mockLiquidProvider = MockLiquidProvider();
    final mockSharedPreferences = MockSharedPreferences();

    when(() => mockLiquidProvider.policyAsset).thenReturn(kLbtcId);
    when(() => mockLiquidProvider.usdtId).thenReturn(kUsdtId);
    when(() => mockSharedPreferences.setStringList(any(), any()))
        .thenAnswer((_) async => true);

    container = ProviderContainer(overrides: [
      marketplaceServiceProvider.overrideWithValue(mockMarketplaceService),
      sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
      liquidProvider.overrideWithValue(mockLiquidProvider),
      envProvider.overrideWith((ref) => FakeEnvNotifier(mockSharedPreferences)),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  final assetsList = [
    Asset.fromJson({
      "Name": "Liquid Bitcoin",
      "Id": kLbtcId,
      "Ticker": "L-BTC",
      "Logo": "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/L-BTC.svg",
      "Default": true,
      "IsRemovable": false,
    }),
    Asset.fromJson({
      "Name": "Tether USDt",
      "Id": kUsdtId,
      "Ticker": "USDt",
      "Logo": "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/USDt.svg",
      "Default": true,
      "IsRemovable": true,
    }),
    Asset.fromJson({
      "Name": "PEGx EURx",
      "Id": "18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec",
      "Ticker": "EURx",
      "Logo": "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/EURx.svg",
      "Default": false,
      "IsRemovable": true,
    }),
    Asset.fromJson({
      "Name": "Mexas",
      "Id": "26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e",
      "Ticker": "MEX",
      "Logo": "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/MEX.svg",
      "Default": false,
      "IsRemovable": true,
    }),
    Asset.fromJson({
      "Name": "DePix",
      "Id": "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
      "Ticker": "DePix",
      "Logo": "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/DePix.svg",
      "Default": false,
      "IsRemovable": true,
    }),
  ];
  final mockAssetsJsonList = assetsList.map((r) => r.toJson()).toList();
  final assetsJson = {
    "QueryResponse": {"Assets": mockAssetsJsonList}
  };
  group('availableAssetsProvider', () {
    // This test ensures that the assets json format is correct
    // This format is used in the user settings and changing it will break the app for existing users.
    test('Asset.fromJson creates Asset object from JSON', () {
      final asset = Asset.fromJson(mockAssetsJsonList.first);
      expect(asset.id, kLbtcId);
      expect(asset.name, 'Liquid Bitcoin');
      expect(asset.ticker, 'L-BTC');
      expect(asset.logoUrl,
          'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/L-BTC.svg');
      expect(asset.isDefaultAsset, true);
      expect(asset.isRemovable, false);
    });

    test('fetches assets successfully from API', () async {
      // Stub the fetchAssets call to return a successful response with mock data

      when(() => mockMarketplaceService.fetchAssets()).thenAnswer(
        (_) async => Response(
          http.Response(
            jsonEncode(assetsJson),
            200,
          ),
          AssetsResponse.fromJson(assetsJson),
        ),
      );

      final result = await container.read(availableAssetsProvider.future);
      expect(container.read(availableAssetsProvider).value, [
        Asset(
          id: kLbtcId,
          name: 'Liquid Bitcoin',
          ticker: 'L-BTC',
          logoUrl:
              'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/L-BTC.svg',
          isDefaultAsset: true,
          isRemovable: false,
          domain: null,
          amount: 0,
          precision: 8,
          isLiquid: true,
          isLBTC: true,
          isUSDt: false,
        ),
        Asset(
          id: kUsdtId,
          name: 'Tether USDt',
          ticker: 'USDt',
          logoUrl:
              'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/USDt.svg',
          isDefaultAsset: true,
          isRemovable: true,
          domain: null,
          amount: 0,
          precision: 8,
          isLiquid: true,
          isLBTC: false,
          isUSDt: true,
        ),
        Asset(
          id: '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec',
          name: 'PEGx EURx',
          ticker: 'EURx',
          logoUrl:
              'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/EURx.svg',
          isDefaultAsset: false,
          isRemovable: true,
          domain: null,
          amount: 0,
          precision: 8,
          isLiquid: true,
          isLBTC: false,
          isUSDt: false,
        ),
        Asset(
          id: '26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e',
          name: 'Mexas',
          ticker: 'MEX',
          logoUrl:
              'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/MEX.svg',
          isDefaultAsset: false,
          isRemovable: true,
          domain: null,
          amount: 0,
          precision: 8,
          isLiquid: true,
          isLBTC: false,
          isUSDt: false,
        ),
        Asset(
          id: '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
          name: 'DePix',
          ticker: 'DePix',
          logoUrl:
              'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/DePix.svg',
          isDefaultAsset: false,
          isRemovable: true,
          domain: null,
          amount: 0,
          precision: 8,
          isLiquid: true,
          isLBTC: false,
          isUSDt: false,
        )
      ]);
      expect(result, isA<List<Asset>>());
      verify(() => mockMarketplaceService.fetchAssets())
          .called(1); // Verify API call
    });

    test('testnet function works when we are on another env', () async {
      container.read(envProvider.notifier).state = Env.testnet;
      container.invalidate(availableAssetsProvider);

      when(() => mockMarketplaceService.fetchTestNetAssets()).thenAnswer(
        (_) async => Response(
          http.Response(
            jsonEncode(assetsJson),
            200,
          ),
          AssetsResponse.fromJson(assetsJson),
        ),
      );
      var wasCalled = false;
      getStaticAssetFn = (ref) async {
        wasCalled = true;
        return assetsList;
      };

      final result = await container.read(availableAssetsProvider.future);

      expect(wasCalled, isFalse);
      expect(container.read(availableAssetsProvider).value?.length,
          assetsList.length + 1); //Testnet asset gets added by the code.
      expect(result, isA<List<Asset>>());

      verify(() => mockMarketplaceService.fetchTestNetAssets()).called(1);
      verifyNever(() => mockMarketplaceService.fetchAssets());
    });

    test('falls back to static assets on API failure', () async {
      var wasCalled = false;

      // Stub the service to simulate API failure
      when(() => mockMarketplaceService.fetchAssets()).thenAnswer(
        (_) async => Response(http.Response('error', 500), null),
      );

      //Replace real getStaticAssets function with fake
      getStaticAssetFn = (ref) async {
        wasCalled = true;
        return assetsList;
      };

      final result = await container.read(availableAssetsProvider.future);

      expect(wasCalled, isTrue);
      expect(result, isA<List<Asset>>());
      expect(container.read(availableAssetsProvider).value?.length,
          assetsList.length);
    });

    test('falls back to static assets on API failure for other env', () async {
      bool wasCalled = false;

      container.read(envProvider.notifier).state = Env.testnet;
      container.invalidate(availableAssetsProvider);

      when(() => mockMarketplaceService.fetchTestNetAssets()).thenAnswer(
        (_) async => Response(http.Response('error', 500), null),
      );
      getStaticAssetFn = (ref) async {
        wasCalled = true;
        return assetsList;
      };

      final result = await container.read(availableAssetsProvider.future);

      expect(wasCalled, isTrue);
      expect(result, isA<List<Asset>>());

      verify(() => mockMarketplaceService.fetchTestNetAssets()).called(1);
      verifyNever(() => mockMarketplaceService.fetchAssets());
    });
  });
}
