import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements dio.Dio {}

class MockBTCDirectApiService extends Mock implements BTCDirectApiService {}

class MockRef extends Mock implements Ref {}

void main() {
  group('PublicApiPriceFetcher', () {
    late MockDio mockDio;
    late MockRef mockRef;
    late PublicApiPriceFetcher priceFetcher;
    late NumberFormat mockFormatter;

    setUp(() {
      mockDio = MockDio();
      mockRef = MockRef();
      priceFetcher = PublicApiPriceFetcher(mockDio);
      mockFormatter = NumberFormat.currency(decimalDigits: 0, name: '');

      when(() => mockRef.read(currencyFormatProvider(0)))
          .thenReturn(mockFormatter);
    });

    test('fetchPrice - Beaver Bitcoin', () async {
      final integration = OnRampIntegration.beaverBitcoin();
      final mockData = {
        "timestamp": 1718620507,
        "date": "2024-06-17 10:35:07",
        "priceInCents": 9054482
      };

      when(() => mockDio.get(integration.priceApi!))
          .thenAnswer((_) async => dio.Response(
                data: mockData,
                statusCode: 200,
                requestOptions: dio.RequestOptions(path: ''),
              ));

      final price = await priceFetcher.fetchPrice(integration, mockRef);

      expect(price, equals('\$90,545'));
      verify(() => mockDio.get(integration.priceApi!)).called(1);
    });

    test('fetchPrice - Pocket Bitcoin', () async {
      final integration = OnRampIntegration.pocketBitcoin();
      final mockData = {
        "error": [],
        "result": {
          "XXBTZEUR": {
            "a": ["57509.00000", "4", "4.000"],
          }
        }
      };

      when(() => mockDio.get(integration.priceApi!))
          .thenAnswer((_) async => dio.Response(
                data: mockData,
                statusCode: 200,
                requestOptions: dio.RequestOptions(path: ''),
              ));

      final price = await priceFetcher.fetchPrice(integration, mockRef);

      expect(price, equals('€57,509'));
      verify(() => mockDio.get(integration.priceApi!)).called(1);
    });

    test('fetchPrice - handles null priceApi', () async {
      final integration =
          OnRampIntegration.meld(); // Assuming this has no priceApi

      final price = await priceFetcher.fetchPrice(integration, mockRef);

      expect(price, isNull);
      verifyNever(() => mockDio.get(any()));
    });
  });

  group('BTCDirectPriceFetcher', () {
    late MockBTCDirectApiService mockService;
    late MockRef mockRef;
    late BTCDirectPriceFetcher priceFetcher;
    late NumberFormat mockFormatter;

    setUp(() {
      mockService = MockBTCDirectApiService();
      mockRef = MockRef();
      priceFetcher = BTCDirectPriceFetcher(mockService);
      mockFormatter = NumberFormat.currency(decimalDigits: 0, name: '');

      when(() => mockRef.read(currencyFormatProvider(0)))
          .thenReturn(mockFormatter);
    });

    test('fetchPrice - returns formatted price', () async {
      final integration = OnRampIntegration.btcDirect();
      const mockPriceResponse = BTCPriceResponse(
        buyPrice: '50000.00',
        sellPrice: '49000.00',
      );

      when(() => mockService.getBTCPrice())
          .thenAnswer((_) async => mockPriceResponse);

      final price = await priceFetcher.fetchPrice(integration, mockRef);

      expect(price, equals('${integration.priceSymbol}50,000'));
      verify(() => mockService.getBTCPrice()).called(1);
    });

    test('fetchPrice - propagates errors', () async {
      final integration = OnRampIntegration.btcDirect();

      when(() => mockService.getBTCPrice()).thenThrow(Exception('API Error'));

      expect(
        () => priceFetcher.fetchPrice(integration, mockRef),
        throwsException,
      );
    });
  });
}
