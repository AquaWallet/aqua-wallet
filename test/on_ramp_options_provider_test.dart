import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/settings/region/providers/region_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements dio.Dio {}

class MockDioResponse<T> extends Mock implements dio.Response<T> {}

class MockRef extends Mock implements Ref {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockRegionsProvider extends Mock implements RegionsProvider {}

void main() {
  group('fetchPrice', () {
    late MockDio mockDio;
    late MockRef mockRef;
    late MockSharedPreferences mockSharedPreferences;
    late MockDioResponse mockResponse;
    late ProviderContainer container;

    setUp(() {
      mockRef = MockRef();
      mockDio = MockDio();
      mockResponse = MockDioResponse();
      mockSharedPreferences = MockSharedPreferences();
      container = ProviderContainer(overrides: [
        dioProvider.overrideWithValue(mockDio),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
      ]);
    });

    test('correctly parse and format price from response data - beaver bitcoin',
        () async {
      final mockData = {
        "timestamp": 1718620507,
        "date": "2024-06-17 10:35:07",
        "priceInCents": 9054482
      };

      mockResponse = MockDioResponse();
      when(() => mockResponse.data).thenReturn(mockData);
      final format = NumberFormat.currency(
        decimalDigits: 0,
        name: '',
      );
      when(() => mockRef.read(currencyFormatProvider(0))).thenReturn(format);

      final notifier = container.read(onRampOptionsProvider.notifier);
      final result = await notifier.parseAndFormatPrice(
          OnRampIntegration.beaverBitcoin(), mockResponse);

      expect(result, equals("\$90,545"));
    });

    test('should correctly parse and format Pocket Bitcoin price', () async {
      final mockData = {
        "error": [],
        "result": {
          "XXBTZEUR": {
            "a": ["57509.00000", "4", "4.000"],
            "b": ["57508.90000", "1", "1.000"],
            "c": ["57490.10000", "0.00015715"],
            "v": ["208.24592276", "483.80935400"],
            "p": ["57420.40079", "57535.01327"],
            "t": [7558, 14683],
            "l": ["57184.00000", "57038.20000"],
            "h": ["58120.00000", "58155.00000"],
            "o": "57550.50000"
          }
        }
      };

      mockResponse = MockDioResponse();
      when(() => mockResponse.data).thenReturn(mockData);
      final format = NumberFormat.currency(
        decimalDigits: 0,
        name: '',
      );
      when(() => mockRef.read(currencyFormatProvider(0))).thenReturn(format);

      final notifier = container.read(onRampOptionsProvider.notifier);
      final result = await notifier.parseAndFormatPrice(
          OnRampIntegration.pocketBitcoin(), mockResponse);

      expect(result, equals("€57,509"));
    });
  });
}
