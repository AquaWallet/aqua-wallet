import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_components/ui_components.dart';

import '../../../mocks/mocks.dart';

const kSpecialBtcSeparator = '\u2009';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final asset = Asset.btc(amount: kPointOneBtcInSats);
  final args = ReceiveAmountArguments(asset: asset);

  final mockPrefsProvider = MockUserPreferencesNotifier();
  final mockAssetsNotifier = MockAssetsNotifier(assets: [asset]);
  final mockRefRateProvider = ReferenceExchangeRateProviderMock();
  final mockFiatRatesNotifier = MockFiatRatesNotifier(
    rates: [kBtcUsdFiatRate, kBtcEurFiatRate],
  );
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWith((_) => mockPrefsProvider),
    assetsProvider.overrideWith(() => mockAssetsNotifier),
    exchangeRatesProvider.overrideWith((_) => mockRefRateProvider),
    fiatRatesProvider.overrideWith(() => mockFiatRatesNotifier),
  ]);
  final provider = receiveAssetInputStateProvider(args);

  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(SupportedDisplayUnits.btc);
  });

  group('Initial State', () {
    test('input text should be empty', () async {
      mockPrefsProvider.mockGetDisplayUnitCall(SupportedDisplayUnits.btc);
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(state.amountFieldText, isNull);
    });
    test('input amount should be 0', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(state.amountInSats, 0);
    });
    test('display balance should be 0', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(state.amountInSats, 0);
    });
    test('fiat amount should be 0', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(state.displayConversionAmount, '\$0.00');
    });
    test('input unit should be crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(state.inputUnit, AquaAssetInputUnit.crypto);
    });
    test('input type should be crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(state.inputType, AquaAssetInputType.crypto);
    });
    test('swap pair should be null', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(state.swapPair, isNull);
    });
    test('exchange rate should be USD', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);

      final state = await container.read(provider.future);

      expect(
        state.rate,
        isA<ExchangeRate>()
            .having((e) => e.source, 'source', ExchangeRateSource.coingecko)
            .having((e) => e.currency, 'currency', FiatCurrency.usd),
      );
    });
  });
  group('Update amount text', () {
    test('should update amount field text', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 100;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final finalState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(finalState.amountFieldText,
          '100.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
    });
    test('should update fiat amount', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 100;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final finalState = await container.read(provider.future);

      expect(initialState.inputUnit, AquaAssetInputUnit.crypto);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(finalState.inputUnit, AquaAssetInputUnit.crypto);
      // 100 BTC * 56690 USD/BTC = 5669000 USD (now correctly formatted as fiat)
      expect(finalState.displayConversionAmount, '\$5,669,000.00');
    });
    test('should NOT update balance amount', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 100;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final finalState = await container.read(provider.future);

      expect(initialState.balanceInSats, kPointOneBtcInSats);
      expect(initialState.balanceDisplay,
          '0.10${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // 0.1
      expect(finalState.balanceInSats, kPointOneBtcInSats);
      expect(finalState.balanceDisplay,
          '0.10${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // 0.1
    });
    test('should NOT update input type', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 100;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final fiatState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final finalState = await container.read(provider.future);

      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(finalState.inputType, AquaAssetInputType.fiat);
    });
    test('should reset to initial values when removing input without decimal',
        () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kPointOneBtc.toString());

      final inputState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('');

      final finalState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amountInSats, 0);
      expect(initialState.displayConversionAmount, '\$0.00');

      expect(inputState.amountFieldText,
          '0.10${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(inputState.amountInSats, kPointOneBtcInSats);
      expect(inputState.displayConversionAmount, '\$5,669.00');

      expect(finalState.amountFieldText,
          '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(finalState.amountInSats, 0);
      expect(finalState.displayConversionAmount, '\$0.00');
    });
    test('should reset to initial values when removing input with decimal',
        () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1.5;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final inputState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('');

      final finalState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amountInSats, 0);
      expect(initialState.displayConversionAmount, '\$0.00');

      expect(inputState.amountFieldText,
          '1.50${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(inputState.amountInSats, 150000000);
      expect(inputState.displayConversionAmount, '\$85,035.00'); // 1.5 * 56690

      expect(finalState.amountFieldText,
          '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(finalState.amountInSats, 0);
      expect(finalState.displayConversionAmount, '\$0.00');
    });
  });
  group('Update input unit', () {
    test('initial input unit should be crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final state = await container.read(provider.future);

      expect(state.inputUnit, AquaAssetInputUnit.crypto);
    });
    test('should change input unit from crypto to sats', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kInputAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amountInSats, 0);
      expect(initialState.displayConversionAmount, '\$0.00');
      // 100 BTC * 56690 USD/BTC = 5669000 USD (now correctly formatted as fiat)
      expect(cryptoState.amountFieldText,
          '100.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.amountInSats, kOneBtcInSats * kInputAmount);
      expect(cryptoState.displayConversionAmount, '\$5,669,000.00');
      // 100 Sats * 56690 USD/BTC / 100000000 sats/BTC = 0.057 USD
      expect(satsState.amountFieldText, '100');
      expect(satsState.amountInSats, kInputAmount);
      expect(satsState.displayConversionAmount, '\$0.06');
    });
    test('should change input unit from crypto to bits', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kInputAmount.toString());

      final bitsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amountInSats, 0);
      // 100 BTC * 56690 USD/BTC = 5669000 USD
      expect(cryptoState.amountFieldText,
          '100.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.amountInSats, 10000000000);
      expect(cryptoState.displayConversionAmount, '\$5,669,000.00');
      // 100 bits * 100 sats/bit = 10000 sats
      expect(bitsState.amountFieldText, '100');
      expect(bitsState.amountInSats, 10000);
      expect(bitsState.displayConversionAmount, '\$5.67');
    });
    test('should change input unit from sats to crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString()); // 0.01 BTC in sats

      final satsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString()); // 100000000 BTC

      final cryptoState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(satsState.amountFieldText, '1,000,000');
      expect(satsState.displayConversionAmount, '\$566.90');
      expect(cryptoState.amountFieldText,
          '1,000,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.displayConversionAmount, '\$56,690,000,000.00');
    });
    test('should change input unit from bits to sats', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000; // 1M bits = 1 BTC

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      // 1M bits * 100 sats/bit = 100M sats (1 BTC)
      expect(bitsState.amountFieldText, '1,000,000');
      expect(bitsState.amountInSats, 100000000);
      expect(bitsState.displayConversionAmount, '\$56,690.00');
      expect(satsState.amountFieldText, '1,000,000');
      expect(satsState.amountInSats, 1000000);
      expect(satsState.displayConversionAmount, '\$566.90');
    });
    test('should change input unit from sats to bits', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString());

      final satsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(satsState.amountFieldText, '1,000,000');
      expect(satsState.amountInSats, 1000000);
      expect(satsState.displayConversionAmount, '\$566.90');
      expect(bitsState.amountFieldText, '1,000,000');
      // 1,000,000 bits * 100 sats/bit
      expect(bitsState.amountInSats, 100000000);
    });
    test('should change input unit from bits to crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 10000; // 0.1 BTC in bits

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString());

      final cryptoState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      // 10000 bits * 100 sats/bit = 1M sats (0.01 BTC)
      expect(bitsState.amountFieldText, '10,000');
      expect(bitsState.amountInSats, 1000000);
      expect(bitsState.displayConversionAmount, '\$566.90');
      expect(cryptoState.amountFieldText,
          '10,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.amountInSats, 1000000000000);
      expect(cryptoState.displayConversionAmount, '\$566,900,000.00');
    });
    test('should change input unit from crypto to sats', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kBtcAmount = 2.0; // 2 BTC
      const kSatAmount = 200000000; // 2 BTC in sats

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kBtcAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kSatAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(cryptoState.amountFieldText,
          '2.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.displayConversionAmount, '\$113,380.00');
      expect(satsState.amountFieldText, '200,000,000');
      expect(satsState.displayConversionAmount, '\$113,380.00');
    });

    test('should change fiat rate on input unit from crypto to sats', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kInputAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      // 100 BTC * 56690 USD/BTC = 5669000 USD
      expect(cryptoState.displayConversionAmount, '\$5,669,000.00');
      // 100 Sats * 56690 USD/BTC / 100000000 sats/BTC = 0.057 USD
      expect(satsState.displayConversionAmount, '\$0.06');
    });
    test('should change fiat rate on input unit from crypto to bits', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kInputAmount.toString());

      final bitsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amountInSats, 0);
      // 100 BTC * 56690 USD/BTC = 5669000 USD
      expect(cryptoState.amountFieldText,
          '100.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.amountInSats, 10000000000);
      expect(cryptoState.displayConversionAmount, '\$5,669,000.00');
      // 100 Bits * 100 sats/bit * 56690 USD/BTC / 100000000 sats/BTC = 5.67 USD
      expect(bitsState.amountFieldText, '100');
      expect(bitsState.amountInSats, 10000); // 100 bits * 100 sats/bit
      expect(bitsState.displayConversionAmount, '\$5.67');
    });
    test('should change fiat rate on input unit from sats to crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString()); // 0.01 BTC in sats

      final satsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString()); // 100000000 BTC

      final cryptoState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(satsState.amountFieldText, '1,000,000');
      expect(satsState.displayConversionAmount, '\$566.90');
      expect(cryptoState.amountFieldText,
          '1,000,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.displayConversionAmount, '\$56,690,000,000.00');
    });
    test('should change fiat rate on input unit from bits to sats', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(bitsState.amountFieldText, '1,000,000');
      // 1,000,000 bits * 100 sats/bit
      expect(bitsState.amountInSats, 100000000);
      expect(bitsState.displayConversionAmount, '\$56,690.00');
      expect(satsState.amountFieldText, '1,000,000');
      expect(satsState.amountInSats, 1000000);
      expect(satsState.displayConversionAmount, '\$566.90');
    });
    test('should change fiat rate on input unit from sats to bits', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString());

      final satsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(satsState.amountFieldText, '1,000,000');
      expect(satsState.amountInSats, 1000000);
      expect(satsState.displayConversionAmount, '\$566.90');
      expect(bitsState.amountFieldText, '1,000,000');
      // 1,000,000 bits * 100 sats/bit
      expect(bitsState.amountInSats, 100000000);
    });
    test('should change fiat rate on input unit from bits to crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 10000; // 0.1 BTC in bits

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString());

      final cryptoState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(bitsState.amountFieldText, '10,000');
      expect(bitsState.amountInSats, 1000000); // 10,000 bits * 100 sats/bit
      expect(bitsState.displayConversionAmount, '\$566.90');
      expect(cryptoState.amountFieldText,
          '10,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.amountInSats, 1000000000000);
      expect(cryptoState.displayConversionAmount, '\$566,900,000.00');
    });
    test('should change fiat rate on input unit from crypto to sats', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kBtcAmount = 2.0; // 2 BTC
      const kSatAmount = 200000000; // 2 BTC in sats

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kBtcAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kSatAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(cryptoState.amountFieldText,
          '2.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.displayConversionAmount, '\$113,380.00');
      expect(satsState.amountFieldText, '200,000,000');
      expect(satsState.displayConversionAmount, '\$113,380.00');
    });
    test('should preserve amount sats on crypto to sats change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kInputAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(cryptoState.amountInSats, 10000000000);
      expect(satsState.amountInSats, 100);
    });
    test('should preserve amount sats on crypto to bits change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kInputAmount.toString());

      final bitsState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(cryptoState.amountInSats, 10000000000);
      expect(bitsState.amountInSats, 10000); // 100 bits * 100 sats/bit
    });
    test('should preserve amount sats on sats to crypto change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString()); // 0.01 BTC in sats

      final satsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString()); // 100000000 BTC

      final cryptoState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(satsState.amountInSats, 1000000);
      expect(cryptoState.amountInSats, 100000000000000);
    });
    test('should preserve amount sats on bits to sats change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      // 1,000,000 bits * 100 sats/bit
      expect(bitsState.amountInSats, 100000000);
      expect(satsState.amountInSats, 1000000);
    });
    test('should preserve amount sats on sats to bits change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1000000;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString());

      final satsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(satsState.amountInSats, 1000000);
      // 1,000,000 bits * 100 sats/bit
      expect(bitsState.amountInSats, 100000000);
    });

    test('should preserve amount sats on bits to crypto change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 10000; // 0.1 BTC in bits

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString());

      final bitsState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString());

      final cryptoState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(bitsState.amountInSats, 1000000); // 10,000 bits * 100 sats/bit
      expect(cryptoState.amountInSats, 1000000000000);
    });
    test('should preserve amount sats on crypto to sats change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kBtcAmount = 2.0; // 2 BTC
      const kSatAmount = 200000000; // 2 BTC in sats

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kBtcAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kSatAmount.toString());

      final satsState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(cryptoState.amountInSats, 200000000);
      expect(satsState.amountInSats, 200000000);
    });
  });
  group('Update input type', () {
    test('should change input type from crypto to fiat', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final fiatState = await container.read(provider.future);

      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
    });
    test('should change balance value on input type change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final fiatState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.crypto);

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final finalState = await container.read(provider.future);

      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(finalState.inputType, AquaAssetInputType.fiat);
      expect(initialState.balanceDisplay,
          '0.10${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(fiatState.balanceDisplay, '\$5,669.00');
      expect(cryptoState.balanceDisplay,
          '0.10${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(finalState.balanceDisplay, '\$5,669.00');
    });
    test('should swap values on Crypto to Fiat', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kCryptoAmount = 1;
      const kFiatAmount = 100;

      await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kCryptoAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..updateAmountFieldText(kFiatAmount.toString());

      final fiatState = await container.read(provider.future);

      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(cryptoState.amountFieldText,
          '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.displayConversionAmount, '\$56,690.00');
      expect(fiatState.amountFieldText, '100.00');
      expect(fiatState.displayConversionAmount,
          '0.00${kSpecialBtcSeparator}176${kSpecialBtcSeparator}397');
    });
    test('should swap values on Fiat to Crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kFiatAmount = 1000;
      const kCryptoAmount = 1;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..updateAmountFieldText(kFiatAmount.toString());

      final fiatState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.crypto)
        ..updateAmountFieldText(kCryptoAmount.toString());

      final cryptoState = await container.read(provider.future);

      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.amountFieldText, '1,000.00');
      expect(fiatState.displayConversionAmount,
          '0.01${kSpecialBtcSeparator}763${kSpecialBtcSeparator}979');
      expect(cryptoState.amountFieldText,
          '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.displayConversionAmount, '\$56,690.00');
    });
    test('should preserve amount sats on input type change', () async {
      const kFiatAmount = 1000;
      const kCryptoAmount = 1;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..updateAmountFieldText(kFiatAmount.toString());

      final fiatState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.crypto)
        ..updateAmountFieldText(kCryptoAmount.toString());

      final cryptoState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(fiatState.amountInSats, 1763979);
      expect(cryptoState.amountInSats, 100000000);
    });
    test('should change unit to crypto on input type change to fiat', () async {
      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..setType(AquaAssetInputType.fiat);

      final fiatState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.crypto)
        ..setUnit(AquaAssetInputUnit.bits);

      final cryptoState = await container.read(provider.future);

      expect(initialState.inputUnit, AquaAssetInputUnit.crypto);
      expect(fiatState.inputUnit, AquaAssetInputUnit.crypto);
      expect(cryptoState.inputUnit, AquaAssetInputUnit.bits);
    });
    test('should have correct conversion when input type is changed to fiat',
        () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('1');

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final fiatState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      expect(cryptoState.displayConversionAmount, '\$56,690.00');
      // When switching from crypto to fiat, "1" BTC is converted to its fiat value ($56,690), so displayConversionAmount shows crypto equivalent of $56,690 which is 1 BTC
      expect(fiatState.displayConversionAmount,
          '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
    });
    test('should have correct conversion when switching from sats to fiat',
        () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('100000');

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier).setUnit(AquaAssetInputUnit.sats);

      final satsState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final fiatState = await container.read(provider.future);

      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(initialState.inputUnit, AquaAssetInputUnit.crypto);
      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');

      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(cryptoState.inputUnit, AquaAssetInputUnit.crypto);
      expect(cryptoState.amountFieldText,
          '100,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(cryptoState.displayConversionAmount, '\$5,669,000,000.00');

      expect(satsState.inputType, AquaAssetInputType.crypto);
      expect(satsState.inputUnit, AquaAssetInputUnit.sats);
      expect(satsState.amountFieldText, '100,000');
      expect(satsState.displayConversionAmount, '\$56.69');

      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(fiatState.inputUnit, AquaAssetInputUnit.crypto);
      expect(fiatState.amountFieldText, '56.69');
      // When switching from sats to fiat, "100,000" sats becomes "$56.69", so displayConversionAmount shows crypto equivalent of $56.69
      expect(fiatState.displayConversionAmount, '100,000');
    });

    group('Swap button behavior', () {
      test('should convert actual BTC value when swapping crypto to fiat',
          () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Type "1" in crypto mode (1 BTC = 100M sats)
        container.read(provider.notifier).updateAmountFieldText('1');
        final cryptoState = await container.read(provider.future);

        // Swap to fiat - should convert 1 BTC to its USD value
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final fiatState = await container.read(provider.future);

        expect(cryptoState.amountFieldText,
            '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
        expect(cryptoState.displayConversionAmount, '\$56,690.00');

        expect(fiatState.amountFieldText, '56,690.00'); // 1 BTC = $56,690
        expect(fiatState.displayConversionAmount,
            '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // $56,690 = 1 BTC
      });

      test('should convert actual sat value when swapping sats to fiat',
          () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Type "100000" in crypto mode then switch to sats
        container.read(provider.notifier)
          ..updateAmountFieldText('100000')
          ..setUnit(AquaAssetInputUnit.sats);

        final satsState = await container.read(provider.future);

        // Swap to fiat - should convert the actual satoshi value, not treat display as fiat amount
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final fiatState = await container.read(provider.future);

        expect(satsState.amountFieldText, '100,000');
        expect(satsState.displayConversionAmount, '\$56.69');

        expect(fiatState.amountFieldText, '56.69');
        expect(fiatState.displayConversionAmount, '100,000');
      });

      test('should convert actual USD value when swapping fiat to crypto',
          () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Switch to fiat mode first and type "100"
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        container.read(provider.notifier).updateAmountFieldText('100');
        final fiatState = await container.read(provider.future);

        // Swap back to crypto - should convert $100 to its BTC value
        container.read(provider.notifier).setType(AquaAssetInputType.crypto);
        final cryptoState = await container.read(provider.future);

        expect(fiatState.amountFieldText, '100.00');
        expect(fiatState.displayConversionAmount,
            '0.00${kSpecialBtcSeparator}176${kSpecialBtcSeparator}397'); // $100 = 176397 sats

        expect(cryptoState.amountFieldText,
            '0.00${kSpecialBtcSeparator}176${kSpecialBtcSeparator}397'); // 176397 sats in BTC format
        expect(cryptoState.displayConversionAmount,
            '\$100.00'); // 176397 sats = $100
      });

      test('should handle edge case with large amounts', () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Type "1000000" in crypto mode (1 million BTC)
        container.read(provider.notifier).updateAmountFieldText('1000000');
        final cryptoState = await container.read(provider.future);

        // Swap to fiat - should convert 1M BTC to USD
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final fiatState = await container.read(provider.future);

        expect(cryptoState.displayConversionAmount, '\$56,690,000,000.00');
        expect(fiatState.amountFieldText, '56,690,000,000.00'); // 1M BTC in USD
        expect(fiatState.displayConversionAmount,
            startsWith('1,000,000.00')); // Should show 1M BTC
      });

      test('should handle zero amount edge case', () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Initial state has 0 amount
        final initialState = await container.read(provider.future);

        // Swap to fiat with zero amount - should not crash
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final fiatState = await container.read(provider.future);

        expect(initialState.displayConversionAmount, '\$0.00');
        expect(fiatState.displayConversionAmount,
            '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      });
    });

    group('Currency change in fiat mode behavior', () {
      test(
          'should convert BTC to fiat when swapping, then preserve numeric value on currency change',
          () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Type "1" in crypto mode (1 BTC), then swap to fiat (converts to $56,690)
        container.read(provider.notifier).updateAmountFieldText('1');
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final usdState = await container.read(provider.future);

        // Change currency to EUR
        container.read(provider.notifier).setRate(kBtcEurExchangeRate);
        final eurState = await container.read(provider.future);

        expect(usdState.amountFieldText, '56,690.00'); // 1 BTC converted to USD
        expect(usdState.displayConversionAmount,
            '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // $56,690 = 1 BTC

        // After currency change:
        // - amountFieldText becomes €56,690 (same numeric value, different currency)
        // - displayConversionAmount shows BTC equivalent of €56,690
        expect(eurState.amountFieldText,
            '56.690,00'); // 56,690 USD → €56,690 EUR (EUR uses comma as decimal separator)
        expect(eurState.displayConversionAmount,
            '2.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // €56,690 = ~2 BTC
      });

      test(
          'should not show zero when changing currency in fiat mode (original bug)',
          () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Simulate the exact user scenario: type 1, swap to fiat, then change currency
        container.read(provider.notifier).updateAmountFieldText('1');
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final usdState = await container.read(provider.future);

        container.read(provider.notifier).setRate(kBtcEurExchangeRate);
        final eurState = await container.read(provider.future);

        // The bug was that displayConversionAmount became '0.00 000 000'
        // NEW BEHAVIOR: 1 BTC converts to $56,690, then becomes €56,690
        expect(usdState.displayConversionAmount,
            '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // $56,690 = 1 BTC
        expect(eurState.displayConversionAmount,
            '2.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // €56,690 = ~2 BTC
        expect(
            eurState.displayConversionAmount,
            isNot(
                '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000')); // NOT zero!
      });

      test('should handle multiple currency changes correctly', () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Start with $10 fiat amount
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        container.read(provider.notifier).updateAmountFieldText('10');
        final initialState = await container.read(provider.future);

        // Change USD → EUR → USD
        container.read(provider.notifier).setRate(kBtcEurExchangeRate);
        final eurState = await container.read(provider.future);

        container.read(provider.notifier).setRate(kBtcUsdExchangeRate);
        final backToUsdState = await container.read(provider.future);

        // NEW BEHAVIOR: Satoshi amounts change because display values are treated as new currency amounts
        // $10 USD (17639 sats) → €10 EUR (35279 sats) → $10 USD (17639 sats)
        expect(initialState.amountInSats, 17639); // $10 USD
        expect(eurState.amountInSats, 35279); // €10 EUR
        expect(backToUsdState.amountInSats, 17639); // $10 USD again

        // Display conversion amounts should be consistent for same currency amounts
        expect(initialState.displayConversionAmount,
            backToUsdState.displayConversionAmount);
        // But EUR will have different displayConversionAmount (because €10 ≠ $10 in BTC terms)
        expect(eurState.displayConversionAmount,
            isNot(initialState.displayConversionAmount));
      });

      test('should maintain correct formatting when currency changes',
          () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Start with $1000 fiat amount
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        container.read(provider.notifier).updateAmountFieldText('1000');
        final usdState = await container.read(provider.future);

        container.read(provider.notifier).setRate(kBtcEurExchangeRate);
        final eurState = await container.read(provider.future);

        // Check that amountFieldText is properly formatted for new currency
        expect(usdState.amountFieldText, '1,000.00'); // USD formatting
        // NEW BEHAVIOR: $1000 becomes €1000 (not EUR equivalent)
        expect(eurState.amountFieldText, '1.000,00'); // EUR formatting of 1000
        expect(eurState.amountFieldText,
            contains(',')); // Should include thousands separator

        // displayConversionAmount should remain in crypto format
        expect(
            eurState.displayConversionAmount, contains(kSpecialBtcSeparator));
        expect(eurState.displayConversionAmount, isNot(contains('\$')));
        expect(eurState.displayConversionAmount, isNot(contains('€')));
      });

      test('USER REPORTED BUG: exact scenario reproduction', () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // Step 1: Type "1" in crypto mode (1 BTC)
        container.read(provider.notifier).updateAmountFieldText('1');
        final step1 = await container.read(provider.future);

        // Step 2: Switch to fiat via swap button (converts 1 BTC to $56,690)
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final step2 = await container.read(provider.future);

        // Step 3: Change currency to EUR (keeps $56,690 as €56,690)
        container.read(provider.notifier).setRate(kBtcEurExchangeRate);
        final step3 = await container.read(provider.future);

        // Verify the behavior is correct
        expect(step1.displayConversionAmount,
            startsWith('\$')); // Should show USD equivalent
        expect(step2.displayConversionAmount,
            '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // $56,690 = 1 BTC

        // The key fix: displayConversionAmount should NOT be zero after currency change
        expect(
            step3.displayConversionAmount,
            isNot(
                '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000')); // Should NOT be zero
        expect(step3.displayConversionAmount,
            contains(kSpecialBtcSeparator)); // Should be in crypto format
        expect(step3.displayConversionAmount,
            isNot(contains('€'))); // Should not contain currency symbol

        // NEW BEHAVIOR: $56,690 USD becomes €56,690 EUR (different BTC amounts)
        // $56,690 USD = 1 BTC, €56,690 EUR = ~2 BTC
        expect(step3.displayConversionAmount,
            '2.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // €56,690 = ~2 BTC
      });

      test('UI CALL SEQUENCE: setRate then setUnit (like currency picker)',
          () async {
        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await container.read(provider.future);

        // User types "1" in crypto mode (1 BTC)
        container.read(provider.notifier).updateAmountFieldText('1');

        // User swaps to fiat mode (converts 1 BTC to $56,690)
        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final afterSwap = await container.read(provider.future);

        // User opens currency picker and selects EUR + crypto unit
        // This triggers the EXACT call sequence from receive_amount_screen.dart:
        final notifier = container.read(provider.notifier);
        notifier.setRate(kBtcEurExchangeRate); // Called first
        notifier.setUnit(AquaAssetInputUnit.crypto); // Called second
        final finalState = await container.read(provider.future);

        // Verify the fix: displayConversionAmount should be recalculated, not zero
        expect(
            afterSwap.amountInSats, 100000000); // $56,690 = 1 BTC = 100M sats

        // The key fix: treat displayed amount as new currency amount
        // $56,690 USD → €56,690 EUR (not equivalent conversion, but same numeric value)
        expect(finalState.displayConversionAmount,
            '2.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // €56,690 = ~2 BTC
        expect(
            finalState.displayConversionAmount,
            isNot(
                '0.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000')); // Should NOT be zero
      });

      test('USER LIVE RATES: exact scenario with live BTC rates', () async {
        // Use the exact live rates from user's scenario
        const liveBtcUsdRate = 108570.02;
        const liveBtcEurRate = 92902.44;

        const liveBtcUsdFiatRate = BitcoinFiatRatesResponse(
            rate: liveBtcUsdRate,
            code: 'USD',
            name: 'US Dollar',
            cryptoCode: 'BTC',
            currencyPair: 'BTCUSD');
        const liveBtcEurFiatRate = BitcoinFiatRatesResponse(
            rate: liveBtcEurRate,
            code: 'EUR',
            name: 'Euro',
            cryptoCode: 'BTC',
            currencyPair: 'BTCEUR');

        // Create test container with live rates
        final liveRatesMockNotifier = MockFiatRatesNotifier(
            rates: [liveBtcUsdFiatRate, liveBtcEurFiatRate]);
        final liveContainer = ProviderContainer(overrides: [
          prefsProvider.overrideWith((_) => mockPrefsProvider),
          assetsProvider.overrideWith(() => mockAssetsNotifier),
          exchangeRatesProvider.overrideWith((_) => mockRefRateProvider),
          fiatRatesProvider.overrideWith(() => liveRatesMockNotifier),
        ]);

        mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
        await liveContainer.read(provider.future);

        // Step 1: Type "1" BTC → should show $108,570.02
        liveContainer.read(provider.notifier).updateAmountFieldText('1');
        final step1 = await liveContainer.read(provider.future);
        expect(step1.displayConversionAmount, startsWith('\$108,'));

        // Step 2: Swap to fiat → should convert 1 BTC to $108,570.02
        liveContainer.read(provider.notifier).setType(AquaAssetInputType.fiat);
        final step2 = await liveContainer.read(provider.future);
        expect(step2.displayConversionAmount,
            '1.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000'); // $108,570 = 1 BTC

        // Step 3: Change to EUR → $108,570 becomes €108,570
        final notifier = liveContainer.read(provider.notifier);
        notifier.setRate(kBtcEurExchangeRate);
        notifier.setUnit(AquaAssetInputUnit.crypto);
        final step3 = await liveContainer.read(provider.future);
        logger.debug('Step 3: ${step3.displayConversionAmount}');

        // €108,570 should show its BTC equivalent (~1.17 BTC)
        expect(step3.displayConversionAmount, startsWith('1.1'));
        expect(step3.displayConversionAmount, contains(kSpecialBtcSeparator));

        liveContainer.dispose();
      });
    });
  });
  group('Update currency', () {
    test('should change fiat rate on currency change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final usdState = await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final eurState = await container.read(provider.future);

      expect(
        usdState.rate,
        isA<ExchangeRate>()
            .having((r) => r.currency, 'currency', FiatCurrency.usd)
            .having((r) => r.source, 'source', ExchangeRateSource.coingecko),
      );
      expect(
        eurState.rate,
        isA<ExchangeRate>()
            .having((r) => r.currency, 'currency', FiatCurrency.eur)
            .having((r) => r.source, 'source', ExchangeRateSource.bitfinex),
      );
    });
    test('should change balance value on currency change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..setRate(kBtcEurExchangeRate);

      final eurState = await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);

      final usdState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..setRate(kBtcEurExchangeRate);

      final finalState = await container.read(provider.future);

      expect(initialState.balanceDisplay,
          '0.10${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(eurState.balanceDisplay, '€2.834,50');
      expect(usdState.balanceDisplay, '\$5,669.00');
      expect(finalState.balanceDisplay, '€2.834,50');
    });
    test('should change fiat conversion rate on currency change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 100;
      final initialState = await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..updateAmountFieldText(kAmount.toString());

      final usdState = await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final eurState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      expect(usdState.displayConversionAmount, kOneHundredUsdInBtcDisplay);
      // NEW BEHAVIOR: When currency changes from USD to EUR, treat displayed amount as new currency
      // So $100 USD becomes €100 EUR (not EUR equivalent of $100)
      expect(eurState.displayConversionAmount, kOneHundredEurInBtcDisplay);
    });
    test('should change crypto conversion rate on currency change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 0.1;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final usdState = await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final eurState = await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);

      final finalState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      expect(usdState.displayConversionAmount, '\$5,669.00');
      expect(eurState.displayConversionAmount, '€2.834,50');
      expect(finalState.displayConversionAmount, '\$5,669.00');
    });
    test('should preserve amount sats on currency change', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 0.1;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final usdState = await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final eurState = await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);

      final finalState = await container.read(provider.future);

      expect(initialState.amountInSats, 0);
      expect(usdState.amountInSats, 10000000);
      expect(eurState.amountInSats, 10000000);
      expect(finalState.amountInSats, 10000000);
    });
  });
  group('Submit amount', () {
    test('should submit sats amount when input unit is crypto', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 1.5; // 1.5 BTC

      await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString())
        ..submitAmount();

      final finalState = await container.read(provider.future);
      final submittedAmount = container.read(receiveAssetAmountProvider);

      expect(finalState.amountFieldText,
          '1.50${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(finalState.amountInSats, 150000000); //150000000 sats
      expect(submittedAmount, '150000000');
    });
    test('should submit sats amount when input unit is sats', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 150000000; // 1.5 BTC in sats

      await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString())
        ..submitAmount();

      final finalState = await container.read(provider.future);
      final submittedAmount = container.read(receiveAssetAmountProvider);

      expect(finalState.amountFieldText, '150,000,000');
      expect(finalState.amountInSats, 150000000);
      expect(submittedAmount, '150000000');
    });
    test('should submit sats amount when asset input unit is bits', () async {
      const kAmount = 1000000; // 0.01 BTC in bits

      await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.bits)
        ..updateAmountFieldText(kAmount.toString())
        ..submitAmount();

      final finalState = await container.read(provider.future);
      final submittedAmount = container.read(receiveAssetAmountProvider);

      expect(finalState.amountFieldText, '1,000,000');
      // 1,000,000 bits * 100 sats/bit = 100,000,000 sats (1 BTC)
      expect(finalState.amountInSats, 100000000);
      expect(submittedAmount, '100000000');
    });

    test('should submit sats amount when input is fiat', () async {
      const kFiatAmount = 100000; // $100,000 USD

      await container.read(provider.future);

      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..updateAmountFieldText(kFiatAmount.toString())
        ..submitAmount();

      final finalState = await container.read(provider.future);
      final submittedAmount = container.read(receiveAssetAmountProvider);

      expect(finalState.amountFieldText, '100,000.00');
      expect(finalState.amountInSats, 176397953);
      expect(submittedAmount, '176397953');
    });

    test('should submit USD amount for USDT when input is USD', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kFiatAmount = 100; // $100 USD

      final args = ReceiveAmountArguments(asset: Asset.usdtLiquid());
      final provider = receiveAssetInputStateProvider(args);
      await container.read(provider.future);

      container.read(provider.notifier)
        ..updateAmountFieldText(kFiatAmount.toString())
        ..submitAmount();

      final finalState = await container.read(provider.future);
      final submittedAmount = container.read(receiveAssetAmountProvider);

      expect(finalState.amountFieldText, '100');
      expect(submittedAmount, '100.0');
    });

    test('should submit sats amount when switching input units', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      const kAmount = 5000; // 0.00005 BTC in sats

      await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kAmount.toString())
        ..setUnit(AquaAssetInputUnit.bits)
        ..setUnit(AquaAssetInputUnit.crypto)
        ..updateAmountFieldText(kAmount.toString())
        ..submitAmount();

      final finalState = await container.read(provider.future);
      final submittedAmount = container.read(receiveAssetAmountProvider);

      expect(finalState.amountFieldText,
          '5,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(finalState.inputType, AquaAssetInputType.crypto);
      expect(finalState.inputUnit, AquaAssetInputUnit.crypto);
      expect(finalState.amountInSats, 500000000000);
      expect(submittedAmount, '500000000000');
    });

    test('should submit sats amount when switching input types', () async {
      const kCryptoAmount = 1.5;
      const kSatsAmount = 150000000; // 1.5 BTC in sats

      await container.read(provider.future);

      container.read(provider.notifier)
        ..setUnit(AquaAssetInputUnit.sats)
        ..updateAmountFieldText(kSatsAmount.toString())
        ..setType(AquaAssetInputType.fiat)
        ..setType(AquaAssetInputType.crypto)
        ..setType(AquaAssetInputType.fiat)
        ..setType(AquaAssetInputType.crypto)
        ..updateAmountFieldText(kCryptoAmount.toString())
        ..submitAmount();

      final finalState = await container.read(provider.future);
      final submittedAmount = container.read(receiveAssetAmountProvider);

      expect(finalState.amountFieldText,
          '1.50${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(submittedAmount, '150000000');
    });
  });
  group('Display conversion formatting bugs', () {
    test('should show fiat format when typing crypto amount (Bug #1)',
        () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      await container.read(provider.future);

      // Type "1" in crypto mode
      container.read(provider.notifier).updateAmountFieldText('1');
      final state = await container.read(provider.future);

      // displayConversionAmount should show fiat format with symbol, not crypto format
      expect(state.displayConversionAmount, startsWith('\$'));
      expect(state.displayConversionAmount, isNot(contains('000')));
      expect(
          state.displayConversionAmount, '\$56,690.00'); // Based on kBtcUsdRate
    });

    test('should show fiat format when clearing crypto input (Bug #2)',
        () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      await container.read(provider.future);

      // Type "1" then clear it
      container.read(provider.notifier)
        ..updateAmountFieldText('1')
        ..clearInput();
      final state = await container.read(provider.future);

      // displayConversionAmount should show fiat format "$0.00", not crypto format "0.00 000 000"
      expect(state.displayConversionAmount, '\$0.00');
      expect(state.displayConversionAmount, isNot(contains('000')));
    });

    test('should show crypto format when input type is fiat', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      await container.read(provider.future);

      // Switch to fiat mode and type "100"
      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..updateAmountFieldText('100');
      final state = await container.read(provider.future);

      // displayConversionAmount should show crypto format when input is fiat
      // For $100 at kBtcUsdRate (56690), the BTC amount should be around 0.00176397
      expect(state.displayConversionAmount,
          '0.00${kSpecialBtcSeparator}176${kSpecialBtcSeparator}397');
      expect(state.displayConversionAmount, isNot(startsWith('\$')));
    });
  });

  group('Clear input', () {
    test('should clear input', () async {
      mockRefRateProvider.mockGetCurrentCurrency(value: kBtcUsdExchangeRate);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('100000');

      final inputState = await container.read(provider.future);

      container.read(provider.notifier).clearInput();

      final finalState = await container.read(provider.future);

      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(initialState.inputUnit, AquaAssetInputUnit.crypto);
      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');

      expect(inputState.inputType, AquaAssetInputType.crypto);
      expect(inputState.inputUnit, AquaAssetInputUnit.crypto);
      expect(inputState.amountFieldText,
          '100,000.00${kSpecialBtcSeparator}000${kSpecialBtcSeparator}000');
      expect(inputState.displayConversionAmount, '\$5,669,000,000.00');

      expect(finalState.inputType, AquaAssetInputType.crypto);
      expect(finalState.inputUnit, AquaAssetInputUnit.crypto);
      expect(finalState.amountFieldText, isNull);
      expect(finalState.displayConversionAmount, '\$0.00');
    });
  });
}
