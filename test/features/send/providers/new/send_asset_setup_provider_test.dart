import 'package:aqua/data/data.dart';
import 'package:aqua/data/models/network_amount.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:boltz/boltz.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_components/ui_components.dart';

import '../../../../mocks/mocks.dart';
import 'send_test_helpers.dart';

class MockLNUrlService extends Mock implements LNUrlService {}

class MockBoltzSubmarineSwapNotifier extends StateNotifier<LbtcLnSwap?>
    with Mock
    implements BoltzSubmarineSwapNotifier {
  MockBoltzSubmarineSwapNotifier() : super(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lightningAsset = Asset.lightning();
  final lbtcAsset = Asset.lbtc();
  const kFakeInvoice = 'lnbc1000n1fake_resolved_invoice';
  const kFakeLiquidAddress = 'fake-liquid-address';
  const kLnurlAmount = 1000;
  final lnurlPayParams = LNURLPayParams(
    callback: 'https://example.com/lnurlp/callback',
    minSendable: kLnurlAmount * 1000,
    maxSendable: kLnurlAmount * 1000,
  );
  final lnurlParseResult = LNURLParseResult(payParams: lnurlPayParams);

  final mockAddressParser = MockAddressParserProvider();
  final mockBalanceProvider = MockBalanceProvider();
  final mockDisplayUnitsProvider = MockDisplayUnitsProvider();
  final mockExchangeRatesProvider = ReferenceExchangeRateProviderMock();

  late MockLNUrlService mockLnurl;
  late MockBoltzSubmarineSwapNotifier mockBoltzNotifier;

  final args = SendAssetArguments(
    asset: lightningAsset,
    network: 'Lightning',
    lnurlParseResult: lnurlParseResult,
    networkAmount: NetworkAmount(
      amount: Decimal.fromInt(kLnurlAmount),
      asset: lightningAsset,
    ),
  );

  setUpAll(() {
    registerFallbackValue(lightningAsset);
    registerFallbackValue(lnurlPayParams);
    registerFallbackValue(Decimal.zero);

    mockDisplayUnitsProvider.mockCurrentDisplayUnit(
        value: SupportedDisplayUnits.btc);
    mockDisplayUnitsProvider.mockGetForcedDisplayUnit(
        value: SupportedDisplayUnits.btc);
    mockDisplayUnitsProvider.mockConvertSatsToUnit();
    mockDisplayUnitsProvider.mockConvertUnitToSats();
    mockExchangeRatesProvider.mockGetCurrentCurrency(
        value: kBtcUsdExchangeRate);
    mockExchangeRatesProvider
        .mockGetAvailableCurrencies(value: [kBtcUsdExchangeRate]);
  });

  setUp(() {
    mockLnurl = MockLNUrlService();
    mockBoltzNotifier = MockBoltzSubmarineSwapNotifier();
  });

  ProviderContainer createContainer({
    required MockAddressParserProvider addressParser,
    MockManageAssetsProvider? manageAssets,
  }) {
    return ProviderContainer(overrides: [
      ...getStandardOverrides(
        addressParser: addressParser,
        balance: mockBalanceProvider,
        manageAssets: manageAssets,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ),
      satsToFiatDisplayWithSymbolProvider.overrideWith(
        (_, __) => Future.value('\$0.00'),
      ),
      lnurlProvider.overrideWith((_) => mockLnurl),
      boltzSubmarineSwapProvider.overrideWith((_) => mockBoltzNotifier),
    ]);
  }

  group('_initLightning LNURL flow', () {
    test('should reset amount after resolving LNURL invoice', () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100000000);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: lightningAsset,
          address: kFakeInvoice,
        ),
      );

      when(() => mockLnurl.callLnurlPay(
            payParams: any(named: 'payParams'),
            amountSatoshis: any(named: 'amountSatoshis'),
          )).thenAnswer((_) async => kFakeInvoice);

      when(() => mockBoltzNotifier.prepareSubmarineSwap(
            address: any(named: 'address'),
          )).thenAnswer((_) async => true);

      final container = createContainer(addressParser: mockAddressParser);
      addTearDown(container.dispose);

      await container.read(sendAssetInputStateProvider(args).future);

      container
          .read(sendAssetInputStateProvider(args).notifier)
          .setType(AquaAssetInputType.fiat);

      final inputBefore =
          container.read(sendAssetInputStateProvider(args)).valueOrNull!;
      expect(inputBefore.amount, isNot(0));
      expect(inputBefore.isLnurl, true);
      expect(inputBefore.inputType, AquaAssetInputType.fiat);

      await container.read(sendAssetSetupProvider(args).future);

      final inputAfter =
          container.read(sendAssetInputStateProvider(args)).valueOrNull;
      expect(inputAfter, isNotNull);
      expect(inputAfter!.amount, 0);
      expect(inputAfter.isSendAllFunds, false);
      expect(inputAfter.inputType, AquaAssetInputType.crypto);
    });

    test('should call prepareSubmarineSwap exactly once for regular invoice',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100000000);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: lightningAsset,
          address: kFakeInvoice,
        ),
      );

      when(() => mockLnurl.callLnurlPay(
            payParams: any(named: 'payParams'),
            amountSatoshis: any(named: 'amountSatoshis'),
          )).thenAnswer((_) async => kFakeInvoice);

      when(() => mockBoltzNotifier.prepareSubmarineSwap(
            address: any(named: 'address'),
          )).thenAnswer((_) async => true);

      final container = createContainer(addressParser: mockAddressParser);
      addTearDown(container.dispose);

      await container.read(sendAssetInputStateProvider(args).future);

      final result = await container.read(sendAssetSetupProvider(args).future);

      expect(result, true);
      verify(() => mockBoltzNotifier.prepareSubmarineSwap(
            address: kFakeInvoice,
          )).called(1);
    });
  });

  group('_initLightning boltz-to-boltz flow', () {
    late MockManageAssetsProvider mockManageAssets;

    setUp(() {
      mockManageAssets = MockManageAssetsProvider();
      mockManageAssets.mockIsNonLbtcLiquidToLbtcCall(value: false);
    });

    test('should return true and skip prepareSubmarineSwap for boltz-to-boltz',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100000000);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: lbtcAsset,
          address: kFakeLiquidAddress,
          isBoltzToBoltzSwap: true,
        ),
      );

      when(() => mockLnurl.callLnurlPay(
            payParams: any(named: 'payParams'),
            amountSatoshis: any(named: 'amountSatoshis'),
          )).thenAnswer((_) async => kFakeInvoice);

      final container = createContainer(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssets,
      );
      addTearDown(container.dispose);

      await container.read(sendAssetInputStateProvider(args).future);

      final result = await container.read(sendAssetSetupProvider(args).future);

      expect(result, true);
      verifyNever(() => mockBoltzNotifier.prepareSubmarineSwap(
            address: any(named: 'address'),
          ));
    });

    test('should switch asset from lightning to lbtc for boltz-to-boltz',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100000000);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: lbtcAsset,
          address: kFakeLiquidAddress,
          isBoltzToBoltzSwap: true,
        ),
      );

      when(() => mockLnurl.callLnurlPay(
            payParams: any(named: 'payParams'),
            amountSatoshis: any(named: 'amountSatoshis'),
          )).thenAnswer((_) async => kFakeInvoice);

      final container = createContainer(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssets,
      );
      addTearDown(container.dispose);

      await container.read(sendAssetInputStateProvider(args).future);

      final inputBefore =
          container.read(sendAssetInputStateProvider(args)).valueOrNull!;
      expect(inputBefore.asset.isLightning, true);

      await container.read(sendAssetSetupProvider(args).future);

      final inputAfter =
          container.read(sendAssetInputStateProvider(args)).valueOrNull!;
      expect(inputAfter.asset.isLBTC, true);
      expect(inputAfter.isBoltzToBoltzSwap, true);
      expect(inputAfter.addressFieldText, kFakeLiquidAddress);
    });
  });
}
