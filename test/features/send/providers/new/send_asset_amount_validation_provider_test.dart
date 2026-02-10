import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';

const kMinServiceSendAmount = 0.1;
const kMaxServiceSendAmount = 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final asset = Asset.unknown();
  final args = SendAssetArguments.fromAsset(asset);
  final mockSwapPair = SwapPair(
    from: SwapAsset.fromAsset(asset),
    to: SwapAsset.fromAsset(asset),
  );
  final mockSwapRate = SwapRate(
    rate: DecimalExt.fromDouble(kBtcUsdRateSats),
    min: DecimalExt.fromDouble(kMinServiceSendAmount),
    max: Decimal.fromInt(kMaxServiceSendAmount),
  );

  final mockBalanceProvider = MockBalanceProvider();
  final mockPrefsProvider = MockUserPreferencesNotifier();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockSideshiftService = MockSideshiftService();
  final mockRegistry =
      MockSwapServicesRegistry(mockService: mockSideshiftService);
  final mockNotifier = MockSwapOrderCreationNotifier();
  final mockExchangeRatesProvider = ReferenceExchangeRateProviderMock();

  final container = ProviderContainer(overrides: [
    clipboardContentProvider.overrideWith((_) => null),
    balanceProvider.overrideWith((_) => mockBalanceProvider),
    prefsProvider.overrideWith((_) => mockPrefsProvider),
    bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
    swapServicesRegistryProvider.overrideWith(() => mockRegistry),
    swapOrderProvider.overrideWith(() => mockNotifier),
    exchangeRatesProvider.overrideWith((_) => mockExchangeRatesProvider),
  ]);

  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(args);
    registerFallbackValue(mockSwapPair);
    registerFallbackValue(mockSwapRate);
    registerFallbackValue(SwapOrderType.variable);

    // Set up exchange rates mock
    mockExchangeRatesProvider.mockGetCurrentCurrency(
        value: kBtcUsdExchangeRate);
    mockExchangeRatesProvider
        .mockGetAvailableCurrencies(value: [kBtcUsdExchangeRate]);
  });

  test('When amount is null, returns false to disable button', () async {
    mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
    mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
    mockBalanceProvider.mockGetBalanceCall(value: 100);
    final provider = sendAssetAmountValidationProvider(args);

    // Should complete without throwing and return false
    final result = await container.read(provider.future);

    expect(result, false,
        reason: 'Validation should return false when amount is null/zero');
    expect(provider.argument, isA<SendAssetArguments>());
    expect((provider.argument as SendAssetArguments).userEnteredAmount, null);
  });
  test('When amount is zero, returns false to disable button', () async {
    final provider = sendAssetAmountValidationProvider(
      args.copyWith(userEnteredAmount: Decimal.zero),
    );

    // Should complete without throwing and return false
    final result = await container.read(provider.future);

    expect(result, false,
        reason: 'Validation should return false when amount is zero');
    expect(provider.argument, isA<SendAssetArguments>());
    expect((provider.argument as SendAssetArguments).userEnteredAmount,
        Decimal.zero);
  });
  test('When balance is zero, input is valid', () async {
    mockBalanceProvider.mockGetBalanceCall(value: 0);
    final provider = sendAssetAmountValidationProvider(args);

    // Should complete without throwing
    await container.read(provider.future);
  });
  test('When amount exceeds balance, throws insufficient funds error',
      () async {
    mockBalanceProvider.mockGetBalanceCall(value: 100);
    final provider = sendAssetAmountValidationProvider(args.copyWith(
      userEnteredAmount: Decimal.fromInt(200),
    ));

    expect(
      () => container.read(provider.future),
      throwsA(isA<AmountParsingException>()),
    );

    try {
      await container.read(provider.future);
      fail('Expected AmountParsingException to be thrown');
    } catch (e) {
      expect(e, isA<AmountParsingException>());
      expect((e as AmountParsingException).type,
          AmountParsingExceptionType.notEnoughFunds);
    }
  });
  test('When amount below min GDK limit, throws limit error', () async {
    final provider = sendAssetAmountValidationProvider(args.copyWith(
      userEnteredAmount: Decimal.tryParse('0.00000001'),
    ));

    expect(
      () => container.read(provider.future),
      throwsA(isA<AmountParsingException>()),
    );

    try {
      await container.read(provider.future);
      fail('Expected AmountParsingException to be thrown');
    } catch (e) {
      expect(e, isA<AmountParsingException>());
      expect((e as AmountParsingException).type,
          AmountParsingExceptionType.belowMin);
    }
  });

  test('When amount is valid, returns true to enable button', () async {
    mockBalanceProvider.mockGetBalanceCall(value: 100000);
    final provider = sendAssetAmountValidationProvider(args.copyWith(
      userEnteredAmount: Decimal.tryParse('0.0001'),
    ));

    // Should complete without throwing and return true
    final result = await container.read(provider.future);

    expect(result, true,
        reason: 'Validation should return true when amount is valid');
  });

  group('Button State Logic', () {
    test('Button should be disabled when validation returns false', () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100);
      final provider = sendAssetAmountValidationProvider(args);

      final result = await container.read(provider.future);
      final isButtonEnabled = result == true;

      expect(isButtonEnabled, false,
          reason: 'Button should be disabled when amount is zero');
    });

    test('Button should be disabled when validation throws error', () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100);
      final provider = sendAssetAmountValidationProvider(args.copyWith(
        userEnteredAmount: Decimal.fromInt(200),
      ));

      try {
        await container.read(provider.future);
        fail('Expected exception');
      } catch (e) {
        // When there's an error, the button logic checks !hasError && valueOrNull == true
        final validationState = container.read(provider);
        final isButtonEnabled = !validationState.hasError &&
            !validationState.isLoading &&
            validationState.valueOrNull == true;
        expect(isButtonEnabled, false,
            reason: 'Button should be disabled when validation throws error');
        expect(validationState.hasError, true,
            reason:
                'Validation state should have error when exception is thrown');
      }
    });

    test('Button should be enabled when validation returns true', () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100000);
      final provider = sendAssetAmountValidationProvider(args.copyWith(
        userEnteredAmount: Decimal.tryParse('0.0001'),
      ));

      final result = await container.read(provider.future);
      final isButtonEnabled = result == true;

      expect(isButtonEnabled, true,
          reason: 'Button should be enabled when amount is valid');
    });
  });
}
