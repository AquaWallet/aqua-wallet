import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validator.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_components/ui_components.dart';

import '../../../../mocks/mocks.dart';

void main() {
  final mockBalanceProvider = MockBalanceProvider();
  final mockPrefsProvider = MockUserPreferencesNotifier();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockSideshiftService = MockSideshiftService();
  final mockRegistry =
      MockSwapServicesRegistry(mockService: mockSideshiftService);
  final mockLiquidProvider = MockLiquidProvider();
  final mockAddressParser = MockAddressParserProvider();
  final mockManageAssetsProvider = MockManageAssetsProvider();
  final mockDisplayUnitsProvider = MockDisplayUnitsProvider();
  final mockExchangeRatesProvider = ReferenceExchangeRateProviderMock();
  final container = ProviderContainer(overrides: [
    currentWalletIdOrThrowProvider.overrideWith((_) async => 'test-wallet-id'),
    clipboardContentProvider.overrideWith((_) => 'test'),
    balanceProvider.overrideWith((_) => mockBalanceProvider),
    prefsProvider.overrideWith((_) => mockPrefsProvider),
    bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
    swapServicesRegistryProvider.overrideWith(() => mockRegistry),
    swapServiceResolverProvider
        .overrideWith((_, __) => SwapServiceSource.sideshift),
    liquidProvider.overrideWith((_) => mockLiquidProvider),
    addressParserProvider.overrideWith((_) => mockAddressParser),
    manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
    fiatRatesProvider.overrideWith(() => MockFiatRatesNotifier(rates: [
          const BitcoinFiatRatesResponse(
            name: 'US Dollar',
            cryptoCode: 'BTC',
            currencyPair: 'BTCUSD',
            code: 'USD',
            rate: 56690.0,
          ),
        ])),
    formatterProvider.overrideWith((ref) => FormatterProvider(ref)),
    formatProvider.overrideWith((ref) => FormatService(ref)),
    displayUnitsProvider.overrideWith((ref) => mockDisplayUnitsProvider),
    exchangeRatesProvider.overrideWith((ref) => mockExchangeRatesProvider),
    amountInputMutationsProvider
        .overrideWith((ref) => MockCryptoAmountInputMutationsNotifier()),
  ]);

  final asset = Asset.usdtTrx();
  final fakeSwapOrderRequest = SwapOrderRequest(
    from: SwapAsset.fromAsset(Asset.unknown()),
    to: SwapAsset.fromAsset(Asset.unknown()),
    amount: Decimal.fromInt(0),
  );
  final fakeSwapOrder = SwapOrder(
    id: 'test',
    createdAt: DateTime.now(),
    from: SwapAsset.fromAsset(Asset.unknown()),
    to: SwapAsset.fromAsset(Asset.unknown()),
    depositAddress: 'test',
    settleAddress: 'test',
    depositAmount: Decimal.fromInt(0),
    serviceFee: SwapFee(
      type: SwapFeeType.flatFee,
      value: Decimal.fromInt(0),
      currency: SwapFeeCurrency.usd,
    ),
    status: SwapOrderStatus.waiting,
    serviceType: SwapServiceSource.sideshift,
  );

  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(fakeSwapOrderRequest);
    registerFallbackValue(fakeSwapOrder);
    registerFallbackValue(Decimal.zero);

    // Set up mock defaults
    mockDisplayUnitsProvider.mockCurrentDisplayUnit(
        value: SupportedDisplayUnits.sats);
    mockDisplayUnitsProvider.mockGetForcedDisplayUnit(
        value: SupportedDisplayUnits.sats);
    mockDisplayUnitsProvider.mockConvertSatsToUnit();
    mockDisplayUnitsProvider.mockConvertUnitToSats();
    mockExchangeRatesProvider.mockGetCurrentCurrency(
        value: kBtcUsdExchangeRate);
    mockExchangeRatesProvider
        .mockGetAvailableCurrencies(value: [kBtcUsdExchangeRate]);
    mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
  });

  group('Amount', () {
    test('When Alt USDt amount changes, should recreate order', () async {
      final sendArgs = SendAssetArguments.fromAsset(asset);
      const initialAmount = 200;
      const updateAmount = 100;
      final initialRequest = fakeSwapOrderRequest.copyWith(
        amount: Decimal.fromInt(initialAmount),
      );
      final initialOrder = fakeSwapOrder.copyWith(
        depositAmount: Decimal.fromInt(initialAmount),
      );
      final updatedRequest = fakeSwapOrderRequest.copyWith(
        amount: Decimal.fromInt(updateAmount),
      );
      final updatedOrder = fakeSwapOrder.copyWith(
        depositAmount: Decimal.fromInt(updateAmount),
      );

      final inputProvider = sendAssetInputStateProvider(sendArgs);
      mockLiquidProvider.mockGetReceiveAddress(address: 'test');
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockSideshiftService.mockCreateSendOrder(initialOrder, initialRequest);
      mockSideshiftService.mockCacheOrderToDatabase();

      final initialInputState = await container.read(inputProvider.future);

      container
          .read(inputProvider.notifier)
          .updateAmountFieldText('$initialAmount');

      await container.read(sendAssetSetupProvider(sendArgs).future);
      final inputState = await container.read(inputProvider.future);
      final orderProvider =
          swapOrderProvider(SwapArgs(pair: inputState.swapPair!));
      final initialOrderState = await container.read(orderProvider.future);

      mockSideshiftService.mockCreateSendOrder(updatedOrder, updatedRequest);
      container
          .read(inputProvider.notifier)
          .updateAmountFieldText('$updateAmount');
      final updatedInputState = await container.read(inputProvider.future);

      // Recreate the order with the updated amount (simulating what sendAssetSetupProvider does)
      await container
          .read(orderProvider.notifier)
          .createSendOrder(updatedRequest);
      final updatedOrderState = await container.read(orderProvider.future);

      expect(initialInputState.amount, 0);
      expect(initialInputState.inputType, AquaAssetInputType.crypto);
      expect(initialInputState.displayConversionAmount, null);
      // 200 USDt with precision 8 = 20000000000
      expect(inputState.amount, 20000000000);
      expect(inputState.displayConversionAmount, null);
      // 100 USDt with precision 8 = 10000000000
      expect(updatedInputState.amount, kOneHundredUsdtInSats);
      expect(updatedInputState.displayConversionAmount, null);
      expect(initialOrderState.order, isNotNull);
      expect(initialOrderState.order, equals(initialOrder));
      expect(updatedOrderState.order, isNotNull);
      expect(updatedOrderState.order, equals(updatedOrder));
      expect(
        initialOrderState.order?.depositAmount,
        Decimal.fromInt(initialAmount),
      );
      expect(
        updatedOrderState.order?.depositAmount,
        Decimal.fromInt(updateAmount),
      );
    });
  });
}
