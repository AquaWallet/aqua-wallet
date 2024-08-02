import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:dio/dio.dart' as dio;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

class MockDio extends Mock implements dio.Dio {}

class MockDioResponse<T> extends Mock implements dio.Response<T> {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('electrsProvider', () {
    late dio.Dio client;
    late SharedPreferences prefs;

    setUp(() {
      client = MockDio();
      prefs = MockSharedPreferences();
    });

    test('fetchFeeRates success', () async {
      final ratesJson = <String, dynamic>{
        '1': 48.427,
        '3': 41.674,
        '6': 31.124000000000002,
        '1008': 5.12
      };

      final response = MockDioResponse<Map<String, dynamic>>();
      when(() => response.data).thenReturn(ratesJson);

      when(() => client.get<dynamic>(any())).thenAnswer((_) async => response);

      final container = createContainer(overrides: [
        dioProvider.overrideWithValue(client),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);

      final feeRates = await container
          .read(electrsProvider)
          .fetchFeeRates(NetworkType.bitcoin);

      expect(feeRates, {
        TransactionPriority.high: 48.427,
        TransactionPriority.medium: 41.674,
        TransactionPriority.low: 31.124000000000002,
        TransactionPriority.min: 5.12
      });

      // Verify the GET request was made to the correct URL.
      verify(
        () => client.get<dynamic>(
          'https://blockstream.info/api/fee-estimates',
        ),
      ).called(1);
    });
  });
}
