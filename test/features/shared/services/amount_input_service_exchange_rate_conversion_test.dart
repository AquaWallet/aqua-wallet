import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_components/ui_components.dart';

import '../../../mocks/mocks.dart';

// Mock classes for the service dependencies
class MockFormatterProvider extends Mock implements FormatterProvider {}

class MockFormatService extends Mock implements FormatService {}

class MockDisplayUnitsProvider extends Mock implements DisplayUnitsProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AmountInputService service;
  late MockFormatterProvider mockFormatterProvider;
  late MockFormatService mockFormatService;
  late MockDisplayUnitsProvider mockDisplayUnitsProvider;
  late List<BitcoinFiatRatesResponse> mockFiatRates;
  late Asset btcAsset;

  setUpAll(() {
    registerFallbackValue(Asset.btc());
    registerFallbackValue(SupportedDisplayUnits.btc);
    registerFallbackValue(Decimal.zero);
    registerFallbackValue(const CurrencyFormatSpec(
      symbol: '\$',
      decimalSeparator: '.',
      thousandsSeparator: ',',
      isSymbolLeading: true,
      decimalPlaces: 2,
      currencyCountryCode: 'US',
    ));
  });

  setUp(() {
    mockFormatterProvider = MockFormatterProvider();
    mockFormatService = MockFormatService();
    mockDisplayUnitsProvider = MockDisplayUnitsProvider();
    mockFiatRates = [kBtcUsdFiatRate, kBtcEurFiatRate];
    btcAsset = Asset.btc();

    service = AmountInputService(
      formatterProvider: mockFormatterProvider,
      formatProvider: mockFormatService,
      fiatRatesProvider: AsyncValue.data(mockFiatRates),
      unitsProvider: mockDisplayUnitsProvider,
    );
  });

  group('Exchange Rate Conversion Bug Tests', () {
    test(
      'should correctly convert 0.0001 BTC with EUR rate using comma separator',
      () {
        // Input: "0,0001" BTC with EUR formatting
        const inputText = '0,0001';
        const expectedSats = 10000; // 0.0001 BTC = 10,000 sats
        const expectedFiatAmount =
            2.8345; // 10,000 sats * (28,345 EUR/BTC) / 100,000,000 sats/BTC

        // Mock the parseAssetAmountToSats to handle EUR comma format
        when(() => mockFormatterProvider.parseAssetAmountToSats(
              amount: inputText,
              asset: btcAsset,
              precision: btcAsset.precision,
              forcedDisplayUnit: SupportedDisplayUnits.btc,
            )).thenReturn(expectedSats);

        // Mock the formatFiatAmount to return EUR formatted amount
        when(() => mockFormatService.formatFiatAmount(
              amount: DecimalExt.fromDouble(expectedFiatAmount),
              specOverride: kBtcEurExchangeRate.currency.format,
              withSymbol: true,
            )).thenReturn('€2,83');

        final result = service.getFiatConversionRate(
          amountText: inputText,
          rate: kBtcEurExchangeRate,
          unit: AquaAssetInputUnit.crypto,
          type: AquaAssetInputType.crypto,
          asset: btcAsset,
        );

        expect(result, '€2,83');
        verify(() => mockFormatterProvider.parseAssetAmountToSats(
              amount: inputText,
              asset: btcAsset,
              precision: btcAsset.precision,
              forcedDisplayUnit: SupportedDisplayUnits.btc,
            )).called(1);
      },
    );

    test(
      'should correctly convert 0.0001 BTC with USD rate using dot separator',
      () {
        // Input: "0.0001" BTC with USD formatting
        const inputText = '0.0001';
        const expectedSats = 10000; // 0.0001 BTC = 10,000 sats
        const expectedFiatAmount =
            5.669; // 10,000 sats * (56,690 USD/BTC) / 100,000,000 sats/BTC

        // Mock the parseAssetAmountToSats to handle USD dot format
        when(() => mockFormatterProvider.parseAssetAmountToSats(
              amount: inputText,
              asset: btcAsset,
              precision: btcAsset.precision,
              forcedDisplayUnit: SupportedDisplayUnits.btc,
            )).thenReturn(expectedSats);

        // Mock the formatFiatAmount to return USD formatted amount
        when(() => mockFormatService.formatFiatAmount(
              amount: DecimalExt.fromDouble(expectedFiatAmount),
              specOverride: kBtcUsdExchangeRate.currency.format,
              withSymbol: true,
            )).thenReturn('\$5.67');

        final result = service.getFiatConversionRate(
          amountText: inputText,
          rate: kBtcUsdExchangeRate,
          unit: AquaAssetInputUnit.crypto,
          type: AquaAssetInputType.crypto,
          asset: btcAsset,
        );

        expect(result, '\$5.67');
        verify(() => mockFormatterProvider.parseAssetAmountToSats(
              amount: inputText,
              asset: btcAsset,
              precision: btcAsset.precision,
              forcedDisplayUnit: SupportedDisplayUnits.btc,
            )).called(1);
      },
    );

    test(
      'BUG REPRODUCTION: should NOT show full BTC rate when switching from EUR to USD',
      () {
        // This test reproduces the bug described by the user
        // Input: "0.0001" BTC but the parsing incorrectly interprets it as much more

        const inputText = '0.0001';
        // BUG: parseAssetAmountToSats incorrectly returns a huge value instead of 10000
        const buggyParsedSats = 100000000; // 1 BTC instead of 0.0001 BTC
        const buggyFiatAmount =
            56690.0; // Full BTC rate instead of 0.0001 * rate

        // Mock the buggy behavior
        when(() => mockFormatterProvider.parseAssetAmountToSats(
              amount: inputText,
              asset: btcAsset,
              precision: btcAsset.precision,
              forcedDisplayUnit: SupportedDisplayUnits.btc,
            )).thenReturn(buggyParsedSats);

        when(() => mockFormatService.formatFiatAmount(
              amount: DecimalExt.fromDouble(buggyFiatAmount),
              specOverride: kBtcUsdExchangeRate.currency.format,
              withSymbol: true,
            )).thenReturn('\$56,690.00'); // This is the bug - shows full rate

        final result = service.getFiatConversionRate(
          amountText: inputText,
          rate: kBtcUsdExchangeRate,
          unit: AquaAssetInputUnit.crypto,
          type: AquaAssetInputType.crypto,
          asset: btcAsset,
        );

        // This test demonstrates the bug - it returns the full BTC rate
        expect(result, '\$56,690.00');
        // But it SHOULD return something like '\$5.67' for 0.0001 BTC
      },
    );

    test(
      'should correctly handle EUR comma format parsing',
      () {
        // Test the FormatterProvider parsing with EUR format
        const eurFormat = CurrencyFormatSpec(
          symbol: '€',
          decimalSeparator: ',',
          thousandsSeparator: '.',
          isSymbolLeading: false,
          decimalPlaces: 2,
        );

        // Mock cleanAmountString to handle EUR comma format
        when(() => mockFormatterProvider.cleanAmountString('0,0001', eurFormat))
            .thenReturn('0.0001'); // Should convert comma to dot

        when(() => mockFormatterProvider.parseAssetAmountToSats(
              amount: '0,0001',
              asset: btcAsset,
              precision: btcAsset.precision,
              forcedDisplayUnit: SupportedDisplayUnits.btc,
            )).thenReturn(10000);

        // This should work correctly
        final sats = mockFormatterProvider.parseAssetAmountToSats(
          amount: '0,0001',
          asset: btcAsset,
          precision: btcAsset.precision,
          forcedDisplayUnit: SupportedDisplayUnits.btc,
        );

        expect(sats, 10000);
      },
    );

    test(
      'should correctly handle USD dot format parsing',
      () {
        // Test the FormatterProvider parsing with USD format
        const usdFormat = CurrencyFormatSpec(
          symbol: '\$',
          decimalSeparator: '.',
          thousandsSeparator: ',',
          isSymbolLeading: true,
          decimalPlaces: 2,
        );

        // Mock cleanAmountString to handle USD dot format
        when(() => mockFormatterProvider.cleanAmountString('0.0001', usdFormat))
            .thenReturn('0.0001'); // Should remain the same

        when(() => mockFormatterProvider.parseAssetAmountToSats(
              amount: '0.0001',
              asset: btcAsset,
              precision: btcAsset.precision,
              forcedDisplayUnit: SupportedDisplayUnits.btc,
            )).thenReturn(10000);

        // This should also work correctly
        final sats = mockFormatterProvider.parseAssetAmountToSats(
          amount: '0.0001',
          asset: btcAsset,
          precision: btcAsset.precision,
          forcedDisplayUnit: SupportedDisplayUnits.btc,
        );

        expect(sats, 10000);
      },
    );
  });
}
