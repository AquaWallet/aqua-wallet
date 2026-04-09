import 'dart:convert';

import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/marketplace/models/models.dart';
import 'package:aqua/features/marketplace/providers/enabled_services_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mocks.dart';

class FakeEnabledServicesNotifier extends EnabledServicesTypesNotifier {
  final List<MarketplaceServiceAvailability> services;

  FakeEnabledServicesNotifier(this.services);

  @override
  Future<List<MarketplaceServiceAvailability>> build() async {
    final currentRegion =
        ref.watch(regionsProvider.select((p) => p.currentRegion));

    return services.where((service) {
      if (!service.isEnabled) return false;
      final regions = RegionsIntegrations.supportedRegions(service.type);
      if (regions == null) return true;
      if (currentRegion == null) return false;
      return regions.any((r) => r.iso == currentRegion.iso);
    }).toList();
  }
}

ProviderContainer _makeContainer({
  Region? region,
  required List<MarketplaceServiceAvailability> services,
}) {
  final mockPrefs = MockUserPreferencesNotifier();
  mockPrefs.mockGetRegionCall(
    region != null ? jsonEncode(region.toJson()) : null,
  );

  return ProviderContainer(overrides: [
    prefsProvider.overrideWith((_) => mockPrefs),
    enabledServicesTypesProvider
        .overrideWith(() => FakeEnabledServicesNotifier(services)),
  ]);
}

void main() {
  group('RegionsIntegrations.supportedRegions', () {
    test('chapsmart returns chapsmartRegions', () {
      final regions = RegionsIntegrations.supportedRegions(
          MarketplaceServiceType.chapsmart);
      expect(regions, isNotNull);
      expect(regions!.any((r) => r.iso == 'TZ'), isTrue);
    });

    test('moneybadger returns moneybadgerRegions', () {
      final regions = RegionsIntegrations.supportedRegions(
          MarketplaceServiceType.moneybadger);
      expect(regions, isNotNull);
      expect(regions!.length, 1);
      expect(regions.first.iso, 'ZA');
      expect(regions.first.name, 'South Africa');
    });

    test('unrestricted services return null', () {
      expect(
        RegionsIntegrations.supportedRegions(MarketplaceServiceType.swaps),
        isNull,
      );
      expect(
        RegionsIntegrations.supportedRegions(MarketplaceServiceType.buyBitcoin),
        isNull,
      );
    });
  });

  group('enabledServicesTypesProvider', () {
    final allServices = [
      const MarketplaceServiceAvailability(
        type: MarketplaceServiceType.swaps,
        isEnabled: true,
      ),
      const MarketplaceServiceAvailability(
        type: MarketplaceServiceType.chapsmart,
        isEnabled: true,
      ),
      const MarketplaceServiceAvailability(
        type: MarketplaceServiceType.moneybadger,
        isEnabled: true,
      ),
    ];

    test('chapsmart included for Tanzania', () async {
      final container = _makeContainer(
        region: Region(name: 'Tanzania', iso: 'TZ'),
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, contains(MarketplaceServiceType.swaps));
      expect(types, contains(MarketplaceServiceType.chapsmart));
    });

    test('chapsmart excluded for US', () async {
      final container = _makeContainer(
        region: Region(name: 'United States of America', iso: 'US'),
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, contains(MarketplaceServiceType.swaps));
      expect(types, isNot(contains(MarketplaceServiceType.chapsmart)));
    });

    test('chapsmart excluded when no region set', () async {
      final container = _makeContainer(
        region: null,
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, contains(MarketplaceServiceType.swaps));
      expect(types, isNot(contains(MarketplaceServiceType.chapsmart)));
    });

    test('disabled services are filtered out', () async {
      final container = _makeContainer(
        region: Region(name: 'Tanzania', iso: 'TZ'),
        services: [
          const MarketplaceServiceAvailability(
            type: MarketplaceServiceType.swaps,
            isEnabled: false,
          ),
          const MarketplaceServiceAvailability(
            type: MarketplaceServiceType.chapsmart,
            isEnabled: true,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, isNot(contains(MarketplaceServiceType.swaps)));
      expect(types, contains(MarketplaceServiceType.chapsmart));
    });

    test('moneybadger included for South Africa', () async {
      final container = _makeContainer(
        region: Region(name: 'South Africa', iso: 'ZA'),
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, contains(MarketplaceServiceType.swaps));
      expect(types, contains(MarketplaceServiceType.moneybadger));
      expect(types, isNot(contains(MarketplaceServiceType.chapsmart)));
    });

    test('moneybadger excluded for US', () async {
      final container = _makeContainer(
        region: Region(name: 'United States of America', iso: 'US'),
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, contains(MarketplaceServiceType.swaps));
      expect(types, isNot(contains(MarketplaceServiceType.moneybadger)));
    });

    test('moneybadger excluded when no region set', () async {
      final container = _makeContainer(
        region: null,
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, isNot(contains(MarketplaceServiceType.moneybadger)));
    });

    test('Tanzania shows chapsmart but not moneybadger', () async {
      final container = _makeContainer(
        region: Region(name: 'Tanzania', iso: 'TZ'),
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, contains(MarketplaceServiceType.chapsmart));
      expect(types, isNot(contains(MarketplaceServiceType.moneybadger)));
    });

    test('unrestricted services always pass through', () async {
      final container = _makeContainer(
        region: Region(name: 'Germany', iso: 'DE'),
        services: allServices,
      );
      addTearDown(container.dispose);

      final result = await container.read(enabledServicesTypesProvider.future);
      final types = result.map((s) => s.type).toList();
      expect(types, contains(MarketplaceServiceType.swaps));
      expect(types, isNot(contains(MarketplaceServiceType.chapsmart)));
      expect(types, isNot(contains(MarketplaceServiceType.moneybadger)));
    });
  });
}
