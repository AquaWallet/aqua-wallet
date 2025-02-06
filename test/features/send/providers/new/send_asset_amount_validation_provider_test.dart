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
import 'send_asset_input_provider_test.dart';

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
  final mockPrefsProvider = MockPrefsProvider();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockSideshiftService = MockSideshiftService();
  final mockRegistry =
      MockSwapServicesRegistry(mockService: mockSideshiftService);
  final mockNotifier = MockSwapOrderCreationNotifier();

  final container = ProviderContainer(overrides: [
    clipboardContentProvider.overrideWith((_) => null),
    balanceProvider.overrideWith((_) => mockBalanceProvider),
    prefsProvider.overrideWith((_) => mockPrefsProvider),
    bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
    swapServicesRegistryProvider.overrideWith(() => mockRegistry),
    swapOrderProvider.overrideWith(() => mockNotifier),
  ]);

  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(args);
    registerFallbackValue(mockSwapPair);
    registerFallbackValue(mockSwapRate);
    registerFallbackValue(SwapOrderType.variable);
  });

  test('When amount is null, input is invalid', () async {
    mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
    mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
    mockBalanceProvider.mockGetBalanceCall(value: 100);
    final provider = sendAssetAmountValidationProvider(args);

    final state = await container.read(provider.future);

    expect(provider.argument, isA<SendAssetArguments>());
    expect((provider.argument as SendAssetArguments).userEnteredAmount, null);
    expect(state, false);
  });
  test('When amount is zero, input is invalid', () async {
    final provider = sendAssetAmountValidationProvider(
      args.copyWith(userEnteredAmount: Decimal.zero),
    );

    final state = await container.read(provider.future);

    expect(provider.argument, isA<SendAssetArguments>());
    expect((provider.argument as SendAssetArguments).userEnteredAmount,
        Decimal.zero);
    expect(state, false);
  });
  test('When balance is zero, input is invalid', () async {
    mockBalanceProvider.mockGetBalanceCall(value: 0);
    final provider = sendAssetAmountValidationProvider(args);

    final state = await container.read(provider.future);

    expect(state, false);
  });
  test('When amount exceeds balance, throw insufficient funds error', () async {
    mockBalanceProvider.mockGetBalanceCall(value: 100);
    final provider = sendAssetAmountValidationProvider(args.copyWith(
      userEnteredAmount: Decimal.fromInt(200),
    ));

    expect(
      () async => await container.read(provider.future),
      throwsA(isA<AmountParsingException>().having(
        (AmountParsingException e) => e.type,
        'type',
        AmountParsingExceptionType.notEnoughFunds,
      )),
    );
  });
  test('When amount below min GDK limit, throw limit error', () async {
    final provider = sendAssetAmountValidationProvider(args.copyWith(
      userEnteredAmount: Decimal.tryParse('0.00000001'),
    ));

    expect(
      () async => await container.read(provider.future),
      throwsA(isA<AmountParsingException>().having(
        (AmountParsingException e) => e.type,
        'type',
        AmountParsingExceptionType.belowMin,
      )),
    );
  });
}
