import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_components/ui_components.dart';

import '../../../mocks/mocks.dart';

const kSpecialBtcSeparator = '\u2009';

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
  late Asset usdtAsset;

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
    ));
  });

  setUp(() {
    mockFormatterProvider = MockFormatterProvider();
    mockFormatService = MockFormatService();
    mockDisplayUnitsProvider = MockDisplayUnitsProvider();
    mockFiatRates = [kBtcUsdFiatRate, kBtcEurFiatRate];
    btcAsset = Asset.btc();
    usdtAsset = Asset.usdtLiquid();

    service = AmountInputService(
      formatterProvider: mockFormatterProvider,
      formatProvider: mockFormatService,
      fiatRatesProvider: AsyncValue.data(mockFiatRates),
      unitsProvider: mockDisplayUnitsProvider,
    );
  });

  group('getFiatConversionRate', () {
    test('should return default rate when asset has no fiat rate', () {
      // Create an asset that doesn't have fiat rate (like a custom token)
      final assetWithoutFiatRate = Asset.unknown();

      final result = service.getFiatConversionRate(
        amountText: '1',
        rate: kBtcUsdExchangeRate,
        unit: AquaAssetInputUnit.crypto,
        type: AquaAssetInputType.crypto,
        asset: assetWithoutFiatRate,
      );

      expect(result, '\$0.00');
    });

    test('should calculate fiat conversion for crypto input', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(100000000); // 1 BTC in sats

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$56,690.00');

      final result = service.getFiatConversionRate(
        amountText: '1',
        rate: kBtcUsdExchangeRate,
        unit: AquaAssetInputUnit.crypto,
        type: AquaAssetInputType.crypto,
        asset: btcAsset,
      );

      expect(result, '\$56,690.00');
      verify(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: '1',
            asset: btcAsset,
            precision: btcAsset.precision,
            forcedDisplayUnit: SupportedDisplayUnits.btc,
          )).called(1);
    });

    test('should handle fiat input with crypto unit', () {
      final result = service.getFiatConversionRate(
        amountText: '100',
        rate: kBtcUsdExchangeRate,
        unit: AquaAssetInputUnit.crypto,
        type: AquaAssetInputType.fiat,
        asset: btcAsset,
      );

      // 100 / 56690 = 0.00176398 (rounded to 8 decimal places)
      expect(result, '0.00176398');
    });

    test('should return amount text for fiat input with non-crypto unit', () {
      final result = service.getFiatConversionRate(
        amountText: '100.50',
        rate: kBtcUsdExchangeRate,
        unit: AquaAssetInputUnit.sats,
        type: AquaAssetInputType.fiat,
        asset: btcAsset,
      );

      expect(result, '100.50');
    });

    test('should return default rate when fiat rate is zero', () {
      final result = service.getFiatConversionRate(
        amountText: '100',
        rate:
            const ExchangeRate(FiatCurrency.usd, ExchangeRateSource.coingecko),
        unit: AquaAssetInputUnit.crypto,
        type: AquaAssetInputType.fiat,
        asset: Asset.unknown(), // Asset without fiat rate
      );

      expect(result, '\$0.00');
    });
  });

  group('getBalanceDisplay', () {
    test('should format crypto balance display', () {
      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');

      final result = service.getBalanceDisplay(
        balanceInSats: kOneBtcInSats,
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
      );

      expect(
          result, '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      verify(() => mockFormatService.formatAssetAmount(
            asset: btcAsset,
            amount: kOneBtcInSats,
            displayUnitOverride: SupportedDisplayUnits.btc,
          )).called(1);
    });

    test('should format fiat balance display', () {
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$56,690.00');

      final result = service.getBalanceDisplay(
        balanceInSats: kOneBtcInSats,
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
      );

      expect(result, '\$56,690.00');
      verify(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: true,
            specOverride: any(named: 'specOverride'),
          )).called(1);
    });

    test('should handle zero fiat rate gracefully', () {
      final serviceWithoutRates = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: const AsyncValue.data([]),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$0.00');

      final result = serviceWithoutRates.getBalanceDisplay(
        balanceInSats: kOneBtcInSats,
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
      );

      expect(result, '\$0.00');
    });
  });

  group('extractRawValue', () {
    test('should return 0 for null or empty text', () {
      expect(
        service.extractRawValue(
          formattedText: null,
          currentType: AquaAssetInputType.crypto,
          currentUnit: AquaAssetInputUnit.crypto,
          asset: btcAsset,
          currentRate: kBtcUsdExchangeRate,
        ),
        0,
      );

      expect(
        service.extractRawValue(
          formattedText: '',
          currentType: AquaAssetInputType.crypto,
          currentUnit: AquaAssetInputUnit.crypto,
          asset: btcAsset,
          currentRate: kBtcUsdExchangeRate,
        ),
        0,
      );
    });

    test('should extract raw value from crypto formatted text', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            precision: any(named: 'precision'),
            asset: any(named: 'asset'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(100000000); // 1 BTC in sats

      when(() => mockDisplayUnitsProvider.convertSatsToUnit(
            sats: any(named: 'sats'),
            asset: any(named: 'asset'),
            displayUnitOverride: any(named: 'displayUnitOverride'),
          )).thenReturn(Decimal.fromInt(1));

      final result = service.extractRawValue(
        formattedText: '1.00000000',
        currentType: AquaAssetInputType.crypto,
        currentUnit: AquaAssetInputUnit.crypto,
        asset: btcAsset,
        currentRate: kBtcUsdExchangeRate,
      );

      expect(result, 1.0);
    });

    test('should extract raw value from fiat formatted text', () {
      when(() => mockFormatterProvider.cleanAmountString(
            any(),
            any(),
          )).thenReturn('1000.50');

      final result = service.extractRawValue(
        formattedText: '1,000.50',
        currentType: AquaAssetInputType.fiat,
        currentUnit: AquaAssetInputUnit.crypto,
        asset: btcAsset,
        currentRate: kBtcUsdExchangeRate,
      );

      expect(result, 1000.50);
      verify(() => mockFormatterProvider.cleanAmountString(
            '1,000.50',
            kBtcUsdExchangeRate.currency.format,
          )).called(1);
    });

    test('should handle invalid fiat text gracefully', () {
      when(() => mockFormatterProvider.cleanAmountString(
            any(),
            any(),
          )).thenReturn('invalid');

      final result = service.extractRawValue(
        formattedText: 'invalid',
        currentType: AquaAssetInputType.fiat,
        currentUnit: AquaAssetInputUnit.crypto,
        asset: btcAsset,
        currentRate: kBtcUsdExchangeRate,
      );

      expect(result, 0);
    });
  });

  group('processAmountInput', () {
    test('should process crypto input correctly', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(100000000); // 1 BTC in sats

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$56,690.00');

      final result = service.processAmountInput(
        text: '1',
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.formattedAmountText,
          '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(result.amountInSats, 100000000);
      expect(result.displayConversionAmount, '\$56,690.00');
    });

    test('should process fiat input correctly', () {
      when(() => mockFormatterProvider.cleanAmountString(
            any(),
            any(),
          )).thenReturn('100');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('100.00');

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '0.00${kSpecialBtcSeparator}176${kSpecialBtcSeparator}397');

      final result = service.processAmountInput(
        text: '100',
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.formattedAmountText, '100.00');
      expect(result.amountInSats, kOneHundredUsdInBtcSats);
      expect(result.displayConversionAmount,
          '0.00${kSpecialBtcSeparator}176${kSpecialBtcSeparator}397');
    });

    test('should handle numeric string input for fiat without over-cleaning',
        () {
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('50.00');

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '0.00${kSpecialBtcSeparator}088${kSpecialBtcSeparator}198');

      final result = service.processAmountInput(
        text: '50',
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.formattedAmountText, '50.00');
      expect(result.amountInSats, 88198); // 50 USD in sats at rate 56690

      // Verify cleanAmountString was NOT called since text is already numeric
      verifyNever(() => mockFormatterProvider.cleanAmountString(any(), any()));
    });

    test('should use current state rate for currency format when provided', () {
      when(() => mockFormatterProvider.cleanAmountString(
            any(),
            any(),
          )).thenReturn('100');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('100,00'); // EUR formatting

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '0.00${kSpecialBtcSeparator}352${kSpecialBtcSeparator}795');

      service.processAmountInput(
        text: '100,00', // EUR formatted input
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcEurExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
        currentStateRate: kBtcUsdExchangeRate, // Previous rate was USD
      );

      // Should use current state rate (USD) for cleaning, not new rate (EUR)
      verify(() => mockFormatterProvider.cleanAmountString(
            '100,00',
            kBtcUsdExchangeRate.currency.format,
          )).called(1);
    });

    test('should handle zero fiat rate gracefully', () {
      final serviceWithoutRates = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: const AsyncValue.data([]),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('100.00');

      final result = serviceWithoutRates.processAmountInput(
        text: '100',
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.amountInSats, 0); // Should be 0 when fiat rate is 0
    });
  });

  group('different asset types', () {
    test('should handle USDT asset correctly', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(10000000000); // 100 USDT (8 decimals)

      when(() => mockFormatService.formatAssetAmount(
            asset: any(named: 'asset'),
            amount: any(named: 'amount'),
            displayUnitOverride: any(named: 'displayUnitOverride'),
          )).thenReturn('100.00000000');

      final result = service.processAmountInput(
        text: '100',
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: usdtAsset,
        balanceInSats: 10000000000,
      );

      expect(result.formattedAmountText, '100.00000000');
      expect(result.amountInSats, 10000000000);
    });
  });

  group('different display units', () {
    test('should handle sats unit correctly', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(100000); // 100k sats

      when(() => mockFormatService.formatAssetAmount(
            asset: any(named: 'asset'),
            amount: any(named: 'amount'),
            displayUnitOverride: any(named: 'displayUnitOverride'),
          )).thenReturn('100,000');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$56.69');

      final result = service.processAmountInput(
        text: '100000',
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.sats,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.formattedAmountText, '100,000');
      expect(result.amountInSats, 100000);
      expect(result.displayConversionAmount, '\$56.69');
    });

    test('should handle bits unit correctly', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(1000000); // 1M sats (10k bits)

      when(() => mockFormatService.formatAssetAmount(
            asset: any(named: 'asset'),
            amount: any(named: 'amount'),
            displayUnitOverride: any(named: 'displayUnitOverride'),
          )).thenReturn('10,000');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$566.90');

      final result = service.processAmountInput(
        text: '10000',
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.bits,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.formattedAmountText, '10,000');
      expect(result.amountInSats, 1000000);
      expect(result.displayConversionAmount, '\$566.90');
    });
  });

  group('edge cases', () {
    test('should handle empty string input', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(0);

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$0.00');

      final result = service.processAmountInput(
        text: '',
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.amountInSats, 0);
      expect(result.displayConversionAmount, null);
    });

    test('should handle very large amounts', () {
      const largeAmount = 2100000000000000; // 21M BTC in sats
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(largeAmount);

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '21,000,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$1,190,490,000,000.00');

      final result = service.processAmountInput(
        text: '21000000',
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: largeAmount,
      );

      expect(result.amountInSats, largeAmount);
      expect(result.displayConversionAmount, '\$1,190,490,000,000.00');
    });

    test('should handle decimal precision correctly', () {
      when(() => mockFormatterProvider.parseAssetAmountToSats(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            precision: any(named: 'precision'),
            forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
          )).thenReturn(1); // 1 sat

      when(() => mockFormatService.formatAssetAmount(
                asset: any(named: 'asset'),
                amount: any(named: 'amount'),
                displayUnitOverride: any(named: 'displayUnitOverride'),
              ))
          .thenReturn(
              '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}001');

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$0.00');

      final result = service.processAmountInput(
        text: '0.00000001',
        type: AquaAssetInputType.crypto,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
        balanceInSats: kOneBtcInSats,
      );

      expect(result.amountInSats, 1);
      expect(result.formattedAmountText,
          '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}001');
    });
  });

  group('error handling', () {
    test('should handle AsyncValue.loading for fiat rates', () {
      final serviceWithLoadingRates = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: const AsyncValue.loading(),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$0.00');

      final result = serviceWithLoadingRates.getBalanceDisplay(
        balanceInSats: kOneBtcInSats,
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
      );

      expect(result, '\$0.00'); // Should handle gracefully with 0 rate
    });

    test('should handle AsyncValue.error for fiat rates', () {
      final serviceWithErrorRates = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: AsyncValue.error('Error', StackTrace.current),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$0.00');

      final result = serviceWithErrorRates.getBalanceDisplay(
        balanceInSats: kOneBtcInSats,
        type: AquaAssetInputType.fiat,
        unit: AquaAssetInputUnit.crypto,
        rate: kBtcUsdExchangeRate,
        asset: btcAsset,
      );

      expect(result, '\$0.00'); // Should handle gracefully with 0 rate
    });
  });

  group('formatUsdtAmount', () {
    test('should format USDt amount in USD with symbol', () {
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$52.00');

      final result = service.formatUsdtAmount(
        amountInSats: 5200000000, // 52 USDt (precision 8)
        asset: usdtAsset,
        targetCurrency: FiatCurrency.usd,
        currencyFormat: FiatCurrency.usd.format,
        withSymbol: true,
      );

      expect(result, '\$52.00');
      verify(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: true,
            specOverride: FiatCurrency.usd.format,
          )).called(1);
    });

    test('should format USDt amount in USD without symbol', () {
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('52.00');

      final result = service.formatUsdtAmount(
        amountInSats: 5200000000, // 52 USDt
        asset: usdtAsset,
        targetCurrency: FiatCurrency.usd,
        currencyFormat: FiatCurrency.usd.format,
        withSymbol: false,
      );

      expect(result, '52.00');
      verify(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: false,
            specOverride: FiatCurrency.usd.format,
          )).called(1);
    });

    test('should convert USDt amount from USD to EUR with symbol', () {
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('€26.00');

      final result = service.formatUsdtAmount(
        amountInSats: 5200000000, // 52 USDt = 52 USD
        asset: usdtAsset,
        targetCurrency: FiatCurrency.eur,
        currencyFormat: FiatCurrency.eur.format,
        withSymbol: true,
      );

      // Verify conversion: 52 USD * (28345/56690) = 52 * 0.5 = 26 EUR
      expect(result, '€26.00');
    });

    test('should convert USDt amount from USD to CNY without symbol', () {
      // Add CNY rate to mock data
      final mockFiatRatesWithCny = [
        kBtcUsdFiatRate,
        const BitcoinFiatRatesResponse(
          rate: 400000.0,
          code: 'CNY',
          name: 'Chinese Yuan',
          cryptoCode: 'BTC',
          currencyPair: 'BTCCNY',
        ),
      ];

      final serviceWithCny = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: AsyncValue.data(mockFiatRatesWithCny),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('367.12');

      final result = serviceWithCny.formatUsdtAmount(
        amountInSats: 5200000000, // 52 USDt = 52 USD
        asset: usdtAsset,
        targetCurrency: FiatCurrency.cny,
        currencyFormat: FiatCurrency.cny.format,
        withSymbol: false,
      );

      // Verify conversion: 52 USD * (400000/56690) = 52 * 7.06 = 367.12 CNY
      expect(result, '367.12');
    });

    test('should handle missing target currency rate gracefully', () {
      // Service with only USD rate, no EUR
      final serviceWithLimitedRates = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: AsyncValue.data([kBtcUsdFiatRate]),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('€52.00'); // Falls back to USD amount with EUR symbol

      final result = serviceWithLimitedRates.formatUsdtAmount(
        amountInSats: 5200000000,
        asset: usdtAsset,
        targetCurrency: FiatCurrency.eur,
        currencyFormat: FiatCurrency.eur.format,
        withSymbol: true,
      );

      // Should fallback to USD amount (52) with EUR formatting
      expect(result, '€52.00');
    });

    test('should handle missing USD rate gracefully', () {
      // Service with only EUR rate, no USD
      final serviceWithoutUsd = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: AsyncValue.data([kBtcEurFiatRate]),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('€52.00'); // Falls back to USD amount

      final result = serviceWithoutUsd.formatUsdtAmount(
        amountInSats: 5200000000,
        asset: usdtAsset,
        targetCurrency: FiatCurrency.eur,
        currencyFormat: FiatCurrency.eur.format,
        withSymbol: true,
      );

      // Should fallback to USD amount (52)
      expect(result, '€52.00');
    });

    test('should handle zero USD rate gracefully', () {
      final mockRatesWithZeroUsd = [
        const BitcoinFiatRatesResponse(
          rate: 0.0, // Zero USD rate
          code: 'USD',
          name: 'US Dollar',
          cryptoCode: 'BTC',
          currencyPair: 'BTCUSD',
        ),
        kBtcEurFiatRate,
      ];

      final serviceWithZeroUsd = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: AsyncValue.data(mockRatesWithZeroUsd),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('€52.00');

      final result = serviceWithZeroUsd.formatUsdtAmount(
        amountInSats: 5200000000,
        asset: usdtAsset,
        targetCurrency: FiatCurrency.eur,
        currencyFormat: FiatCurrency.eur.format,
        withSymbol: true,
      );

      // Should fallback to USD amount when USD rate is 0
      expect(result, '€52.00');
    });

    test('should handle empty rates list', () {
      final serviceWithNoRates = AmountInputService(
        formatterProvider: mockFormatterProvider,
        formatProvider: mockFormatService,
        fiatRatesProvider: const AsyncValue.data([]),
        unitsProvider: mockDisplayUnitsProvider,
      );

      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$52.00');

      final result = serviceWithNoRates.formatUsdtAmount(
        amountInSats: 5200000000,
        asset: usdtAsset,
        targetCurrency: FiatCurrency.usd,
        currencyFormat: FiatCurrency.usd.format,
        withSymbol: true,
      );

      expect(result, '\$52.00');
    });

    test('should handle very small USDt amounts', () {
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$0.01');

      final result = service.formatUsdtAmount(
        amountInSats: 1000000, // 0.01 USDt
        asset: usdtAsset,
        targetCurrency: FiatCurrency.usd,
        currencyFormat: FiatCurrency.usd.format,
        withSymbol: true,
      );

      expect(result, '\$0.01');
    });

    test('should handle very large USDt amounts', () {
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            withSymbol: any(named: 'withSymbol'),
            specOverride: any(named: 'specOverride'),
          )).thenReturn('\$1,000,000.00');

      final result = service.formatUsdtAmount(
        amountInSats: 100000000000000, // 1M USDt
        asset: usdtAsset,
        targetCurrency: FiatCurrency.usd,
        currencyFormat: FiatCurrency.usd.format,
        withSymbol: true,
      );

      expect(result, '\$1,000,000.00');
    });
  });

  group('AmountInputResult', () {
    test('should create result with all required fields', () {
      const result = AmountInputResult(
        formattedAmountText: '1.00000000',
        amountInSats: 100000000,
        balanceDisplay: '1.00000000',
        displayConversionAmount: '\$56,690.00',
      );

      expect(result.formattedAmountText, '1.00000000');
      expect(result.amountInSats, 100000000);
      expect(result.balanceDisplay, '1.00000000');
      expect(result.displayConversionAmount, '\$56,690.00');
    });
  });
}
