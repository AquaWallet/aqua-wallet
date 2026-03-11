import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/features/shared/providers/shared_prefs_provider.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.dart';
import '../../mocks/prefs_provider_mocks.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  setUpAll(() {
    // Register fallback value for Asset
    registerFallbackValue(Asset.btc());
  });

  group('FormatService - Fiat Currency Formatting', () {
    late FormatService formatter;
    late MockSharedPreferences mockSharedPreferences;
    late MockUserPreferencesNotifier mockPrefsProvider;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      mockPrefsProvider = MockUserPreferencesNotifier();

      // Setup default mocks
      mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.btc);

      final container = createContainer(
        overrides: [
          sharedPreferencesProvider
              .overrideWith((ref) => mockSharedPreferences),
          prefsProvider.overrideWith((ref) => mockPrefsProvider),
        ],
      );
      formatter = container.read(formatProvider);
    });

    test('formats USD correctly', () {
      final amount = Decimal.parse('1234.56');
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.usd.format,
      );

      // Spec: symbol: '\$', isSymbolLeading: true, thousandsSeparator: ',', decimalSeparator: '.'
      expect(result, '\$1,234.56');
    });

    test('formats EUR correctly', () {
      final amount = Decimal.parse('1234.56');
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.eur.format,
      );

      // Spec: symbol: '€', isSymbolLeading: true, thousandsSeparator: '.', decimalSeparator: ','
      expect(result, '€1.234,56');
    });

    test('formats RUB correctly', () {
      final amount = Decimal.parse('1234.56');
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.rub.format,
      );

      // Spec: symbol: '₽', isSymbolLeading: false, thousandsSeparator: '\u2009\u2009', decimalSeparator: ','
      expect(result, '1\u2009\u2009234,56 ₽');
    });

    test('formats BRL correctly', () {
      final amount = Decimal.parse('1234.56');
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.brl.format,
      );

      // Spec: symbol: 'R\$ ', isSymbolLeading: true, thousandsSeparator: '.', decimalSeparator: ','
      expect(result, 'R\$ 1.234,56');
    });

    test('handles negative amounts correctly', () {
      final amount = Decimal.parse('-1234.56');
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.usd.format,
      );

      expect(result, '-\$1,234.56');
    });

    test('formats without symbol correctly', () {
      final amount = Decimal.parse('1234.56');
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.usd.format,
        withSymbol: false,
      );

      expect(result, '1,234.56');
    });

    test('formats zero correctly', () {
      final amount = Decimal.zero;
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.usd.format,
      );
      expect(result, '\$0.00');
    });

    test('formats VND correctly', () {
      final amount = Decimal.parse('1234.56');
      final result = formatter.formatFiatAmount(
        amount: amount,
        specOverride: FiatCurrency.vnd.format,
      );

      // Spec: symbol: '₫', isSymbolLeading: true, thousandsSeparator: '.', decimalSeparator: ',', decimalPlaces: 2
      expect(result, '₫1.234,56');
    });
  });

  group('FormatService - Bitcoin Formatting', () {
    late FormatService formatter;
    late MockSharedPreferences mockSharedPreferences;
    late MockUserPreferencesNotifier mockPrefsProvider;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      mockPrefsProvider = MockUserPreferencesNotifier();

      // Setup default mocks
      mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.btc);

      final container = createContainer(
        overrides: [
          sharedPreferencesProvider
              .overrideWith((ref) => mockSharedPreferences),
          prefsProvider.overrideWith((ref) => mockPrefsProvider),
        ],
      );
      formatter = container.read(formatProvider);
    });

    test('formats BTC correctly for USD locale', () {
      const sats = 123456789;

      final result = formatter.formatAssetAmount(
        amount: sats,
        asset: Asset.btc(),
        displayUnitOverride: SupportedDisplayUnits.btc,
        specOverride: FiatCurrency.usd.format,
      );
      // Expects '.' for decimal and thin spaces for fractional grouping
      expect(result, '1.23\u2009456\u2009789');
    });

    test('formats BTC correctly for EUR locale', () {
      const sats = 123456789;

      final result = formatter.formatAssetAmount(
        amount: sats,
        asset: Asset.btc(),
        displayUnitOverride: SupportedDisplayUnits.btc,
        specOverride: FiatCurrency.eur.format,
      );
      // Expects ',' for decimal and thin spaces for fractional grouping
      expect(result, '1,23\u2009456\u2009789');
    });

    test('formats Sats correctly for USD locale', () {
      const sats = 1234567;

      final result = formatter.formatAssetAmount(
        amount: sats,
        asset: Asset.btc(),
        displayUnitOverride: SupportedDisplayUnits.sats,
        specOverride: FiatCurrency.usd.format,
      );
      // Expects ',' as thousands separator
      expect(result, '1,234,567');
    });

    test('formats Sats correctly for EUR locale', () {
      const sats = 1234567;

      final result = formatter.formatAssetAmount(
        amount: sats,
        asset: Asset.btc(),
        displayUnitOverride: SupportedDisplayUnits.sats,
        specOverride: FiatCurrency.eur.format,
      );
      // Expects '.' as thousands separator
      expect(result, '1.234.567');
    });

    test('formats Sats correctly for RUB locale', () {
      const sats = 1234567;

      final result = formatter.formatAssetAmount(
        amount: sats,
        asset: Asset.btc(),
        displayUnitOverride: SupportedDisplayUnits.sats,
        specOverride: FiatCurrency.rub.format,
      );
      // Expects thin space as thousands separator
      expect(result, '1\u2009\u2009234\u2009\u2009567');
    });

    test('formats Bits correctly for USD locale', () {
      const sats = 1234567;
      final result = formatter.formatAssetAmount(
        amount: sats,
        asset: Asset.btc(),
        displayUnitOverride: SupportedDisplayUnits.bits,
        specOverride: FiatCurrency.usd.format,
      );
      // Expects ',' for thousands and '.' for decimal
      expect(result, '12,345.67');
    });
  });
}
