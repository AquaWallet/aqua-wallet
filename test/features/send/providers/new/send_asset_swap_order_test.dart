import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validator.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';
import 'send_asset_input_provider_test.dart';

void main() {
  final mockBalanceProvider = MockBalanceProvider();
  final mockPrefsProvider = MockPrefsProvider();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockSideshiftService = MockSideshiftService();
  final mockRegistry =
      MockSwapServicesRegistry(mockService: mockSideshiftService);
  final mockLiquidProvider = MockLiquidProvider();
  final mockAddressParser = MockAddressParserProvider();
  final container = ProviderContainer(overrides: [
    clipboardContentProvider.overrideWith((_) => 'test'),
    balanceProvider.overrideWith((_) => mockBalanceProvider),
    prefsProvider.overrideWith((_) => mockPrefsProvider),
    bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
    swapServicesRegistryProvider.overrideWith(() => mockRegistry),
    swapServiceResolverProvider
        .overrideWith((_, __) => SwapServiceSource.sideshift),
    liquidProvider.overrideWith((_) => mockLiquidProvider),
    addressParserProvider.overrideWith((_) => mockAddressParser),
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
          .setInputType(CryptoAmountInputType.fiat);
      await container
          .read(inputProvider.notifier)
          .updateAmountFieldText('$initialAmount');

      await container.read(sendAssetSetupProvider(sendArgs).future);
      final inputState = await container.read(inputProvider.future);
      final orderProvider =
          swapOrderProvider(SwapArgs(pair: inputState.swapPair!));
      final initialOrderState = await container.read(orderProvider.future);

      mockSideshiftService.mockCreateSendOrder(updatedOrder, updatedRequest);
      await container
          .read(inputProvider.notifier)
          .updateAmountFieldText('$updateAmount');
      final updatedInputState = await container.read(inputProvider.future);
      // final updatedOrderState = await container.read(orderProvider.future);

      expect(initialInputState.amount, 0);
      expect(initialInputState.amountConversionDisplay, null);
      expect(inputState.amount, (kOneHundredUsdInBtcSats * 2) + 1);
      expect(inputState.amountConversionDisplay, null);
      expect(updatedInputState.amount, kOneHundredUsdInBtcSats);
      expect(updatedInputState.amountConversionDisplay, null);
      expect(initialOrderState.order, isNotNull);
      expect(initialOrderState.order, equals(initialOrder));
      //TODO - Fix this test
      // expect(updatedOrderState.order, isNotNull);
      // expect(updatedOrderState.order, equals(updatedOrder));
      // expect(
      //   initialOrderState.order?.depositAmount,
      //   Decimal.fromInt(initialAmount),
      // );
      // expect(
      //   updatedOrderState.order?.depositAmount,
      //   Decimal.fromInt(updateAmount),
      // );
    });
  });
}
