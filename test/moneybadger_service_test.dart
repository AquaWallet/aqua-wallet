import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketplaceServiceAvailability.fromResponse', () {
    test('parses moneybadger response', () {
      final response = ServiceTilesResponse.fromJson({
        'name': 'moneybadger',
        'is_active': true,
      });
      final availability =
          MarketplaceServiceAvailability.fromResponse(response);

      expect(availability, isNotNull);
      expect(availability!.type, MarketplaceServiceType.moneybadger);
      expect(availability.isEnabled, isTrue);
    });

    test('parses inactive moneybadger response', () {
      final response = ServiceTilesResponse.fromJson({
        'name': 'moneybadger',
        'is_active': false,
      });
      final availability =
          MarketplaceServiceAvailability.fromResponse(response);

      expect(availability, isNotNull);
      expect(availability!.type, MarketplaceServiceType.moneybadger);
      expect(availability.isEnabled, isFalse);
    });

    test('returns null for unknown service name', () {
      final response = ServiceTilesResponse.fromJson({
        'name': 'unknown_service',
        'is_active': true,
      });
      final availability =
          MarketplaceServiceAvailability.fromResponse(response);

      expect(availability, isNull);
    });
  });
}
