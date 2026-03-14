import 'dart:convert';

import 'package:aqua/config/constants/svgs.dart';
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

  group('ManageAssetsProvider', () {
    late MockUserPreferencesNotifier mockPrefs;

    const kEurxId =
        '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec';
    const kMexId =
        '26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e';
    const kUnknownId =
        '8a4053ef1b2f3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d';

    final curatedAssets = [
      Asset(
        id: kLbtcId,
        name: 'Liquid Bitcoin',
        ticker: 'L-BTC',
        logoUrl:
            'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/L-BTC.svg',
        isDefaultAsset: true,
        isRemovable: false,
        isLiquid: true,
        isLBTC: true,
      ),
      Asset(
        id: kUsdtId,
        name: 'Tether USDt',
        ticker: 'USDt',
        logoUrl:
            'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/USDt.svg',
        isDefaultAsset: true,
        isRemovable: true,
        isLiquid: true,
        isUSDt: true,
      ),
      Asset(
        id: kEurxId,
        name: 'PEGx EURx',
        ticker: 'EURx',
        logoUrl:
            'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/EURx.svg',
        isRemovable: true,
        isLiquid: true,
      ),
    ];

    final discoveredAssetsList = [
      Asset(
        id: kUnknownId,
        name: 'SomeToken',
        ticker: 'STK',
        logoUrl: Svgs.unknownAsset,
        precision: 8,
        isLiquid: true,
        isRemovable: true,
        amount: 100000,
      ),
    ];

    setUp(() {
      mockPrefs = MockUserPreferencesNotifier();
    });

    test('userAssets returns assets matching user pref IDs', () {
      when(() => mockPrefs.userAssetIds)
          .thenReturn([kLbtcId, kUsdtId, kEurxId]);

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        [],
      );

      expect(provider.userAssets.length, 3);
      expect(provider.userAssets.first.id, kLbtcId);
    });

    test('availableAssets excludes already enabled assets', () {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId, kUsdtId]);

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        [],
      );

      // EURx is removable and not in userAssetIds, so it should be available
      expect(provider.availableAssets.length, 1);
      expect(provider.availableAssets.first.id, kEurxId);
    });

    test('enabledDiscoveredAssets returns empty when no discovered prefs', () {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId]);
      when(() => mockPrefs.discoveredAssetIds).thenReturn([]);

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        discoveredAssetsList,
      );

      expect(provider.enabledDiscoveredAssets, isEmpty);
    });

    test('enabledDiscoveredAssets returns matching discovered assets', () {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId]);
      when(() => mockPrefs.discoveredAssetIds).thenReturn([kUnknownId]);

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        discoveredAssetsList,
      );

      expect(provider.enabledDiscoveredAssets.length, 1);
      expect(provider.enabledDiscoveredAssets.first.id, kUnknownId);
      expect(provider.enabledDiscoveredAssets.first.ticker, 'STK');
    });

    test('enabledDiscoveredAssets ignores IDs not in discovered list', () {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId]);
      when(() => mockPrefs.discoveredAssetIds)
          .thenReturn(['nonexistent_asset_id']);

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        discoveredAssetsList,
      );

      expect(provider.enabledDiscoveredAssets, isEmpty);
    });

    test('addDiscoveredAsset delegates to prefs', () async {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId]);
      when(() => mockPrefs.discoveredAssetIds).thenReturn([]);
      when(() => mockPrefs.addDiscoveredAsset(any()))
          .thenAnswer((_) async {});

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        discoveredAssetsList,
      );

      await provider.addDiscoveredAsset(discoveredAssetsList.first);

      verify(() => mockPrefs.addDiscoveredAsset(kUnknownId)).called(1);
    });

    test('removeDiscoveredAsset delegates to prefs', () async {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId]);
      when(() => mockPrefs.discoveredAssetIds).thenReturn([kUnknownId]);
      when(() => mockPrefs.removeDiscoveredAsset(any()))
          .thenAnswer((_) async {});

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        discoveredAssetsList,
      );

      await provider.removeDiscoveredAsset(discoveredAssetsList.first);

      verify(() => mockPrefs.removeDiscoveredAsset(kUnknownId)).called(1);
    });

    test('discoveredAssets field is accessible', () {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId]);

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        discoveredAssetsList,
      );

      expect(provider.discoveredAssets.length, 1);
      expect(provider.discoveredAssets.first.id, kUnknownId);
    });

    test('discoveredAssets empty when no non-curated assets exist', () {
      when(() => mockPrefs.userAssetIds).thenReturn([kLbtcId]);

      final provider = ManageAssetsProvider(
        Env.mainnet,
        mockPrefs,
        curatedAssets,
        [],
      );

      expect(provider.discoveredAssets, isEmpty);
    });
  });

  group('discoveredAssetsProvider', () {
    const kUnknownAssetId =
        '8a4053ef1b2f3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d';

    test('returns empty list when all balances are curated', () async {
      final mockLiquidProvider = MockLiquidProvider();
      final mockSharedPreferences = MockSharedPreferences();

      when(() => mockLiquidProvider.policyAsset).thenReturn(kLbtcId);
      when(() => mockLiquidProvider.usdtId).thenReturn(kUsdtId);
      when(() => mockLiquidProvider.getBalance(requiresRefresh: false))
          .thenAnswer((_) async => {
                kLbtcId: 50000,
                kUsdtId: 100000,
              });
      when(() => mockSharedPreferences.setStringList(any(), any()))
          .thenAnswer((_) async => true);

      when(() => mockMarketplaceService.fetchAssets()).thenAnswer(
        (_) async => Response(
          http.Response(jsonEncode(assetsJson), 200),
          AssetsResponse.fromJson(assetsJson),
        ),
      );

      final testContainer = ProviderContainer(overrides: [
        marketplaceServiceProvider.overrideWithValue(mockMarketplaceService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        liquidProvider.overrideWithValue(mockLiquidProvider),
        envProvider
            .overrideWith((ref) => FakeEnvNotifier(mockSharedPreferences)),
      ]);

      addTearDown(testContainer.dispose);

      // First resolve availableAssetsProvider so discoveredAssetsProvider can use it
      await testContainer.read(availableAssetsProvider.future);
      final result =
          await testContainer.read(discoveredAssetsProvider.future);

      expect(result, isEmpty);
    });

    test('returns discovered assets for non-curated balances', () async {
      final mockLiquidProvider = MockLiquidProvider();
      final mockSharedPreferences = MockSharedPreferences();

      when(() => mockLiquidProvider.policyAsset).thenReturn(kLbtcId);
      when(() => mockLiquidProvider.usdtId).thenReturn(kUsdtId);
      when(() => mockLiquidProvider.getBalance(requiresRefresh: false))
          .thenAnswer((_) async => {
                kLbtcId: 50000,
                kUsdtId: 100000,
                kUnknownAssetId: 75000,
              });
      when(() => mockLiquidProvider.allRawAssets).thenReturn({
        kUnknownAssetId: const GdkAssetInformation(
          name: 'Some Token',
          ticker: 'STK',
          precision: 8,
        ),
      });
      when(() => mockSharedPreferences.setStringList(any(), any()))
          .thenAnswer((_) async => true);

      when(() => mockMarketplaceService.fetchAssets()).thenAnswer(
        (_) async => Response(
          http.Response(jsonEncode(assetsJson), 200),
          AssetsResponse.fromJson(assetsJson),
        ),
      );

      final testContainer = ProviderContainer(overrides: [
        marketplaceServiceProvider.overrideWithValue(mockMarketplaceService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        liquidProvider.overrideWithValue(mockLiquidProvider),
        envProvider
            .overrideWith((ref) => FakeEnvNotifier(mockSharedPreferences)),
      ]);

      addTearDown(testContainer.dispose);

      await testContainer.read(availableAssetsProvider.future);
      final result =
          await testContainer.read(discoveredAssetsProvider.future);

      expect(result.length, 1);
      expect(result.first.id, kUnknownAssetId);
      expect(result.first.name, 'Some Token');
      expect(result.first.ticker, 'STK');
      expect(result.first.logoUrl, Svgs.unknownAsset);
      expect(result.first.isLiquid, true);
      expect(result.first.isRemovable, true);
      expect(result.first.amount, 75000);
    });

    test('excludes policy asset from discovered assets', () async {
      final mockLiquidProvider = MockLiquidProvider();
      final mockSharedPreferences = MockSharedPreferences();

      when(() => mockLiquidProvider.policyAsset).thenReturn(kLbtcId);
      when(() => mockLiquidProvider.usdtId).thenReturn(kUsdtId);
      // Balance only has policy asset (which is already curated anyway)
      // and an unknown asset with zero balance
      when(() => mockLiquidProvider.getBalance(requiresRefresh: false))
          .thenAnswer((_) async => {
                kLbtcId: 50000,
                kUnknownAssetId: 0,
              });
      when(() => mockSharedPreferences.setStringList(any(), any()))
          .thenAnswer((_) async => true);

      when(() => mockMarketplaceService.fetchAssets()).thenAnswer(
        (_) async => Response(
          http.Response(jsonEncode(assetsJson), 200),
          AssetsResponse.fromJson(assetsJson),
        ),
      );

      final testContainer = ProviderContainer(overrides: [
        marketplaceServiceProvider.overrideWithValue(mockMarketplaceService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        liquidProvider.overrideWithValue(mockLiquidProvider),
        envProvider
            .overrideWith((ref) => FakeEnvNotifier(mockSharedPreferences)),
      ]);

      addTearDown(testContainer.dispose);

      await testContainer.read(availableAssetsProvider.future);
      final result =
          await testContainer.read(discoveredAssetsProvider.future);

      expect(result, isEmpty);
    });

    test('uses truncated ID as name when GDK has no metadata', () async {
      final mockLiquidProvider = MockLiquidProvider();
      final mockSharedPreferences = MockSharedPreferences();

      when(() => mockLiquidProvider.policyAsset).thenReturn(kLbtcId);
      when(() => mockLiquidProvider.usdtId).thenReturn(kUsdtId);
      when(() => mockLiquidProvider.getBalance(requiresRefresh: false))
          .thenAnswer((_) async => {
                kUnknownAssetId: 50000,
              });
      when(() => mockLiquidProvider.allRawAssets).thenReturn({});
      when(() => mockSharedPreferences.setStringList(any(), any()))
          .thenAnswer((_) async => true);

      when(() => mockMarketplaceService.fetchAssets()).thenAnswer(
        (_) async => Response(
          http.Response(jsonEncode(assetsJson), 200),
          AssetsResponse.fromJson(assetsJson),
        ),
      );

      final testContainer = ProviderContainer(overrides: [
        marketplaceServiceProvider.overrideWithValue(mockMarketplaceService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        liquidProvider.overrideWithValue(mockLiquidProvider),
        envProvider
            .overrideWith((ref) => FakeEnvNotifier(mockSharedPreferences)),
      ]);

      addTearDown(testContainer.dispose);

      await testContainer.read(availableAssetsProvider.future);
      final result =
          await testContainer.read(discoveredAssetsProvider.future);

      expect(result.length, 1);
      expect(result.first.name, kUnknownAssetId.substring(0, 8));
      expect(result.first.ticker, '???');
      expect(result.first.precision, 8);
    });
  });
}

class MockUserPreferencesNotifier extends Mock
    implements UserPreferencesNotifier {}
