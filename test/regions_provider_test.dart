import 'dart:convert';

import 'package:aqua/features/marketplace/api_services/marketplace_service.dart';
import 'package:aqua/features/settings/region/region.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http; // For http.Response
import 'package:mocktail/mocktail.dart';

import 'mocks/market_place_service_mocks.dart';

void main() {
  late ProviderContainer container;
  late MockMarketplaceService mockMarketplaceService;

  setUp(() {
    mockMarketplaceService = MockMarketplaceService();

    container = ProviderContainer(overrides: [
      marketplaceServiceProvider.overrideWithValue(mockMarketplaceService),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('availableRegionsProvider', () {
    final mockRegions = [
      Region(iso: 'US', name: 'United States'),
      Region(iso: 'CA', name: 'Canada'),
    ];

    final regionsJson = {
      "QueryResponse": {
        "Regions": [
          {"Name": "Afghanistan", "ISO": "AF"},
          {"Name": "Albania", "ISO": "AL"},
          {"Name": "Algeria", "ISO": "DZ"},
          {"Name": "American Samoa", "ISO": "AS"}
        ]
      }
    };

    // This is the format how it's stored current region both in the json and the user preferences
    // Changing the format breaks the app for existing users.
    test('Region model fromJson', () {
      final region =
          Region.fromJson(regionsJson['QueryResponse']!['Regions']![0]);
      expect(region.name, 'Afghanistan');
      expect(region.iso, 'AF');
    });

    // Replaces old test to fetch regions
    test('fetch Regions success', () async {
      // Use the regionsJson list to mock the API response
      when(() => mockMarketplaceService.fetchRegions()).thenAnswer(
        (_) async => Response(
          http.Response(jsonEncode(regionsJson), 200),
          RegionResponse.fromJson(regionsJson),
        ),
      );

      final result = await container.read(availableRegionsProvider.future);

      expect(result, isA<List<Region>>());
      expect(container.read(availableRegionsProvider).value, [
        Region(name: 'Afghanistan', iso: 'AF'),
        Region(name: 'Albania', iso: 'AL'),
        Region(name: 'Algeria', iso: 'DZ'),
        Region(name: 'American Samoa', iso: 'AS')
      ]);
      expect(result.length,
          equals(regionsJson['QueryResponse']!['Regions']!.length));
      expect(result.first.name,
          equals(regionsJson['QueryResponse']!['Regions']!.first['Name']));
      verify(() => mockMarketplaceService.fetchRegions()).called(1);
    });

    test('fetches regions successfully from API', () async {
      // Stub the fetchRegions call to return a successful response with mock data
      when(() => mockMarketplaceService.fetchRegions()).thenAnswer(
        (_) async => Response(
          http.Response(jsonEncode(regionsJson), 200),
          RegionResponse.fromJson(regionsJson),
        ),
      );

      final result = await container.read(availableRegionsProvider.future);

      expect(result, isA<List<Region>>());
      expect(
          result,
          equals(RegionResponse.fromJson(regionsJson)
              .regions)); // Ensure the returned list matches
      verify(() => mockMarketplaceService.fetchRegions())
          .called(1); // Verify API call
    });

    test('falls back to static regions on API failure', () async {
      var wasCalled = false;

      // Stub the service to simulate API failure
      when(() => mockMarketplaceService.fetchRegions()).thenAnswer(
        (_) async => Response(http.Response('error', 500), null),
      );

      //Replace real getStaticRegions function with fake
      getStaticRegionsFn = () async {
        wasCalled = true;
        return mockRegions;
      };

      final result = await container.read(availableRegionsProvider.future);

      expect(container.read(availableRegionsProvider).value?.length, 2);
      expect(wasCalled, isTrue);
      expect(result, isA<List<Region>>());
    });
  });
}
