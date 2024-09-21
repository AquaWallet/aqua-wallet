import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

import 'helpers.dart';

class MockDio extends Mock implements dio.Dio {}

class MockDioResponse<T> extends Mock implements dio.Response<T> {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockLiquidProvider extends Mock implements LiquidProvider {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const kLbtcId =
      '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d';
  const kUsdtId =
      'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2';

  final assetsJson = <String, dynamic>{
    "QueryResponse": {
      "Assets": [
        {
          "Name": "Liquid Bitcoin",
          "Id": kLbtcId,
          "Ticker": "L-BTC",
          "Logo":
              "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/L-BTC.svg",
          "Default": true
        },
        {
          "Name": "Tether USDt",
          "Id": kUsdtId,
          "Ticker": "USDt",
          "Logo":
              "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/USDt.svg",
          "Default": true
        },
        {
          "Name": "INF",
          "Id":
              "20f235a1096c05a5d9b1d40d09112d3d57eb3a7ac9959beebf0ae5f774a7fd68",
          "Ticker": "INF",
          "Logo": "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/INF.svg",
          "Default": false
        },
        {
          "Name": "JPY Stablecoin",
          "Id":
              "3438ecb49fc45c08e687de4749ed628c511e326460ea4336794e1cf02741329e",
          "Ticker": "JPYS",
          "Logo":
              "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/JPYS.svg",
          "Default": false
        },
        {
          "Name": "PEGx EURx",
          "Id":
              "18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec",
          "Ticker": "EURx",
          "Logo":
              "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/EURx.svg",
          "Default": false
        },
        {
          "Name": "Mexas",
          "Id":
              "26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e",
          "Ticker": "MEX",
          "Logo": "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/MEX.svg",
          "Default": false,
          "IsRemovable": true
        },
        {
          "Name": "DePix",
          "Id":
              "02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189",
          "Ticker": "DePix",
          "Logo":
              "https://aqua-asset-logos.s3.us-west-2.amazonaws.com/DePix.svg",
          "Default": false,
          "IsRemovable": true
        }
      ]
    }
  };

  group('availableAssetsProvider', () {
    late dio.Dio client;
    late SharedPreferences mockSharedPreferences;
    late LiquidProvider mockLiquidProvider;

    setUp(() {
      client = MockDio();
      mockSharedPreferences = MockSharedPreferences();
      mockLiquidProvider = MockLiquidProvider();
    });

    test('fetchAssets success', () async {
      final response = MockDioResponse<Map<String, dynamic>>();
      when(() => response.data).thenReturn(assetsJson);

      // Use the mock response to answer any GET request made with the
      // mocked Dio client.
      when(() => client.get<dynamic>(any())).thenAnswer((_) async => response);

      when(() => mockSharedPreferences.get("userAssetIds")).thenReturn([]);
      when(() => mockSharedPreferences.setStringList(any(), any()))
          .thenAnswer((_) async => true);

      when(() => mockLiquidProvider.policyAsset).thenReturn(kLbtcId);
      when(() => mockLiquidProvider.usdtId).thenReturn(kUsdtId);

      final container = createContainer(overrides: [
        dioProvider.overrideWithValue(client),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        liquidProvider.overrideWithValue(mockLiquidProvider),
      ]);

      expect(
        container.read(availableAssetsProvider),
        const AsyncValue<List<Asset>>.loading(),
      );

      await container.read(availableAssetsProvider.future);

      expect(container.read(availableAssetsProvider).value, [
        Asset(
            id: kLbtcId,
            name: 'Liquid Bitcoin',
            ticker: 'L-BTC',
            logoUrl:
                'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/L-BTC.svg',
            isDefaultAsset: true,
            domain: null,
            amount: 0,
            precision: 8,
            isLiquid: true,
            isLBTC: true,
            isUSDt: false),
        Asset(
            id: kUsdtId,
            name: 'Tether USDt',
            ticker: 'USDt',
            logoUrl:
                'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/USDt.svg',
            isDefaultAsset: true,
            domain: null,
            amount: 0,
            precision: 8,
            isLiquid: true,
            isLBTC: false,
            isUSDt: true),
        Asset(
            id:
                '20f235a1096c05a5d9b1d40d09112d3d57eb3a7ac9959beebf0ae5f774a7fd68',
            name: 'INF',
            ticker: 'INF',
            logoUrl:
                'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/INF.svg',
            isDefaultAsset: false,
            domain: null,
            amount: 0,
            precision: 8,
            isLiquid: true,
            isLBTC: false,
            isUSDt: false),
        Asset(
            id:
                '3438ecb49fc45c08e687de4749ed628c511e326460ea4336794e1cf02741329e',
            name: 'JPY Stablecoin',
            ticker: 'JPYS',
            logoUrl:
                'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/JPYS.svg',
            isDefaultAsset: false,
            domain: null,
            amount: 0,
            precision: 8,
            isLiquid: true,
            isLBTC: false,
            isUSDt: false),
        Asset(
            id:
                '18729918ab4bca843656f08d4dd877bed6641fbd596a0a963abbf199cfeb3cec',
            name: 'PEGx EURx',
            ticker: 'EURx',
            logoUrl:
                'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/EURx.svg',
            isDefaultAsset: false,
            domain: null,
            amount: 0,
            precision: 8,
            isLiquid: true,
            isLBTC: false,
            isUSDt: false),
        Asset(
            id:
                '26ac924263ba547b706251635550a8649545ee5c074fe5db8d7140557baaf32e',
            name: 'Mexas',
            ticker: 'MEX',
            logoUrl:
                'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/MEX.svg',
            isDefaultAsset: false,
            domain: null,
            amount: 0,
            precision: 8,
            isLiquid: true,
            isLBTC: false,
            isUSDt: false),
        Asset(
            id:
                '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
            name: 'DePix',
            ticker: 'DePix',
            logoUrl:
                'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/DePix.svg',
            isDefaultAsset: false,
            domain: null,
            amount: 0,
            precision: 8,
            isLiquid: true,
            isLBTC: false,
            isUSDt: false)
      ]);

      // Verify the GET request was made to the correct URL.
      verify(
        () => client.get<dynamic>(
          'https://api.aquawallet.io/alpha/assets',
        ),
      ).called(1);
    });

    test('fetchAssets throws, load from assets.json', () async {
      final exception = Exception();

      // Use the mocked Dio client to throw when any get request is made
      when(() => client.get<dynamic>(any())).thenThrow(exception);

      when(() => mockSharedPreferences.get("userAssetIds")).thenReturn([]);
      when(() => mockSharedPreferences.setStringList(any(), any()))
          .thenAnswer((_) async => true);

      when(() => mockLiquidProvider.policyAsset).thenReturn(kLbtcId);
      when(() => mockLiquidProvider.usdtId).thenReturn(kUsdtId);

      final container = createContainer(overrides: [
        dioProvider.overrideWithValue(client),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        liquidProvider.overrideWithValue(mockLiquidProvider),
      ]);

      expect(
        container.read(availableAssetsProvider),
        const AsyncValue<List<Asset>>.loading(),
      );

      await container.read(availableAssetsProvider.future);

      expect(
          container.read(availableAssetsProvider).value?.first,
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
              isUSDt: false));
      expect(
          container.read(availableAssetsProvider).value?.last,
          Asset(
              id:
                  '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189',
              name: 'DePix',
              ticker: 'DePix',
              logoUrl:
                  'https://aqua-asset-logos.s3.us-west-2.amazonaws.com/DePix.svg',
              isDefaultAsset: false,
              domain: null,
              amount: 0,
              precision: 8,
              isLiquid: true,
              isLBTC: false,
              isUSDt: false));
      expect(container.read(availableAssetsProvider).value?.length, 7);

      // Verify the GET request was made to the correct URL.
      verify(
        () => client.get<dynamic>(
          'https://api.aquawallet.io/alpha/assets',
        ),
      ).called(1);
    });
  });
}
