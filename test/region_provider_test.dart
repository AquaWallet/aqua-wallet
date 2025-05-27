import 'package:aqua/features/settings/region/region.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:dio/dio.dart' as dio;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'helpers.dart';

class MockDio extends Mock implements dio.Dio {}

class MockDioResponse<T> extends Mock implements dio.Response<T> {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final regionsJson = <String, dynamic>{
    "QueryResponse": {
      "Regions": [
        {"Name": "Afghanistan", "ISO": "AF"},
        {"Name": "Albania", "ISO": "AL"},
        {"Name": "Algeria", "ISO": "DZ"},
        {"Name": "American Samoa", "ISO": "AS"},
      ]
    }
  };

  group('availableRegionsProvider', () {
    late dio.Dio client;

    setUp(() {
      client = MockDio();
    });

    test('fetchRegions success', () async {
      final response = MockDioResponse<Map<String, dynamic>>();
      when(() => response.data).thenReturn(regionsJson);

      // Use the mock response to answer any GET request made with the
      // mocked Dio client.
      when(() => client.get<dynamic>(any())).thenAnswer((_) async => response);

      final container =
          createContainer(overrides: [dioProvider.overrideWithValue(client)]);

      expect(
        container.read(availableRegionsProvider),
        const AsyncValue<List<Region>>.loading(),
      );

      await container.read(availableRegionsProvider.future);

      expect(container.read(availableRegionsProvider).value, [
        Region(name: 'Afghanistan', iso: 'AF'),
        Region(name: 'Albania', iso: 'AL'),
        Region(name: 'Algeria', iso: 'DZ'),
        Region(name: 'American Samoa', iso: 'AS')
      ]);

      // Verify the GET request was made to the correct URL.
      verify(
        () => client.get<dynamic>(
          'https://api.aquawallet.io/alpha/regions',
        ),
      ).called(1);
    });

    test('fetchRegions throws, load from regions.json', () async {
      final exception = Exception();

      // Use the mocked Dio client to throw when any get request is made
      when(() => client.get<dynamic>(any())).thenThrow(exception);

      final container =
          createContainer(overrides: [dioProvider.overrideWithValue(client)]);

      expect(
        container.read(availableRegionsProvider),
        const AsyncValue<List<Region>>.loading(),
      );

      await container.read(availableRegionsProvider.future);

      expect(container.read(availableRegionsProvider).value?.first,
          Region(name: 'Afghanistan', iso: 'AF'));
      expect(container.read(availableRegionsProvider).value?.last,
          Region(name: 'Zimbabwe', iso: 'ZW'));
      expect(container.read(availableRegionsProvider).value?.length, 226);

      // Verify the GET request was made to the correct URL.
      verify(
        () => client.get<dynamic>(
          'https://api.aquawallet.io/alpha/regions',
        ),
      ).called(1);
    });
  });
}
