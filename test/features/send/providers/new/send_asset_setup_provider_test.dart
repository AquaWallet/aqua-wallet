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
  const kFakeInvoice = 'lnbc1000n1fake_resolved_invoice';
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

  group('_initLightning LNURL flow', () {
    test('should reset amount after resolving LNURL invoice', () async {
      mockBalanceProvider.mockGetBalanceCall(value: 100000000);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: lightningAsset,
          address: kFakeInvoice,
          lnurlParseResult: lnurlParseResult,
        ),
      );

      when(() => mockLnurl.callLnurlPay(
            payParams: any(named: 'payParams'),
            amountSatoshis: any(named: 'amountSatoshis'),
          )).thenAnswer((_) async => kFakeInvoice);

      when(() => mockBoltzNotifier.prepareSubmarineSwap(
            address: any(named: 'address'),
          )).thenAnswer((_) async => true);

      final container = ProviderContainer(overrides: [
        ...getStandardOverrides(
          addressParser: mockAddressParser,
          balance: mockBalanceProvider,
          mockDisplayUnitsProvider: mockDisplayUnitsProvider,
          mockExchangeRatesProvider: mockExchangeRatesProvider,
        ),
        satsToFiatDisplayWithSymbolProvider.overrideWith(
          (_, __) => Future.value('\$0.00'),
        ),
        lnurlProvider.overrideWith((_) => mockLnurl),
        boltzSubmarineSwapProvider.overrideWith((_) => mockBoltzNotifier),
      ]);
      addTearDown(container.dispose);

      // Initialize input state — LNURL data gives it a non-zero amount
      await container.read(sendAssetInputStateProvider(args).future);

      // Switch to fiat input type before setup runs
      container
          .read(sendAssetInputStateProvider(args).notifier)
          .setType(AquaAssetInputType.fiat);

      final inputBefore =
          container.read(sendAssetInputStateProvider(args)).valueOrNull!;
      expect(inputBefore.amount, isNot(0));
      expect(inputBefore.isLnurl, true);
      expect(inputBefore.inputType, AquaAssetInputType.fiat);

      // Run setup provider which resolves LNURL → invoice
      await container.read(sendAssetSetupProvider(args).future);

      // The input state amount should be reset after the invoice replaced the LNURL
      final inputAfter =
          container.read(sendAssetInputStateProvider(args)).valueOrNull;
      expect(inputAfter, isNotNull);
      expect(inputAfter!.amount, 0);
      expect(inputAfter.isSendAllFunds, false);
      expect(inputAfter.inputType, AquaAssetInputType.crypto);
    });
  });
}
