import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:aqua/features/settings/exchange_rate/providers/exchange_rate_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks/prefs_provider_mocks.dart';
import 'mocks/storage_mocks.dart';

class MockReferenceExchangeRateProvider extends Mock
    implements ReferenceExchangeRateProvider {}

void main() {
  setUpAll(() {
    // Register fallback value for Asset
    registerFallbackValue(Asset.btc());
    registerFallbackValue(const ExchangeRate(
      FiatCurrency.usd,
      ExchangeRateSource.coingecko,
    ));
  });

  final mockSharedPreferences = MockSharedPreferences();
  final mockPrefsProvider = MockUserPreferencesNotifier();
  final mockExchangeRatesProvider = MockReferenceExchangeRateProvider();

  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWith((ref) => mockSharedPreferences),
    prefsProvider.overrideWith((ref) => mockPrefsProvider),
    exchangeRatesProvider.overrideWith((ref) => mockExchangeRatesProvider),
  ]);

  setUp(() {
    mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.btc);
    when(() => mockExchangeRatesProvider.currentCurrency).thenReturn(
      const ExchangeRate(FiatCurrency.usd, ExchangeRateSource.coingecko),
    );
  });

  group('formatAssetAmount', () {
    group('BTC unit', () {
      test('1 BTC', () async {
        expect(
            container.read(formatProvider).formatAssetAmount(
                amount: 100000000,
                asset: Asset.btc(),
                removeTrailingZeros: false),
            "1.00\u2009000\u2009000");
      });

      test('10.1 BTC', () async {
        expect(
            container.read(formatProvider).formatAssetAmount(
                amount: 1010000000,
                asset: Asset.btc(),
                removeTrailingZeros: false),
            "10.10\u2009000\u2009000");
      });

      test('10,000.4536 BTC', () async {
        expect(
            container.read(formatProvider).formatAssetAmount(
                amount: 1000045360000,
                asset: Asset.btc(),
                removeTrailingZeros: false),
            "10,000.45\u2009360\u2009000");
      });

      test('0.046292 BTC', () async {
        expect(
            container.read(formatProvider).formatAssetAmount(
                amount: 4629200,
                asset: Asset.btc(),
                removeTrailingZeros: false),
            "0.04\u2009629\u2009200");
      });

      test('0.00000001 BTC (1 sat)', () async {
        expect(
          container.read(formatProvider).formatAssetAmount(
              amount: 1, asset: Asset.btc(), removeTrailingZeros: false),
          "0.00\u2009000\u2009001",
        );
      });

      test('0 BTC', () async {
        expect(
            container.read(formatProvider).formatAssetAmount(
                amount: 0, asset: Asset.btc(), removeTrailingZeros: false),
            "0.00\u2009000\u2009000");
      });
    });

    group('Sats unit', () {
      setUp(() {
        mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.sats);
      });

      test('100,000,000 sats (1 BTC)', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 100000000, asset: Asset.btc()),
          "100,000,000",
        );
      });

      test('1,000,000 sats (0.01 BTC)', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 1000000, asset: Asset.btc()),
          "1,000,000",
        );
      });

      test('1 sat', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 1, asset: Asset.btc()),
          "1",
        );
      });

      test('0 sats', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 0, asset: Asset.btc()),
          "0",
        );
      });

      test('123,456 sats', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 123456, asset: Asset.btc()),
          "123,456",
        );
      });
    });

    group('Bits unit', () {
      setUp(() {
        mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.bits);
      });

      test('1,000,000 bits (1 BTC)', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 100000000, asset: Asset.btc()),
          "1,000,000",
        );
      });

      test('10,000 bits (0.01 BTC)', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 1000000, asset: Asset.btc()),
          "10,000",
        );
      });

      test('1 bit (100 sats)', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 100, asset: Asset.btc()),
          "1",
        );
      });

      test('0.5 bits (50 sats)', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 50, asset: Asset.btc()),
          "0.5",
        );
      });

      test('0.01 bits (1 sat)', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 1, asset: Asset.btc()),
          "0.01",
        );
      });

      test('1234.56 bits', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 123456, asset: Asset.btc()),
          "1,234.56",
        );
      });

      test('0 bits', () async {
        expect(
          container
              .read(formatProvider)
              .formatAssetAmount(amount: 0, asset: Asset.btc()),
          "0",
        );
      });
    });
  });

  group('parseAssetAmountDirect', () {
    test('simple positive number', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100",
              precision: 2,
            ),
        10000,
      );
    });

    test('negative number', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "-100",
              precision: 2,
            ),
        -10000,
      );
    });

    test('number with commas', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "2,000",
              precision: 2,
            ),
        200000,
      );
    });

    test('negative number with commas', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "-2,000",
              precision: 2,
            ),
        -200000,
      );
    });

    test('decimal number', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100.50",
              precision: 2,
            ),
        10050,
      );
    });

    test('number with spaces', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: " 100.50 ",
              precision: 2,
            ),
        10050,
      );
    });

    test('throws on invalid precision (negative)', () {
      expect(
        () => container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100",
              precision: -1,
            ),
        throwsA(isA<ParseAmountWrongPrecisionException>()),
      );
    });

    test('throws on invalid precision (too large)', () {
      expect(
        () => container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100",
              precision: 9,
            ),
        throwsA(isA<ParseAmountWrongPrecisionException>()),
      );
    });

    test('throws on invalid number format', () {
      expect(
        () => container.read(formatterProvider).parseAssetAmountDirect(
              amount: "abc",
              precision: 2,
            ),
        throwsA(isA<ParseAmountUnableParseFromStringException>()),
      );
    });
  });

  group('convertAssetAmountToDisplayUnit', () {
    group('BTC unit', () {
      setUp(() {
        mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.btc);
      });

      test('1 BTC (100,000,000 sats)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 100000000,
                asset: Asset.btc(),
              ),
          '1',
        );
      });

      test('0.5 BTC (50,000,000 sats)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 50000000,
                asset: Asset.btc(),
              ),
          '0.5',
        );
      });

      test('0.00001234 BTC (1234 sats)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 1234,
                asset: Asset.btc(),
              ),
          '0.00001234',
        );
      });

      test('0.00000001 BTC (1 sat)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 1,
                asset: Asset.btc(),
              ),
          '0.00000001',
        );
      });

      test('0 BTC', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 0,
                asset: Asset.btc(),
              ),
          '0',
        );
      });

      test('10.12345678 BTC', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 1012345678,
                asset: Asset.btc(),
              ),
          '10.12345678',
        );
      });
    });

    group('Sats unit', () {
      setUp(() {
        mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.sats);
      });

      test('100,000,000 sats (1 BTC)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 100000000,
                asset: Asset.btc(),
              ),
          '100000000',
        );
      });

      test('1234 sats', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 1234,
                asset: Asset.btc(),
              ),
          '1234',
        );
      });

      test('1 sat', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 1,
                asset: Asset.btc(),
              ),
          '1',
        );
      });

      test('0 sats', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 0,
                asset: Asset.btc(),
              ),
          '0',
        );
      });

      test('12345678 sats', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 12345678,
                asset: Asset.btc(),
              ),
          '12345678',
        );
      });
    });

    group('Bits unit', () {
      setUp(() {
        mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.bits);
      });

      test('1,000,000 bits (1 BTC / 100,000,000 sats)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 100000000,
                asset: Asset.btc(),
              ),
          '1000000',
        );
      });

      test('12.34 bits (1234 sats)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 1234,
                asset: Asset.btc(),
              ),
          '12.34',
        );
      });

      test('1 bit (100 sats)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 100,
                asset: Asset.btc(),
              ),
          '1',
        );
      });

      test('0.01 bits (1 sat)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 1,
                asset: Asset.btc(),
              ),
          '0.01',
        );
      });

      test('0.5 bits (50 sats)', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 50,
                asset: Asset.btc(),
              ),
          '0.5',
        );
      });

      test('0 bits', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 0,
                asset: Asset.btc(),
              ),
          '0',
        );
      });
    });

    group('LBTC asset', () {
      setUp(() {
        mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.sats);
      });

      test('uses display unit for LBTC', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 12345,
                asset: Asset.lbtc(),
              ),
          '12345',
        );
      });
    });

    group('Lightning asset', () {
      setUp(() {
        mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.sats);
      });

      test('uses display unit for Lightning', () {
        expect(
          container.read(formatterProvider).convertAssetAmountToDisplayUnit(
                amount: 12345,
                asset: Asset.lightning(),
              ),
          '12345',
        );
      });
    });
  });

  group('cleanAmountString', () {
    // USD: thousandsSeparator=',', decimalSeparator='.'
    const usdSpec = CurrencyFormatSpec(
      symbol: '\$',
      thousandsSeparator: ',',
      decimalSeparator: '.',
      currencyCountryCode: 'US',
    );

    // EUR: thousandsSeparator='.', decimalSeparator=','
    const eurSpec = CurrencyFormatSpec(
      symbol: '€',
      thousandsSeparator: '.',
      decimalSeparator: ',',
      currencyCountryCode: 'EU',
    );

    // VND: thousandsSeparator='.', decimalSeparator=','
    const vndSpec = CurrencyFormatSpec(
      symbol: '₫',
      thousandsSeparator: '.',
      decimalSeparator: ',',
      currencyCountryCode: 'VN',
    );

    group('USD format (dot decimal, comma thousands)', () {
      test('simple decimal amount', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0.0008', usdSpec),
          '0.0008',
        );
      });

      test('amount with thousands separator', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('1,000.50', usdSpec),
          '1000.50',
        );
      });

      test('integer amount', () {
        expect(
          container.read(formatterProvider).cleanAmountString('80000', usdSpec),
          '80000',
        );
      });

      test('amount with spaces', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString(' 1 000 ', usdSpec),
          '1000',
        );
      });

      test('empty string returns 0', () {
        expect(
          container.read(formatterProvider).cleanAmountString('', usdSpec),
          '0',
        );
      });
    });

    group('EUR format (comma decimal, dot thousands)', () {
      test('locale-formatted decimal amount', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0,0008', eurSpec),
          '0.0008',
        );
      });

      test('locale-formatted with thousands separator', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('1.000,50', eurSpec),
          '1000.50',
        );
      });

      test('standard-format decimal (from Decimal.toString()) is preserved',
          () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0.0008', eurSpec),
          '0.0008',
        );
      });

      test('standard-format BTC amount is not corrupted', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0.00080000', eurSpec),
          '0.00080000',
        );
      });

      test('integer amount', () {
        expect(
          container.read(formatterProvider).cleanAmountString('80000', eurSpec),
          '80000',
        );
      });

      test('large locale-formatted amount', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('1.234.567,89', eurSpec),
          '1234567.89',
        );
      });

      test('empty string returns 0', () {
        expect(
          container.read(formatterProvider).cleanAmountString('', eurSpec),
          '0',
        );
      });

      test('amount with bitcoin fractional separator', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0.00\u2009080\u2009000', eurSpec),
          '0.00080000',
        );
      });
    });

    group('VND format (comma decimal, dot thousands)', () {
      test('locale-formatted decimal amount', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0,0008', vndSpec),
          '0.0008',
        );
      });

      test('standard-format decimal is preserved', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0.0008', vndSpec),
          '0.0008',
        );
      });

      test('locale-formatted with thousands separator', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('1.000,50', vndSpec),
          '1000.50',
        );
      });

      test('integer amount', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('1000000', vndSpec),
          '1000000',
        );
      });
    });

    group('CHF format (apostrophe thousands, dot decimal)', () {
      const chfSpec = CurrencyFormatSpec(
        symbol: 'CHF ',
        thousandsSeparator: '\'',
        decimalSeparator: '.',
        currencyCountryCode: 'CH',
      );

      test('simple decimal amount', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString('0.0008', chfSpec),
          '0.0008',
        );
      });

      test('amount with apostrophe thousands separator', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString("1'000.50", chfSpec),
          '1000.50',
        );
      });

      test('large amount with multiple apostrophes', () {
        expect(
          container
              .read(formatterProvider)
              .cleanAmountString("1'234'567.89", chfSpec),
          '1234567.89',
        );
      });

      test('integer amount', () {
        expect(
          container.read(formatterProvider).cleanAmountString('80000', chfSpec),
          '80000',
        );
      });

      test('empty string returns 0', () {
        expect(
          container.read(formatterProvider).cleanAmountString('', chfSpec),
          '0',
        );
      });
    });

    group('Cross-currency: same input, different specs', () {
      test('"0.0008" is preserved for both USD and EUR', () {
        final formatter = container.read(formatterProvider);
        expect(formatter.cleanAmountString('0.0008', usdSpec), '0.0008');
        expect(formatter.cleanAmountString('0.0008', eurSpec), '0.0008');
        expect(formatter.cleanAmountString('0.0008', vndSpec), '0.0008');
      });

      test('"1,000" strips thousands for USD, normalizes decimal for EUR', () {
        final formatter = container.read(formatterProvider);
        expect(formatter.cleanAmountString('1,000', usdSpec), '1000');
        expect(formatter.cleanAmountString('1,000', eurSpec), '1.000');
      });

      test('"1.000" strips thousands for EUR, is decimal for USD', () {
        final formatter = container.read(formatterProvider);
        expect(formatter.cleanAmountString('1.000', usdSpec), '1.000');
        expect(formatter.cleanAmountString('1.000', eurSpec), '1.000');
      });
    });
  });
}
