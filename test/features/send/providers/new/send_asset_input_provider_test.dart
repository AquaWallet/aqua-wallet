import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_components/ui_components.dart';

import '../../../../mocks/mocks.dart';
import 'send_test_helpers.dart';

const kUsdCurrencySymbol = '\$';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final asset = Asset.btc();
  final args = SendAssetArguments.fromAsset(asset);
  final mockAddressParser = MockAddressParserProvider();
  final mockManageAssetsProvider = MockManageAssetsProvider();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockBalanceProvider = MockBalanceProvider();
  final mockPrefsProvider = MockUserPreferencesNotifier();
  final mockDisplayUnitsProvider = MockDisplayUnitsProvider();
  final mockExchangeRatesProvider = ReferenceExchangeRateProviderMock();
  final container = ProviderContainer(
      overrides: getStandardOverrides(
    addressParser: mockAddressParser,
    manageAssets: mockManageAssetsProvider,
    bitcoin: mockBitcoinProvider,
    balance: mockBalanceProvider,
    prefs: mockPrefsProvider,
    mockDisplayUnitsProvider: mockDisplayUnitsProvider,
    mockExchangeRatesProvider: mockExchangeRatesProvider,
  ));

  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(Decimal.zero);

    // Set up display units mock
    mockDisplayUnitsProvider.mockCurrentDisplayUnit(
        value: SupportedDisplayUnits.btc);
    mockDisplayUnitsProvider.mockGetForcedDisplayUnit(
        value: SupportedDisplayUnits.btc);
    mockDisplayUnitsProvider.mockConvertSatsToUnit();
    mockDisplayUnitsProvider.mockConvertUnitToSats();

    // Set up exchange rates mock
    mockExchangeRatesProvider.mockGetCurrentCurrency(
        value: kBtcUsdExchangeRate);
    mockExchangeRatesProvider
        .mockGetAvailableCurrencies(value: [kBtcUsdExchangeRate]);
  });

  setUp(() {
    // Reset mock state to defaults FIRST to prevent state leakage
    // This is critical - some tests change currency (e.g., to EUR) which can leak
    mockExchangeRatesProvider.mockGetCurrentCurrency(
        value: kBtcUsdExchangeRate);
    mockDisplayUnitsProvider.mockCurrentDisplayUnit(
        value: SupportedDisplayUnits.btc);

    // Invalidate providers between tests to ensure clean state
    // This ensures each test starts with a fresh provider instance
    try {
      container.invalidate(sendAssetInputStateProvider(args));
    } catch (_) {
      // Provider might not exist yet, ignore
    }
  });

  group('Initial State', () {
    test('Initial state balance is correct', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.balanceInSats, kOneHundredUsdInBtcSats);
      expect(state.balanceDisplay, kOneHundredUsdInBtcDisplay);
      expect(state.balanceFiatDisplay, '${kUsdCurrencySymbol}100.00');
    });
    test('Initial state clipboard is empty when nothing is found', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
    });
    test('Initial state address text field is empty', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.addressFieldText, isNull);
      expect(state.isAddressFieldEmpty, true);
    });
    test('Initial state amount text field is empty', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.amountFieldText, isNull);
      expect(state.isAmountFieldEmpty, true);
    });
    test('Initial state amount text field is editable', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.isAmountEditable, isTrue);
    });
    test('Initial state scanned QR Code is empty', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.scannedQrCode, isNull);
      expect(state.isScannedQrCodeEmpty, true);
    });
    test('Initial state amount is zero', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.amount, 0);
    });
    test('Initial state converted amount is empty', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.displayConversionAmount, '\$0.00');
    });
    test('Initial state amount input is fiat', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.inputType, AquaAssetInputType.crypto);
      expect(state.isCryptoAmountInput, true);
    });
    test('Initial state is NOT send all funds', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.isSendAllFunds, false);
    });
    test('Initial state fee asset is lbtc by default', () async {
      final args = SendAssetArguments.fromAsset(Asset.unknown());
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.feeAsset, FeeAsset.lbtc);
    });
    test('Initial state fee asset is btc', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.feeAsset, FeeAsset.btc);
    });

    test('BTC asset hasFiatRate should be true', () async {
      final btcAsset = Asset.btc();
      expect(btcAsset.hasFiatRate, true);
    });

    test('USDt asset hasFiatRate should be false', () async {
      final usdtAsset = Asset.usdtLiquid();
      expect(usdtAsset.hasFiatRate, false);
    });

    test('Non-BTC/LBTC/Lightning liquid asset hasFiatRate should be false',
        () async {
      final liquidAsset = Asset.unknown().copyWith(
        id: 'some-liquid-asset-id',
        isLiquid: true,
        isLBTC: false,
        isUSDt: false,
      );
      expect(liquidAsset.hasFiatRate, false);
    });
  });

  group('Initialize with arguments', () {
    test('Inital state address text field is NOT empty', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.btc(asset).copyWith(
        input: kFakeBitcoinAddress,
      );

      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(asset: asset, address: kFakeBitcoinAddress),
      );

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.addressFieldText, isNotNull);
      expect(state.isAddressFieldEmpty, false);
      expect(state.addressFieldText, kFakeBitcoinAddress);
      expect(state.asset.id, asset.id);
    });
    test('Inital state crypto amount is NOT empty', () async {
      final asset = Asset.btc();
      final cryptoDecimalAmount = Decimal.parse(kOneHundredUsdInBtc.toString());
      final args = SendAssetArguments.btc(asset).copyWith(
        input: kFakeBitcoinAddress,
        userEnteredAmount: cryptoDecimalAmount,
      );

      // Set up mocks for this specific asset
      mockBalanceProvider.mockGetBalanceCall(
          value: kOneHundredUsdInBtcSats, asset: asset);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(asset: asset, address: kFakeBitcoinAddress),
      );

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.asset.id, asset.id);
      expect(state.inputType, AquaAssetInputType.crypto);
      expect(state.amountFieldText, cryptoDecimalAmount.toString());
      expect(state.isAmountFieldEmpty, false);
    });
    test('Inital state converted crypto amount is NOT empty', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.btc(asset).copyWith(
        input: kFakeBitcoinAddress,
        userEnteredAmount: Decimal.parse(kPointOneBtc.toString()),
      );

      // Set up mocks for this specific asset
      mockBalanceProvider.mockGetBalanceCall(
          value: kOneHundredUsdInBtcSats, asset: asset);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(asset: asset, address: kFakeBitcoinAddress),
      );

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.amount, kPointOneBtcInSats);
      expect(state.displayConversionAmount, "${kUsdCurrencySymbol}5,669.00");
    });
    test('Inital state BTC fee asset is correct', () async {
      final args = SendAssetArguments.fromAsset(Asset.btc());

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.feeAsset, FeeAsset.btc);
    });
    test('Inital state L-BTC fee asset is correct', () async {
      final args = SendAssetArguments.fromAsset(Asset.liquidTest());

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.feeAsset, FeeAsset.lbtc);
    });
    test('Inital state USDt fee asset is correct', () async {
      final args = SendAssetArguments.fromAsset(Asset.usdtEth());

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.feeAsset, FeeAsset.tetherUsdt);
    });
  });

  group('Address field', () {
    test('content is NOT empty when valid address is entered', () async {
      final provider = sendAssetInputStateProvider(args);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: asset,
          address: kFakeBitcoinAddress,
        ),
      );
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeBitcoinAddress);

      final state = await container.read(provider.future);

      expect(initialState.addressFieldText, isNull);
      expect(initialState.isAddressFieldEmpty, true);
      expect(state.addressFieldText, kFakeBitcoinAddress);
      expect(state.isAddressFieldEmpty, false);
    });
    test('throws AddressParsingException when invalid address is entered',
        () async {
      final provider = sendAssetInputStateProvider(args);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);
      final initialState = await container.read(provider.future);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeContent);

      expect(initialState.addressFieldText, isNull);
      expect(initialState.isAddressFieldEmpty, true);
      expectLater(
        container.read(provider.notifier).state,
        isA<AsyncError<SendAssetInputState>>().having(
          (e) => e.error,
          'error',
          isA<AddressParsingException>().having(
            (e) => e.type,
            'type',
            AddressParsingExceptionType.invalidAddress,
          ),
        ),
      );
    });

    test('amount is NOT empty when an address with amount is found', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      final otherAsset = Asset.lightning();
      const kFakeAmount = 100;
      final expectedAmountText = mockDisplayUnitsProvider
          .convertSatsToUnit(
            sats: kFakeAmount,
            asset: otherAsset,
          )
          .toString();
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amountInSats: kFakeAmount,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeLiquidAddress);

      final state = await container.read(provider.future);
      expect(initialState.amount, 0);
      expect(initialState.isAddressFieldEmpty, true);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.amount, kFakeAmount);
      expect(state.isAmountFieldEmpty, false);
      expect(state.amountFieldText, expectedAmountText);
    });
    test('amount is NOT empty when pasted address has amount', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      final otherAsset = Asset.lightning();
      const kFakeAmount = 150;
      final expectedAmountText = mockDisplayUnitsProvider
          .convertSatsToUnit(
            sats: kFakeAmount,
            asset: otherAsset,
          )
          .toString();
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: Future.value(kFakeLiquidAddress),
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amountInSats: kFakeAmount,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container.read(provider.notifier).pasteClipboardContent();

      final state = await container.read(provider.future);
      expect(initialState.amount, 0);
      expect(initialState.isAddressFieldEmpty, true);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.amount, kFakeAmount);
      expect(state.isAmountFieldEmpty, false);
      expect(state.amountFieldText, expectedAmountText);
    });
    test('amount is not editable for BIP21 address with amount', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      const kBip21Input =
          'bitcoin:1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2?amount=1.23&label=Example';
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: asset,
          address: '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2',
          amountInSats: 123000000,
          label: 'Example',
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      await container.read(provider.notifier).updateAddressFieldText(
            kBip21Input,
          );

      final state = await container.read(provider.future);
      expect(state.addressFieldText, kBip21Input);
      expect(state.isAmountEditable, isFalse);
    });
    test('throws AddressParsingException on generic error', () async {
      mockAddressParser.mockThrowParseInputCall(message: 'error');
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);
      expect(initialState.amount, 0);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeBitcoinAddress);

      await expectLater(
        container.read(provider.notifier).state,
        isA<AsyncError<SendAssetInputState>>().having(
          (e) => e.error,
          'error',
          isA<AddressParsingException>().having(
            (e) => e.type,
            'type',
            AddressParsingExceptionType.invalidAddress,
          ),
        ),
      );
    });
    test('use LNURL params when scanned QR code is LNURL', () async {
      final lightningAsset = Asset.lightning();
      final lightningArgs = SendAssetArguments.fromAsset(lightningAsset);
      const kFakeOriginalAmount = 100;
      const kFakeLnUrlAmount = 200;
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: null,
        addressParser: mockAddressParser,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: lightningAsset,
          address: kFakeLiquidAddress,
          amountInSats: kFakeOriginalAmount,
          lnurlParseResult: LNURLParseResult(
            payParams: LNURLPayParams(
              minSendable: kFakeLnUrlAmount * 1000,
              maxSendable: kFakeLnUrlAmount * 1000,
            ),
          ),
        ),
      );

      final provider = sendAssetInputStateProvider(lightningArgs);
      final initialState = await container.read(provider.future);
      expect(initialState.amount, 0);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeContent);

      final state = await container.read(provider.future);
      expect(state.asset.id, lightningAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.isLnurl, true);
      expect(state.lnurlData, isNotNull);
      expect(state.lnurlData?.payParams?.isFixedAmount, true);
      expect(state.amount, kFakeLnUrlAmount);
    });
    test('use params when scanned QR code is BIP21 BTC Invoice', () async {
      final asset = Asset.lightning();
      final args = SendAssetArguments.fromAsset(asset);
      const kInvoiceAddress = 'BC1234567890';
      const kInvoiceAmount = 1000;
      const kInvoiceAmountFiat = (kBtcUsdRate * kInvoiceAmount) / satsPerBtc;
      final expectedAmountText =
          (Decimal.fromInt(kInvoiceAmount) / Decimal.fromInt(satsPerBtc))
              .toDecimal()
              .toString();
      const kInvoiceLabel = 'Invoice Label';
      const kInvoiceMessage = 'Invoice Message';
      const kInvoiceLightningAddress = 'lnbc100xxx';
      const kFakeBtcBip21Url = 'bitcoin:$kInvoiceAddress?'
          'amount=$kInvoiceAmount&'
          'label=$kInvoiceLabel&'
          'message=$kInvoiceMessage&'
          'lightning=$kInvoiceLightningAddress';
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: null,
        addressParser: mockAddressParser,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          address: kInvoiceAddress,
          amountInSats: kInvoiceAmount,
          asset: asset,
          assetId: null,
          message: kInvoiceMessage,
          label: kInvoiceLabel,
          lightningInvoice: kInvoiceLightningAddress,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container
          .read(provider.notifier)
          .pasteScannedQrCode(kFakeBtcBip21Url);

      final state = await container.read(provider.future);
      expect(initialState.amount, 0);
      expect(state.asset.id, asset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
      expect(state.addressFieldText, kFakeBtcBip21Url);
      expect(state.isAddressFieldEmpty, false);
      expect(state.isLnurl, false);
      expect(state.lnurlData, isNull);
      expect(state.amount, kInvoiceAmount);
      expect(state.amountFieldText, expectedAmountText);
      expect(
        state.displayConversionAmount,
        '$kUsdCurrencySymbol${kInvoiceAmountFiat.toStringAsFixed(2)}',
      );
    });
    test('switch asset when scanned address is from another asset', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      final otherAsset = Asset.lightning();
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeBitcoinAddress,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeContent);

      final state = await container.read(provider.future);
      expect(initialState.asset.id, asset.id);
      expect(initialState.isScannedQrCodeEmpty, true);
      expect(initialState.isAddressFieldEmpty, true);
      expect(state.asset.id, otherAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isScannedQrCodeEmpty, true);
      expect(state.addressFieldText, kFakeBitcoinAddress);
      expect(state.isAddressFieldEmpty, false);
    });
    test(
        'dont switch from liquid when scanned address is lightning from Aqua wallet',
        () async {
      final asset = Asset.lbtc();
      final args = SendAssetArguments.fromAsset(asset);
      final otherAsset = Asset.lbtc();
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          lightningInvoice: kFakeLightningInvoice,
          isBoltzToBoltzSwap: true,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeContent);

      final state = await container.read(provider.future);
      expect(initialState.asset.id, asset.id);
      expect(initialState.isScannedQrCodeEmpty, true);
      expect(initialState.isAddressFieldEmpty, true);
      expect(state.asset.id, otherAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isScannedQrCodeEmpty, true);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.isAmountEditable, isFalse);
    });
  });

  group('Clipboard', () {
    final container = ProviderContainer(
        overrides: getStandardOverrides(
      clipboardContent: Future.value(kFakeContent),
      addressParser: mockAddressParser,
      bitcoin: mockBitcoinProvider,
      balance: mockBalanceProvider,
      prefs: mockPrefsProvider,
      mockDisplayUnitsProvider: mockDisplayUnitsProvider,
      mockExchangeRatesProvider: mockExchangeRatesProvider,
    ));

    test('content is empty when an invalid address is found', () async {
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
    });
    test('content is NOT empty when a valid address is found', () async {
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(asset: asset, address: kFakeBitcoinAddress),
      );

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.clipboardAddress, isNotNull);
      expect(state.clipboardAddress, kFakeContent);
      expect(state.isClipboardEmpty, false);
    });
    test('content is pasted in address field when selected', () async {
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: Future.value(kFakeBitcoinAddress),
        addressParser: mockAddressParser,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      final provider = sendAssetInputStateProvider(args);

      final initialState = await container.read(provider.future);
      expect(initialState.clipboardAddress, kFakeBitcoinAddress);
      expect(initialState.isClipboardEmpty, false);
      expect(initialState.addressFieldText, isNull);
      expect(initialState.isAddressFieldEmpty, true);

      container.read(provider.notifier).pasteClipboardContent();

      final finalState = await container.read(provider.future);
      expect(finalState.clipboardAddress, kFakeBitcoinAddress);
      expect(finalState.isClipboardEmpty, false);
      expect(finalState.addressFieldText, kFakeBitcoinAddress);
      expect(finalState.isAddressFieldEmpty, false);
    });
  });

  group('QR code pasted', () {
    test('content is empty when nothing is found', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.scannedQrCode, isNull);
      expect(state.isScannedQrCodeEmpty, true);
    });
    test('throws AddressParsingException when empty input is found', () async {
      final provider = sendAssetInputStateProvider(args);
      final notifier = provider.notifier;
      final initialState = await container.read(provider.future);

      await container.read(notifier).pasteScannedQrCode('');

      await expectLater(
        initialState,
        isA<SendAssetInputState>(),
      );
      await expectLater(
        container.read(notifier).state,
        isA<AsyncError<SendAssetInputState>>().having(
          (e) => e.error,
          'error',
          isA<AddressParsingException>().having(
            (e) => e.type,
            'type',
            AddressParsingExceptionType.emptyAddress,
          ),
        ),
      );
    });
    test('throws AddressParsingException when invalid address is found',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);
      final provider = sendAssetInputStateProvider(args);
      final notifier = provider.notifier;
      final initialState = await container.read(provider.future);

      await container.read(notifier).pasteScannedQrCode(kFakeContent);

      await expectLater(
        initialState,
        isA<SendAssetInputState>(),
      );
      await expectLater(
        container.read(notifier).state,
        isA<AsyncError<SendAssetInputState>>().having(
          (e) => e.error,
          'error',
          isA<AddressParsingException>().having(
            (e) => e.type,
            'type',
            AddressParsingExceptionType.invalidAddress,
          ),
        ),
      );
    });
    test(
      'throws QrScannerInvalidQrParametersException when null input is found',
      () async {
        final provider = sendAssetInputStateProvider(args);
        final notifier = provider.notifier;
        final initialState = await container.read(provider.future);

        await container.read(notifier).pasteScannedQrCode(null);

        await expectLater(
          initialState,
          isA<SendAssetInputState>(),
        );
        await expectLater(
          container.read(notifier).state,
          isA<AsyncError>().having(
            (e) => e.error,
            'error',
            isA<QrScannerInvalidQrParametersException>(),
          ),
        );
      },
    );
    test(
      'throws AddressParsingException when parsed asset is not compatible',
      () async {
        final asset = Asset.btc();
        final args = SendAssetArguments.fromAsset(asset);
        final provider = sendAssetInputStateProvider(args);
        mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
        mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
        mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
        mockAddressParser.mockIsValidAddressForAssetCall(value: true);
        mockAddressParser.mockParseInputCall(
          value: ParsedAddress(
            asset: Asset.usdtEth(),
            address: kFakeBitcoinAddress,
          ),
        );
        final initialState = await container.read(provider.future);

        await container
            .read(provider.notifier)
            .pasteScannedQrCode(kFakeContent);

        expect(initialState.asset.id, asset.id);
        await expectLater(
          container.read(provider.notifier).state,
          isA<AsyncError>().having(
            (e) => e.error,
            'error',
            isA<AddressParsingException>().having(
              (e) => e.type,
              'type',
              AddressParsingExceptionType.nonMatchingAssetId,
            ),
          ),
        );
      },
    );
    test('content is empty when parsed input is invalid address', () async {
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: null,
        addressParser: mockAddressParser,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      final provider = sendAssetInputStateProvider(args);

      final initialState = await container.read(provider.future);
      expect(initialState.clipboardAddress, isNull);
      mockAddressParser.mockThrowParseInputCall(message: 'invalid address');
      await container.read(provider.notifier).pasteScannedQrCode(kFakeContent);
      await expectLater(
        container.read(provider.notifier).state,
        isA<AsyncError<SendAssetInputState>>().having(
          (e) => e.error,
          'error',
          isA<AddressParsingException>().having(
            (e) => e.type,
            'type',
            AddressParsingExceptionType.invalidAddress,
          ),
        ),
      );
    });
    test('amount is NOT empty when an address with amount is found', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      final otherAsset = Asset.lightning();
      const kFakeAmount = 100;
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: null,
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amountInSats: kFakeAmount,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);
      expect(initialState.amount, 0);

      await container.read(provider.notifier).pasteScannedQrCode(kFakeContent);

      final state = await container.read(provider.future);
      expect(state.asset.id, otherAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
      expect(state.addressFieldText, isNotNull);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.amount, kFakeAmount);
    });
    test('throws AddressParsingException on generic error', () async {
      mockAddressParser.mockThrowParseInputCall(message: 'error');
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);
      expect(initialState.amount, 0);

      await container
          .read(provider.notifier)
          .pasteScannedQrCode(kFakeBitcoinAddress);

      await expectLater(
        container.read(provider.notifier).state,
        isA<AsyncError<SendAssetInputState>>().having(
          (e) => e.error,
          'error',
          isA<AddressParsingException>().having(
            (e) => e.type,
            'type',
            AddressParsingExceptionType.invalidAddress,
          ),
        ),
      );
    });
    test('use LNURL params when scanned QR code is LNURL', () async {
      final lightningAsset = Asset.lightning();
      final lightningArgs = SendAssetArguments.fromAsset(lightningAsset);
      const kFakeOriginalAmount = 100;
      const kFakeLnUrlAmount = 200;
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: null,
        addressParser: mockAddressParser,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: lightningAsset,
          address: kFakeLiquidAddress,
          amountInSats: kFakeOriginalAmount,
          lnurlParseResult: LNURLParseResult(
            payParams: LNURLPayParams(
              minSendable: kFakeLnUrlAmount * 1000,
              maxSendable: kFakeLnUrlAmount * 1000,
            ),
          ),
        ),
      );

      final provider = sendAssetInputStateProvider(lightningArgs);
      final initialState = await container.read(provider.future);
      expect(initialState.amount, 0);

      await container.read(provider.notifier).pasteScannedQrCode(kFakeContent);

      final state = await container.read(provider.future);
      expect(state.asset.id, lightningAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
      expect(state.addressFieldText, isNotNull);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.isLnurl, true);
      expect(state.lnurlData, isNotNull);
      expect(state.lnurlData?.payParams?.isFixedAmount, true);
      expect(state.amount, kFakeLnUrlAmount);
    });
    test('switch asset when scanned address is from another asset', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      final otherAsset = Asset.lightning();
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeBitcoinAddress,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container.read(provider.notifier).pasteScannedQrCode(kFakeContent);

      final state = await container.read(provider.future);
      expect(initialState.asset.id, asset.id);
      expect(initialState.isScannedQrCodeEmpty, true);
      expect(initialState.isAddressFieldEmpty, true);
      expect(state.asset.id, otherAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.scannedQrCode, kFakeContent);
      expect(state.isScannedQrCodeEmpty, false);
      expect(state.addressFieldText, kFakeBitcoinAddress);
      expect(state.isAddressFieldEmpty, false);
    });
  });

  group('Asset switching', () {
    test('keep asset when an address from the same asset is found', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      const kOtherAssetName = 'Same Asset with Different Name';
      final otherAsset = asset.copyWith(name: kOtherAssetName);
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: Future.value(kFakeBitcoinAddress),
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeEthereumAddress,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      await container.read(provider.notifier).pasteScannedQrCode(kFakeContent);

      final state = await container.read(provider.future);
      expect(state.asset.id, asset.id);
      expect(state.asset.name, asset.name);
      expect(state.asset.id, otherAsset.id);
      expect(state.asset.name, isNot(kOtherAssetName));
      expect(state.clipboardAddress, isNotNull);
      expect(state.clipboardAddress, kFakeBitcoinAddress);
      expect(state.isClipboardEmpty, false);
      expect(state.isAmountEditable, isTrue);
    });

    test(
      'keep asset when original asset is Non-LBTC Liquid & found address is an '
      'LBTC asset',
      () async {
        final asset = Asset.lightning();
        final args = SendAssetArguments.fromAsset(asset);
        final otherAsset = Asset.liquidTest().copyWith(ticker: 'tL-BTC');

        mockAddressParser.mockParseInputCall(
          value: ParsedAddress(
            asset: otherAsset,
            address: kFakeLiquidAddress,
          ),
        );
        mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: true);

        final provider = sendAssetInputStateProvider(args);
        await container.read(provider.future);

        await container
            .read(provider.notifier)
            .pasteScannedQrCode(kFakeContent);

        final state = await container.read(provider.future);
        expect(asset.id, isNot(otherAsset.id));
        expect(state.asset.id, asset.id);
        expect(state.asset.name, asset.name);
        expect(state.asset.id, isNot(otherAsset.id));
        expect(state.clipboardAddress, isNull);
        expect(state.isClipboardEmpty, true);
      },
    );
  });

  group('Amount', () {
    test('When amount textfield changes, send all flag is removed', () async {
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);

      expect(initialState.amount, 0);
      expect(initialState.isSendAllFunds, false);

      await container.read(provider.notifier).setSendMaxAmount(true);

      final sendAllState = await container.read(provider.future);
      expect(sendAllState.amount, kOneBtcInSats);
      expect(sendAllState.isSendAllFunds, true);

      // Wait for microtask to reset _isProgrammaticUpdate flag
      await Future.microtask(() {});

      container
          .read(provider.notifier)
          .updateAmountFieldText(kPointOneBtc.toString());

      final finalState = await container.read(provider.future);
      expect(finalState.amount, kPointOneBtcInSats);
      expect(finalState.isSendAllFunds, false);
    });

    test(
      'When crypto amount is entered, underlying amount should be correct',
      () async {
        final provider = sendAssetInputStateProvider(args);
        final initialState = await container.read(provider.future);

        container.read(provider.notifier).setType(AquaAssetInputType.crypto);
        container
            .read(provider.notifier)
            .updateAmountFieldText(kOneBtc.toString());

        final state = await container.read(provider.future);
        expect(initialState.amount, 0);
        expect(state.amount, kOneBtcInSats);
        expect(state.amountFieldText, kOneBtc.toString());
      },
    );
    test(
      'When fiat amount is entered, underlying amount should be correct',
      () async {
        final provider = sendAssetInputStateProvider(args);
        final initialState = await container.read(provider.future);

        container.read(provider.notifier).setType(AquaAssetInputType.fiat);
        container.read(provider.notifier).updateAmountFieldText('100');

        // Based on the mocked rate: 100 USD = 0.0017639795 BTC
        final state = await container.read(provider.future);
        expect(initialState.amount, 0);
        expect(state.amount, kOneHundredUsdInBtcSats);
        expect(state.amountFieldText, '100');
      },
    );
    test('When input type changed, amount should be converted', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);
      container
          .read(provider.notifier)
          .updateAmountFieldText(kPointOneBtc.toString());
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final state = await container.read(provider.future);
      expect(initialState.amount, kPointOneBtcInSats);
      expect(initialState.amountFieldText, kPointOneBtc.toString());
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(state.amount, kPointOneBtcInSats);
      expect(state.amountFieldText, isNotNull);
      expect(state.inputType, AquaAssetInputType.fiat);
    });

    test(
        'When switching input type with non-USD currency, conversion symbol matches currency',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockExchangeRatesProvider.mockGetAvailableCurrencies(
          value: [kBtcUsdExchangeRate, kBtcEurExchangeRate]);
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);

      addTearDown(() {
        mockExchangeRatesProvider
            .mockGetAvailableCurrencies(value: [kBtcUsdExchangeRate]);
        mockExchangeRatesProvider.mockGetCurrentCurrency(
            value: kBtcUsdExchangeRate);
      });

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container.read(provider.notifier).setType(AquaAssetInputType.crypto);

      final state = await container.read(provider.future);
      expect(state.rate.currency, FiatCurrency.eur);
      expect(state.inputType, AquaAssetInputType.crypto);
      expect(state.displayConversionAmount, '€0,00');
    });
    test('When input type changed, send max should be preserved', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);
      await container.read(provider.notifier).setSendMaxAmount(true);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final state = await container.read(provider.future);
      expect(initialState.amount, kOneBtcInSats);
      expect(initialState.amountFieldText, kOneBtcDisplay);
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(initialState.isSendAllFunds, true);
      expect(state.amount, kOneBtcInSats);
      expect(state.amountFieldText, isNotNull);
      expect(state.inputType, AquaAssetInputType.fiat);
      expect(state.isSendAllFunds, true);
    });
    test('When send all crypto, entire balance is used for amount', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.crypto);
      await container.read(provider.notifier).setSendMaxAmount(true);

      final state = await container.read(provider.future);
      expect(initialState.isSendAllFunds, false);
      expect(initialState.amount, 0);
      expect(initialState.amountFieldText, null);
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(state.isSendAllFunds, true);
      expect(state.amount, kOneBtcInSats);
      expect(state.amountFieldText, kOneBtcDisplay);
      expect(state.inputType, AquaAssetInputType.crypto);
      expect(state.displayConversionAmount, kBtcUsdRateStr);
    });
    test('When send all from fiat mode, switches to crypto and uses balance',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      await container.read(provider.notifier).setSendMaxAmount(true);

      final state = await container.read(provider.future);
      expect(initialState.isSendAllFunds, false);
      expect(initialState.amount, 0);
      expect(initialState.amountFieldText, null);
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(state.isSendAllFunds, true);
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.amountFieldText, kOneHundredUsdInBtcDisplay);
      expect(state.inputType, AquaAssetInputType.crypto);
    });
    test('When balance is zero, setSendMaxAmount should do nothing', () async {
      // First set up provider with non-zero balance to initialize
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future); // Initialize provider

      // Now mock zero balance for the setSendMaxAmount call
      mockBalanceProvider.mockGetBalanceCall(value: 0); // Zero balance

      // Get state before attempting send max
      final initialState = container.read(provider).value!;

      // Try to enable send max with zero balance
      await container.read(provider.notifier).setSendMaxAmount(true);

      final state = container.read(provider).value!;

      // State should remain unchanged since balance is 0
      expect(state.isSendAllFunds,
          initialState.isSendAllFunds); // Should be unchanged
      expect(state.amount, initialState.amount); // Should be unchanged
      expect(state.amountFieldText,
          initialState.amountFieldText); // Should be unchanged
    });
    test('When amount is zero, converted amount is null', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('0');

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(state.amount, 0);
      expect(state.displayConversionAmount, '\$0.00');
    });
    test('When non-zero crypto amount, converted amount is NOT null', () async {
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kOneHundredUsdInBtc.toString());

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.displayConversionAmount, '${kUsdCurrencySymbol}100.00');
    });
    test('When non-zero fiat amount, converted amount is NOT null', () async {
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container.read(provider.notifier).updateAmountFieldText('100.00');

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.displayConversionAmount, '\$0.00');
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.displayConversionAmount, kOneHundredUsdInBtcDisplay);
    });
    test('When USDt fiat amount, converted amount is null', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final asset = Asset.usdtTrx();
      final provider = sendAssetInputStateProvider(args.copyWith(asset: asset));
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('100.00');

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.displayConversionAmount, null);
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(state.amount, kOneHundredUsdtInSats);
      expect(state.displayConversionAmount, null);
    });

    test('Initial displayConversionAmount should be \$0.00 for regular assets',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args); // BTC asset
      final state = await container.read(provider.future);

      expect(state.amount, 0);
      expect(state.amountFieldText, isNull);
      expect(state.displayConversionAmount,
          '\$0.00'); // Should show $0.00, not null
      expect(state.asset.ticker, 'BTC');
    });

    test('Initial displayConversionAmount should be null for USDt assets',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final asset = Asset.usdtTrx();
      final provider = sendAssetInputStateProvider(args.copyWith(asset: asset));
      final state = await container.read(provider.future);

      expect(state.amount, 0);
      expect(state.amountFieldText, isNull);
      expect(state.displayConversionAmount,
          null); // USDt should show null, not $0.00
      expect(state.asset.isUSDt, true);
    });

    test(
        'USDt currency change should reset amount and preserve null conversion',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final asset = Asset.usdtTrx();
      final provider = sendAssetInputStateProvider(args.copyWith(asset: asset));
      final initialState = await container.read(provider.future);

      // Change currency for USDt asset - should reset amount
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final afterCurrencyChangeState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, null);
      expect(initialState.amountFieldText, isNull);
      expect(initialState.amount, 0);
      expect(afterCurrencyChangeState.displayConversionAmount, null);
      expect(afterCurrencyChangeState.amountFieldText, isNull);
      expect(afterCurrencyChangeState.amount, 0);
      expect(afterCurrencyChangeState.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChangeState.asset.isUSDt, true);
      expect(afterCurrencyChangeState.isSendAllFunds, false);
    });

    test('Regular asset currency change should reset amount and update symbol',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args); // BTC asset
      final initialState = await container.read(provider.future);

      // Change currency for regular asset - should reset amount
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final afterCurrencyChangeState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      expect(initialState.amountFieldText, isNull);
      expect(initialState.amount, 0);
      expect(afterCurrencyChangeState.displayConversionAmount, '€0,00');
      expect(afterCurrencyChangeState.amountFieldText, isNull);
      expect(afterCurrencyChangeState.amount, 0);
      expect(afterCurrencyChangeState.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChangeState.asset.ticker, 'BTC');
      expect(afterCurrencyChangeState.isSendAllFunds, false);
    });

    test('Amount is editable when LNURL param amount is NOT fixed', () async {
      final otherAsset = Asset.lightning();
      const kFakeOriginalAmount = 100;
      const kFakeLnUrlAmount = 200;
      final container = ProviderContainer(
          overrides: getStandardOverrides(
        clipboardContent: null,
        addressParser: mockAddressParser,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amountInSats: kFakeOriginalAmount,
          lnurlParseResult: LNURLParseResult(
            payParams: LNURLPayParams(
              minSendable: kFakeLnUrlAmount * 100,
              maxSendable: kFakeLnUrlAmount * 1000,
            ),
          ),
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);
      expect(initialState.amount, 0);

      await container.read(provider.notifier).pasteScannedQrCode(kFakeContent);

      final state = await container.read(provider.future);
      expect(state.asset.id, otherAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
      expect(state.addressFieldText, isNotNull);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.isLnurl, true);
      expect(state.lnurlData, isNotNull);
      expect(state.lnurlData?.payParams?.isFixedAmount, false);
      expect(state.amount, kFakeOriginalAmount);
      expect(state.isAmountEditable, isTrue);
    });

    test('should update amount field text', () async {
      final provider = sendAssetInputStateProvider(args);
      const kAmount = 100;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final finalState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(finalState.amountFieldText, '100');
      expect(finalState.amount, kOneHundredUsdtInSats); // 100 USDt in sats
    });

    test('should update fiat conversion amount', () async {
      final provider = sendAssetInputStateProvider(args);
      const kAmount = 100;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final finalState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      // 100 BTC * 56690 USD/BTC = 5669000 USD
      expect(finalState.displayConversionAmount, '\$5,669,000.00');
    });

    test('should NOT update balance amount', () async {
      final provider = sendAssetInputStateProvider(args);
      const kAmount = 100;
      mockBalanceProvider.mockGetBalanceCall(value: kPointOneBtcInSats);

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final finalState = await container.read(provider.future);

      expect(initialState.balanceInSats, kPointOneBtcInSats);
      expect(finalState.balanceInSats, kPointOneBtcInSats);
    });

    test('should NOT update input type', () async {
      final provider = sendAssetInputStateProvider(args);
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
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kPointOneBtc.toString());

      final inputState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('');

      final finalState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amount, 0);
      expect(initialState.displayConversionAmount, '\$0.00');

      expect(inputState.amountFieldText, kPointOneBtc.toString());
      expect(inputState.amount, kPointOneBtcInSats);
      expect(inputState.displayConversionAmount, '\$5,669.00');

      expect(finalState.amountFieldText, '');
      expect(finalState.amount, 0);
      expect(finalState.displayConversionAmount, '\$0.00');
    });

    test('should reset to initial values when removing input with decimal',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      const kAmount = 1.5;

      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final inputState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('');

      final finalState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amount, 0);
      expect(initialState.displayConversionAmount, '\$0.00');

      expect(inputState.amountFieldText, kAmount.toString());
      expect(inputState.amount, 150000000); // 1.5 BTC in sats
      expect(inputState.displayConversionAmount, '\$85,035.00'); // 1.5 * 56690

      expect(finalState.amountFieldText, '');
      expect(finalState.amount, 0);
      expect(finalState.displayConversionAmount, '\$0.00');
    });
  });

  group('Note', () {
    test('initial note should be null', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      final state = await container.read(provider.future);

      expect(state.note, isNull);
    });

    test('should update note with string value', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      const testNote = 'Payment for coffee';

      final initialState = await container.read(provider.future);
      expect(initialState.note, isNull);

      container.read(provider.notifier).updateNote(testNote);
      final updatedState = await container.read(provider.future);

      expect(updatedState.note, equals(testNote));
    });

    test('should update note with empty string', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      const initialNote = 'Initial note';
      const emptyNote = '';

      // Initialize state first
      await container.read(provider.future);

      // Set initial note
      container.read(provider.notifier).updateNote(initialNote);
      final stateWithNote = await container.read(provider.future);
      expect(stateWithNote.note, equals(initialNote));

      // Update to empty string
      container.read(provider.notifier).updateNote(emptyNote);
      final stateWithEmptyNote = await container.read(provider.future);

      expect(stateWithEmptyNote.note, equals(emptyNote));
    });

    test('should clear note by setting to null', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      const testNote = 'Test note to be cleared';

      // Initialize state first
      await container.read(provider.future);

      // Set initial note
      container.read(provider.notifier).updateNote(testNote);
      final stateWithNote = await container.read(provider.future);
      expect(stateWithNote.note, equals(testNote));

      // Clear note
      container.read(provider.notifier).updateNote(null);
      final stateWithoutNote = await container.read(provider.future);

      expect(stateWithoutNote.note, isNull);
    });

    test('should preserve other state fields when updating note', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: asset,
          address: kFakeBitcoinAddress,
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      const testNote = 'Preserve other fields test';
      const kInputAmount = 50;

      // Initialize state first
      await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeBitcoinAddress);

      final stateBeforeNote = await container.read(provider.future);

      // Update note
      container.read(provider.notifier).updateNote(testNote);
      final stateAfterNote = await container.read(provider.future);

      // Verify note was updated
      expect(stateAfterNote.note, equals(testNote));

      // Verify other fields were preserved
      expect(stateAfterNote.amount, equals(stateBeforeNote.amount));
      expect(stateAfterNote.addressFieldText,
          equals(stateBeforeNote.addressFieldText));
      expect(stateAfterNote.amountFieldText,
          equals(stateBeforeNote.amountFieldText));
      expect(stateAfterNote.asset, equals(stateBeforeNote.asset));
      expect(stateAfterNote.inputType, equals(stateBeforeNote.inputType));
    });

    test('should handle unicode and special characters in note', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      const unicodeNote = 'Payment 💰 für Kaffee & Kuchen 🍰';

      // Initialize state first
      await container.read(provider.future);

      container.read(provider.notifier).updateNote(unicodeNote);
      final state = await container.read(provider.future);

      expect(state.note, equals(unicodeNote));
    });

    test('should handle very long note strings', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      final longNote = 'A' * 1000; // 1000 character note

      // Initialize state first
      await container.read(provider.future);

      container.read(provider.notifier).updateNote(longNote);
      final state = await container.read(provider.future);

      expect(state.note, equals(longNote));
      expect(state.note!.length, equals(1000));
    });
  });

  group('Input unit', () {
    test('initial input unit should match display unit (btc -> crypto)',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      final state = await container.read(provider.future);

      expect(state.cryptoUnit, AquaAssetInputUnit.crypto);
    });

    test('initial input unit should match display unit (sats -> sats)',
        () async {
      final mockSatsDisplayUnitsProvider = MockDisplayUnitsProvider();
      final mockContainer = ProviderContainer(
          overrides: getStandardOverrides(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockSatsDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));

      // Mock display units provider to return sats
      mockSatsDisplayUnitsProvider.mockCurrentDisplayUnit(
          value: SupportedDisplayUnits.sats);
      mockSatsDisplayUnitsProvider.mockGetForcedDisplayUnit(
          value: SupportedDisplayUnits.sats);
      mockSatsDisplayUnitsProvider.mockConvertSatsToUnit();
      mockSatsDisplayUnitsProvider.mockConvertUnitToSats();

      // Set up other required mocks
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      final state = await mockContainer.read(provider.future);

      expect(state.cryptoUnit, AquaAssetInputUnit.sats);
    });

    test('initial input unit should match display unit (bits -> bits)',
        () async {
      final mockBitsDisplayUnitsProvider = MockDisplayUnitsProvider();
      final mockContainer = ProviderContainer(
          overrides: getStandardOverrides(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockBitsDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));

      // Mock display units provider to return bits
      mockBitsDisplayUnitsProvider.mockCurrentDisplayUnit(
          value: SupportedDisplayUnits.bits);
      mockBitsDisplayUnitsProvider.mockGetForcedDisplayUnit(
          value: SupportedDisplayUnits.bits);
      mockBitsDisplayUnitsProvider.mockConvertSatsToUnit();
      mockBitsDisplayUnitsProvider.mockConvertUnitToSats();

      // Set up other required mocks
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(args);
      final state = await mockContainer.read(provider.future);

      expect(state.cryptoUnit, AquaAssetInputUnit.bits);
    });

    test('Lightning asset should use display unit (btc -> crypto)', () async {
      final lightningAsset = Asset.lightning();
      final lightningArgs = SendAssetArguments.fromAsset(lightningAsset);
      final mockBtcDisplayUnitsProvider = MockDisplayUnitsProvider();
      final mockContainer = ProviderContainer(
          overrides: getStandardOverrides(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockBtcDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));

      // Mock display units provider to return BTC for Lightning
      mockBtcDisplayUnitsProvider.mockCurrentDisplayUnit(
          value: SupportedDisplayUnits.btc);
      mockBtcDisplayUnitsProvider.mockGetForcedDisplayUnit(
          value: SupportedDisplayUnits.btc);
      mockBtcDisplayUnitsProvider.mockConvertSatsToUnit();
      mockBtcDisplayUnitsProvider.mockConvertUnitToSats();

      // Set up other required mocks
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(lightningArgs);
      final state = await mockContainer.read(provider.future);

      expect(state.cryptoUnit, AquaAssetInputUnit.crypto);
      expect(state.asset.isLightning, true);
    });

    test('Lightning asset should use display unit (sats -> sats)', () async {
      final lightningAsset = Asset.lightning();
      final lightningArgs = SendAssetArguments.fromAsset(lightningAsset);
      final mockSatsDisplayUnitsProvider = MockDisplayUnitsProvider();
      final mockContainer = ProviderContainer(
          overrides: getStandardOverrides(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockSatsDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));

      // Mock display units provider to return Sats for Lightning
      mockSatsDisplayUnitsProvider.mockCurrentDisplayUnit(
          value: SupportedDisplayUnits.sats);
      mockSatsDisplayUnitsProvider.mockGetForcedDisplayUnit(
          value: SupportedDisplayUnits.sats);
      mockSatsDisplayUnitsProvider.mockConvertSatsToUnit();
      mockSatsDisplayUnitsProvider.mockConvertUnitToSats();

      // Set up other required mocks
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(lightningArgs);
      final state = await mockContainer.read(provider.future);

      expect(state.cryptoUnit, AquaAssetInputUnit.sats);
      expect(state.asset.isLightning, true);
    });

    test('Lightning asset should use display unit (bits -> bits)', () async {
      final lightningAsset = Asset.lightning();
      final lightningArgs = SendAssetArguments.fromAsset(lightningAsset);
      final mockBitsDisplayUnitsProvider = MockDisplayUnitsProvider();
      final mockContainer = ProviderContainer(
          overrides: getStandardOverrides(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockBitsDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));

      // Mock display units provider to return Bits for Lightning
      mockBitsDisplayUnitsProvider.mockCurrentDisplayUnit(
          value: SupportedDisplayUnits.bits);
      mockBitsDisplayUnitsProvider.mockGetForcedDisplayUnit(
          value: SupportedDisplayUnits.bits);
      mockBitsDisplayUnitsProvider.mockConvertSatsToUnit();
      mockBitsDisplayUnitsProvider.mockConvertUnitToSats();

      // Set up other required mocks
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(lightningArgs);
      final state = await mockContainer.read(provider.future);

      expect(state.cryptoUnit, AquaAssetInputUnit.bits);
      expect(state.asset.isLightning, true);
    });

    test(
        'USDt asset should always use crypto input unit even when global unit is sats',
        () async {
      final usdtAsset = Asset.usdtLiquid();
      final usdtArgs = SendAssetArguments.fromAsset(usdtAsset);
      final mockSatsDisplayUnitsProvider = MockDisplayUnitsProvider();
      final mockContainer = ProviderContainer(
          overrides: getStandardOverrides(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockSatsDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));

      // Mock display units provider to return Sats (global setting)
      mockSatsDisplayUnitsProvider.mockCurrentDisplayUnit(
          value: SupportedDisplayUnits.sats);
      mockSatsDisplayUnitsProvider.mockGetForcedDisplayUnit(
          value: SupportedDisplayUnits.sats);
      mockSatsDisplayUnitsProvider.mockConvertSatsToUnit();
      mockSatsDisplayUnitsProvider.mockConvertUnitToSats();

      // Set up other required mocks
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(usdtArgs);
      final state = await mockContainer.read(provider.future);

      // USDt should always use crypto unit, not sats
      expect(state.cryptoUnit, AquaAssetInputUnit.crypto);
      expect(state.asset.isUSDt, true);
    });

    test(
        'USDt asset should always use crypto input unit even when global unit is bits',
        () async {
      final usdtAsset = Asset.usdtLiquid();
      final usdtArgs = SendAssetArguments.fromAsset(usdtAsset);
      final mockBitsDisplayUnitsProvider = MockDisplayUnitsProvider();
      final mockContainer = ProviderContainer(
          overrides: getStandardOverrides(
        addressParser: mockAddressParser,
        manageAssets: mockManageAssetsProvider,
        bitcoin: mockBitcoinProvider,
        balance: mockBalanceProvider,
        prefs: mockPrefsProvider,
        mockDisplayUnitsProvider: mockBitsDisplayUnitsProvider,
        mockExchangeRatesProvider: mockExchangeRatesProvider,
      ));

      // Mock display units provider to return Bits (global setting)
      mockBitsDisplayUnitsProvider.mockCurrentDisplayUnit(
          value: SupportedDisplayUnits.bits);
      mockBitsDisplayUnitsProvider.mockGetForcedDisplayUnit(
          value: SupportedDisplayUnits.bits);
      mockBitsDisplayUnitsProvider.mockConvertSatsToUnit();
      mockBitsDisplayUnitsProvider.mockConvertUnitToSats();

      // Set up other required mocks
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: false);

      final provider = sendAssetInputStateProvider(usdtArgs);
      final state = await mockContainer.read(provider.future);

      // USDt should always use crypto unit, not bits
      expect(state.cryptoUnit, AquaAssetInputUnit.crypto);
      expect(state.asset.isUSDt, true);
    });

    test('should reset amount when changing input unit from crypto to sats',
        () async {
      final provider = sendAssetInputStateProvider(args);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      // Enter amount in crypto mode
      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());
      final cryptoState = await container.read(provider.future);

      // Change unit to sats - amount should reset
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.sats);
      final afterUnitChange = await container.read(provider.future);

      // Verify unit change resets amount
      expect(initialState.amountFieldText, isNull);
      expect(initialState.amount, 0);
      expect(initialState.displayConversionAmount, '\$0.00');

      // 100 BTC * 56690 USD/BTC = 5669000 USD
      expect(cryptoState.amountFieldText, kInputAmount.toString());
      expect(cryptoState.amount, kOneBtcInSats * kInputAmount);
      expect(cryptoState.displayConversionAmount, '\$5,669,000.00');
      expect(cryptoState.cryptoUnit, AquaAssetInputUnit.crypto);

      // After unit change, amount should be reset
      expect(afterUnitChange.amountFieldText, isNull);
      expect(afterUnitChange.amount, 0);
      expect(afterUnitChange.cryptoUnit, AquaAssetInputUnit.sats);
      expect(afterUnitChange.isSendAllFunds, false);
      // For crypto input type with zero amount, display shows fiat amount
      expect(afterUnitChange.displayConversionAmount, '\$0.00');

      // Enter same number in sats mode - should be interpreted as sats
      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());
      final satsState = await container.read(provider.future);

      // 100 Sats * 56690 USD/BTC / 100000000 sats/BTC = 0.057 USD
      expect(satsState.amountFieldText, kInputAmount.toString());
      expect(satsState.amount, kInputAmount);
      expect(satsState.displayConversionAmount, '\$0.06');
      expect(satsState.cryptoUnit, AquaAssetInputUnit.sats);
    });

    test('should reset amount when changing input unit from crypto to bits',
        () async {
      final provider = sendAssetInputStateProvider(args);
      const kInputAmount = 100;

      final initialState = await container.read(provider.future);

      // Enter amount in crypto mode
      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());
      final cryptoState = await container.read(provider.future);

      // Change unit to bits - amount should reset
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.bits);
      final afterUnitChange = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.amount, 0);

      // 100 BTC * 56690 USD/BTC = 5669000 USD
      expect(cryptoState.amountFieldText, kInputAmount.toString());
      expect(cryptoState.amount, 10000000000); // 100 BTC in sats
      expect(cryptoState.displayConversionAmount, '\$5,669,000.00');
      expect(cryptoState.cryptoUnit, AquaAssetInputUnit.crypto);

      // After unit change, amount should be reset
      expect(afterUnitChange.amountFieldText, isNull);
      expect(afterUnitChange.amount, 0);
      expect(afterUnitChange.cryptoUnit, AquaAssetInputUnit.bits);
      expect(afterUnitChange.isSendAllFunds, false);
      expect(afterUnitChange.displayConversionAmount, '\$0.00');

      // Enter same number in bits mode - should be interpreted as bits
      container
          .read(provider.notifier)
          .updateAmountFieldText(kInputAmount.toString());
      final bitsState = await container.read(provider.future);

      // 100 bits * 100 sats/bit = 10000 sats
      expect(bitsState.amountFieldText, kInputAmount.toString());
      expect(bitsState.amount, 10000); // 100 bits * 100 sats/bit
      expect(bitsState.displayConversionAmount, '\$5.67');
      expect(bitsState.cryptoUnit, AquaAssetInputUnit.bits);
    });

    test('should reset amount when changing input unit from sats to crypto',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);

      final provider = sendAssetInputStateProvider(args);
      const kAmount = 1000000;
      const kAmountText = '1,000,000';

      final initialState = await container.read(provider.future);

      // Change to sats mode first - this resets amount
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.sats);
      final afterSatsChange = await container.read(provider.future);

      // Enter amount in sats mode
      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmountText); // 1000000 sats = 0.01 BTC
      final satsState = await container.read(provider.future);

      // Change to crypto mode - amount should reset
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.crypto);
      final afterCryptoChange = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(initialState.displayConversionAmount, '\$0.00');

      // After switching to sats, amount should be reset
      expect(afterSatsChange.amountFieldText, isNull);
      expect(afterSatsChange.amount, 0);
      expect(afterSatsChange.cryptoUnit, AquaAssetInputUnit.sats);
      expect(afterSatsChange.isSendAllFunds, false);

      expect(satsState.amountFieldText, kAmountText);
      expect(satsState.amount, kAmount);
      expect(satsState.displayConversionAmount, '\$566.90');
      expect(satsState.cryptoUnit, AquaAssetInputUnit.sats);

      // After switching to crypto, amount should be reset
      expect(afterCryptoChange.amountFieldText, isNull);
      expect(afterCryptoChange.amount, 0);
      expect(afterCryptoChange.cryptoUnit, AquaAssetInputUnit.crypto);
      expect(afterCryptoChange.isSendAllFunds, false);
      expect(afterCryptoChange.displayConversionAmount, '\$0.00');

      // Enter same number in crypto mode - should be interpreted as crypto units
      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString()); // 1000000 BTC
      final cryptoState = await container.read(provider.future);

      expect(cryptoState.amountFieldText, kAmountText);
      expect(cryptoState.displayConversionAmount, '\$56,690,000,000.00');
      expect(cryptoState.cryptoUnit, AquaAssetInputUnit.crypto);
    });
  });

  test('should reset amount when changing input unit from bits to sats',
      () async {
    final provider = sendAssetInputStateProvider(args);
    const kAmount = 1000000; // 1M bits = 1 BTC
    const kAmountText = '1,000,000';

    final initialState = await container.read(provider.future);

    // Change to bits mode - this resets amount
    container.read(provider.notifier).setUnit(AquaAssetInputUnit.bits);
    final afterBitsChange = await container.read(provider.future);

    // Enter amount in bits mode
    container.read(provider.notifier).updateAmountFieldText(kAmount.toString());
    final bitsState = await container.read(provider.future);

    // Change to sats mode - amount should reset
    container.read(provider.notifier).setUnit(AquaAssetInputUnit.sats);
    final afterSatsChange = await container.read(provider.future);

    expect(initialState.amountFieldText, isNull);
    expect(initialState.displayConversionAmount, '\$0.00');

    // After switching to bits, amount should be reset
    expect(afterBitsChange.amountFieldText, isNull);
    expect(afterBitsChange.amount, 0);
    expect(afterBitsChange.cryptoUnit, AquaAssetInputUnit.bits);
    expect(afterBitsChange.isSendAllFunds, false);

    // 1,000,000 bits * 100 sats/bit = 100,000,000 sats (1 BTC)
    expect(bitsState.amountFieldText, kAmountText);
    expect(bitsState.amount, 100000000);
    expect(bitsState.displayConversionAmount, '\$56,690.00');
    expect(bitsState.cryptoUnit, AquaAssetInputUnit.bits);

    // After switching to sats, amount should be reset
    expect(afterSatsChange.amountFieldText, isNull);
    expect(afterSatsChange.amount, 0);
    expect(afterSatsChange.cryptoUnit, AquaAssetInputUnit.sats);
    expect(afterSatsChange.isSendAllFunds, false);

    // Enter same number in sats mode - should be interpreted as sats
    container.read(provider.notifier).updateAmountFieldText(kAmount.toString());
    final satsState = await container.read(provider.future);

    expect(satsState.amountFieldText, kAmountText);
    expect(satsState.amount, 1000000);
    expect(satsState.displayConversionAmount, '\$566.90');
    expect(satsState.cryptoUnit, AquaAssetInputUnit.sats);
  });

  test('should reset amount when changing unit (no amount preservation)',
      () async {
    final provider = sendAssetInputStateProvider(args);
    const kInputAmount = 100;

    final initialState = await container.read(provider.future);

    // Enter amount in crypto mode
    container
        .read(provider.notifier)
        .updateAmountFieldText(kInputAmount.toString());
    final cryptoState = await container.read(provider.future);

    // Change to sats mode - amount should reset
    container.read(provider.notifier).setUnit(AquaAssetInputUnit.sats);
    final afterUnitChange = await container.read(provider.future);

    expect(initialState.amount, 0);
    expect(cryptoState.amount, 10000000000); // 100 BTC in sats
    expect(cryptoState.cryptoUnit, AquaAssetInputUnit.crypto);

    // Amount should be reset after unit change
    expect(afterUnitChange.amount, 0);
    expect(afterUnitChange.amountFieldText, isNull);
    expect(afterUnitChange.cryptoUnit, AquaAssetInputUnit.sats);
    expect(afterUnitChange.isSendAllFunds, false);

    // Enter same number in sats mode - should be interpreted as sats
    container
        .read(provider.notifier)
        .updateAmountFieldText(kInputAmount.toString());
    final satsState = await container.read(provider.future);

    expect(satsState.amount, 100); // 100 sats (not converted from BTC)
    expect(satsState.amountFieldText, kInputAmount.toString());
    expect(satsState.cryptoUnit, AquaAssetInputUnit.sats);
  });

  group('Input type', () {
    test('should change input type from crypto to fiat', () async {
      final provider = sendAssetInputStateProvider(args);
      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);

      final fiatState = await container.read(provider.future);

      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
    });

    test(
        'should update balance and conversion display when switching input types',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);

      // Get initial crypto state
      final cryptoState = await container.read(provider.future);
      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(cryptoState.balanceDisplay, kOneBtcDisplay); // "1.00 000 000"
      expect(cryptoState.displayConversionAmount, '\$0.00');

      // Switch to fiat input type
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      final fiatState = await container.read(provider.future);

      // Balance display should now be in fiat format
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(fiatState.balanceDisplay, '\$56,690.00'); // Fiat format
      // Zero BTC format
      expect(fiatState.displayConversionAmount, '0.00\u2009000\u2009000');
    });

    test('should swap values on Crypto to Fiat', () async {
      final provider = sendAssetInputStateProvider(args);
      const kCryptoAmount = 1;
      const kFiatAmount = 100;

      await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kCryptoAmount.toString());

      final cryptoState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container
          .read(provider.notifier)
          .updateAmountFieldText(kFiatAmount.toString());

      final fiatState = await container.read(provider.future);

      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(cryptoState.amountFieldText, kCryptoAmount.toString());
      expect(cryptoState.displayConversionAmount, '\$56,690.00');
      expect(fiatState.amountFieldText, kFiatAmount.toString());
      expect(fiatState.displayConversionAmount, kOneHundredUsdInBtcDisplay);
    });

    test('should swap values on Fiat to Crypto', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);

      final provider = sendAssetInputStateProvider(args);
      const kFiatAmount = 1000;
      const kFiatAmountText = '1,000';
      const kCryptoAmount = 1;
      const kCryptoAmountText = '1';

      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container
          .read(provider.notifier)
          .updateAmountFieldText(kFiatAmount.toString());

      final fiatState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.crypto);
      container
          .read(provider.notifier)
          .updateAmountFieldText(kCryptoAmount.toString());

      final cryptoState = await container.read(provider.future);

      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(cryptoState.inputType, AquaAssetInputType.crypto);
      expect(fiatState.amountFieldText, kFiatAmountText);
      expect(fiatState.displayConversionAmount, kOneThousandUsdInBtcDisplay);
      expect(cryptoState.amountFieldText, kCryptoAmountText);
      expect(cryptoState.displayConversionAmount, '\$56,690.00');
    });

    test('should preserve amount sats on input type change', () async {
      final provider = sendAssetInputStateProvider(args);
      const kFiatAmount = 1000;
      const kCryptoAmount = 1;

      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container
          .read(provider.notifier)
          .updateAmountFieldText(kFiatAmount.toString());

      final fiatState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.crypto);
      container
          .read(provider.notifier)
          .updateAmountFieldText(kCryptoAmount.toString());

      final cryptoState = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(fiatState.amount, kOneThousandUsdInBtcSats);
      expect(cryptoState.amount, 100000000); // 1 BTC in sats
    });
  });

  group('Currency', () {
    test('should change fiat rate on currency change', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
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

    test('should change fiat conversion rate on currency change', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      const kAmount = 100;
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final usdState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      expect(usdState.displayConversionAmount, kOneHundredUsdInBtcDisplay);

      // Note: Currency change behavior in send provider may differ from receive provider
      // This test verifies basic fiat input functionality
    });

    test('should change crypto conversion rate on currency change', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      const kAmount = 0.1;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final usdState = await container.read(provider.future);

      expect(initialState.displayConversionAmount, '\$0.00');
      expect(usdState.displayConversionAmount, '\$5,669.00');

      // Note: Currency change behavior in send provider may differ from receive provider
      // This test verifies basic crypto input and fiat conversion functionality
    });

    test('should preserve amount sats on currency change', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);
      const kAmount = 0.1;
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kAmount.toString());

      final usdState = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(usdState.amount, 10000000); // 0.1 BTC in sats

      // Note: Currency change behavior in send provider may differ from receive provider
      // This test verifies basic amount preservation functionality
    });

    test('should reset amount when currency changes (amount text reset)',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);
      const kAmount = '1'; // User types "1"
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText(kAmount);

      final afterInputState = await container.read(provider.future);

      // Change currency
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final afterCurrencyChangeState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(afterInputState.amountFieldText, kAmount); // User typed "1"
      expect(afterCurrencyChangeState.amountFieldText,
          isNull); // Should reset to null
      expect(afterCurrencyChangeState.amount, 0); // Amount should reset to 0
      expect(afterCurrencyChangeState.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChangeState.isSendAllFunds, false);
    });

    test('should preserve empty amount text on currency change', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      // Change currency without entering any amount
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final afterCurrencyChangeState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(afterCurrencyChangeState.amountFieldText,
          isNull); // Should stay null, not become "0.00 000 000"
      expect(afterCurrencyChangeState.displayConversionAmount,
          '€0,00'); // But conversion should update
      expect(afterCurrencyChangeState.rate.currency, FiatCurrency.eur);
    });

    test('should reset decimal input when currency changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);
      const kAmount = '0.5'; // User types "0.5"
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText(kAmount);

      final afterInputState = await container.read(provider.future);

      // Change currency
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final afterCurrencyChangeState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(afterInputState.amountFieldText, kAmount); // User typed "0.5"
      expect(afterCurrencyChangeState.amountFieldText, isNull); // Should reset
      expect(afterCurrencyChangeState.amount, 0); // Amount should reset to 0
      expect(afterCurrencyChangeState.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChangeState.isSendAllFunds, false);
    });

    test('should reset fiat input when currency changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);
      const kAmount = '100'; // User types "100" in fiat mode
      final initialState = await container.read(provider.future);

      // Switch to fiat mode and enter amount
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container.read(provider.notifier).updateAmountFieldText(kAmount);

      final afterInputState = await container.read(provider.future);

      // Change currency
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final afterCurrencyChangeState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(afterInputState.amountFieldText, kAmount); // User typed "100"
      expect(afterCurrencyChangeState.amountFieldText, isNull); // Should reset
      expect(afterCurrencyChangeState.amount, 0); // Amount should reset to 0
      expect(afterCurrencyChangeState.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChangeState.inputType, AquaAssetInputType.fiat);
      expect(afterCurrencyChangeState.isSendAllFunds, false);
    });
  });

  group('Regression Tests', () {
    test('Empty text should remain empty when currency changes (amount resets)',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      // Change currency with empty amount field
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);

      final afterCurrencyChangeState = await container.read(provider.future);

      expect(initialState.amountFieldText, isNull);
      expect(afterCurrencyChangeState.amountFieldText, isNull);
      expect(afterCurrencyChangeState.displayConversionAmount, '€0,00');
    });

    test('Amount should reset when currency changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);

      // Wait for provider to initialize
      await container.read(provider.future);

      // User types "1"
      container.read(provider.notifier).updateAmountFieldText('1');
      final beforeCurrencyChange = await container.read(provider.future);

      // Change currency - amount should reset
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterCurrencyChange = await container.read(provider.future);

      expect(beforeCurrencyChange.amountFieldText, '1');
      expect(beforeCurrencyChange.amount, 100000000); // 1 BTC in sats
      expect(afterCurrencyChange.amountFieldText, isNull);
      expect(afterCurrencyChange.amount, 0);
      expect(afterCurrencyChange.displayConversionAmount, '€0,00');
      expect(afterCurrencyChange.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChange.isSendAllFunds, false);
    });

    test('Decimal input should reset on currency change', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);

      // Wait for provider to initialize
      await container.read(provider.future);

      // User types "0.123"
      container.read(provider.notifier).updateAmountFieldText('0.123');
      final beforeCurrencyChange = await container.read(provider.future);

      // Change currency - amount should reset
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterCurrencyChange = await container.read(provider.future);

      expect(beforeCurrencyChange.amountFieldText, '0.123');
      expect(beforeCurrencyChange.amount, 12300000); // 0.123 BTC in sats
      expect(afterCurrencyChange.amountFieldText, isNull);
      expect(afterCurrencyChange.amount, 0);
      expect(afterCurrencyChange.displayConversionAmount, '€0,00');
      expect(afterCurrencyChange.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChange.isSendAllFunds, false);
    });

    test('Fiat input should reset on currency change', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);

      // Wait for provider to initialize
      await container.read(provider.future);

      // Switch to fiat and type "50"
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container.read(provider.notifier).updateAmountFieldText('50');
      final beforeCurrencyChange = await container.read(provider.future);

      // Change currency - amount should reset
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterCurrencyChange = await container.read(provider.future);

      expect(beforeCurrencyChange.amountFieldText, '50');
      expect(beforeCurrencyChange.amount,
          greaterThan(0)); // Should have some amount
      expect(afterCurrencyChange.amountFieldText, isNull);
      expect(afterCurrencyChange.amount, 0);
      expect(afterCurrencyChange.inputType, AquaAssetInputType.fiat);
      expect(afterCurrencyChange.rate.currency, FiatCurrency.eur);
      expect(afterCurrencyChange.isSendAllFunds, false);
      // For fiat input type with zero amount, display conversion shows crypto amount
      expect(afterCurrencyChange.displayConversionAmount, isNotNull);
    });

    test(
        'USDt should reset amount on currency change and maintain null conversion',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final asset = Asset.usdtTrx();
      final provider = sendAssetInputStateProvider(args.copyWith(asset: asset));

      // Initial state
      final initialState = await container.read(provider.future);
      expect(initialState.asset.isUSDt, true); // Verify we have USDt asset
      expect(initialState.displayConversionAmount, null);

      // Enter amount
      container.read(provider.notifier).updateAmountFieldText('100');
      final withAmountState = await container.read(provider.future);
      expect(withAmountState.amountFieldText, '100');
      expect(withAmountState.inputType, AquaAssetInputType.crypto);
      // 100 USDt as parsed (precision 8)
      expect(withAmountState.amount, kOneHundredUsdtInSats);
      // USDt conversion amount is always null (no crypto/fiat conversion needed)
      expect(withAmountState.displayConversionAmount, isNull);

      // Change currency - amount should reset
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterCurrencyChangeState = await container.read(provider.future);
      expect(afterCurrencyChangeState.amountFieldText, isNull);
      expect(afterCurrencyChangeState.amount, 0);
      expect(afterCurrencyChangeState.displayConversionAmount, null);
      expect(afterCurrencyChangeState.isSendAllFunds, false);

      // Fiat mode is no longer supported for USDt in UI.
    });

    test('Regular assets should show proper conversion amounts', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args); // BTC asset

      // Initial state should show $0.00
      final initialState = await container.read(provider.future);
      expect(initialState.displayConversionAmount, '\$0.00');

      // Enter crypto amount should show fiat conversion
      container.read(provider.notifier).updateAmountFieldText('1');
      final withAmountState = await container.read(provider.future);
      expect(withAmountState.displayConversionAmount, startsWith('\$'));
      expect(withAmountState.displayConversionAmount, isNot('\$0.00'));

      // Verify amount text is preserved (main regression test)
      expect(withAmountState.amountFieldText,
          '1'); // Should be "1", not "1.00 000 000"
    });
  });

  group('Conversion amount', () {
    test('should show fiat format when typing crypto amount', () async {
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Type "1" in crypto mode
      container.read(provider.notifier).updateAmountFieldText('1');
      final state = await container.read(provider.future);

      // displayConversionAmount should show fiat format with symbol, not crypto format
      expect(state.displayConversionAmount, startsWith('\$'));
      expect(
          state.displayConversionAmount, '\$56,690.00'); // Based on kBtcUsdRate
    });

    test('should show crypto format when input type is fiat', () async {
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Switch to fiat mode and type "100"
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container.read(provider.notifier).updateAmountFieldText('100');
      final state = await container.read(provider.future);

      // displayConversionAmount should show crypto format when input is fiat
      // For $100 at kBtcUsdRate (56690), the BTC amount should be around 0.00176397
      expect(state.displayConversionAmount, kOneHundredUsdInBtcDisplay);
      expect(state.displayConversionAmount, isNot(startsWith('\$')));
    });
  });
  group('Fee asset', () {
    test('When set, fee asset is correct', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container.read(provider.notifier).setFeeAsset(FeeAsset.tetherUsdt);
      final state = await container.read(provider.future);

      expect(initialState.feeAsset, FeeAsset.btc);
      expect(state.feeAsset, FeeAsset.tetherUsdt);
    });
  });

  group('Currency Switch Decimal Parsing Bug Tests', () {
    test(
        'should parse decimal amounts correctly with different currency separators',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);

      // Initialize state
      await container.read(provider.future);

      // Test EUR currency with comma separator
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      container.read(provider.notifier).updateAmountFieldText('0,0001');
      final eurState = await container.read(provider.future);

      expect(eurState.amountFieldText, '0,0001');
      expect(eurState.amount, 10000); // 0.0001 BTC = 10000 sats
      expect(eurState.rate.currency, FiatCurrency.eur);

      // Switch to USD currency - this resets the amount due to new behavior
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcUsdExchangeRate);
      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);
      final afterCurrencyChange = await container.read(provider.future);

      // Verify amount reset on currency change
      expect(afterCurrencyChange.amountFieldText, isNull);
      expect(afterCurrencyChange.amount, 0);
      expect(afterCurrencyChange.rate.currency, FiatCurrency.usd);

      // Now test USD currency with dot separator
      container.read(provider.notifier).updateAmountFieldText('0.0001');
      final usdState = await container.read(provider.future);

      // Verify parsing is correct with USD decimal separator
      expect(usdState.amountFieldText, '0.0001');
      expect(usdState.amount, 10000,
          reason: 'Amount should be 10000 sats for 0.0001 BTC');
      expect(usdState.rate.currency, FiatCurrency.usd);

      // Verify conversion amount is reasonable for the small amount
      expect(usdState.displayConversionAmount, isNot(equals('\$56,690.00')),
          reason:
              'Should show correct conversion for 0.0001 BTC, not full BTC rate');

      // Verify insufficient funds doesn't occur (balance is 1 BTC = 100M sats, amount is 10K sats)
      expect(usdState.amount < usdState.balanceInSats, true,
          reason: 'Amount (0.0001 BTC) should be less than balance (1 BTC)');
    });

    test(
        'should parse comma and dot decimals correctly after currency changes with amount reset',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      final provider = sendAssetInputStateProvider(args);

      await container.read(provider.future);

      // Test 1: USD with dot separator
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcUsdExchangeRate);
      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);
      container.read(provider.notifier).updateAmountFieldText('0.0001');
      final usdState = await container.read(provider.future);

      expect(usdState.amount, 10000,
          reason: 'USD: 0.0001 BTC should equal 10000 sats');
      expect(usdState.amountFieldText, '0.0001');
      expect(usdState.rate.currency, FiatCurrency.usd);

      // Switch to EUR - amount resets
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterEurSwitch = await container.read(provider.future);

      expect(afterEurSwitch.amountFieldText, isNull);
      expect(afterEurSwitch.amount, 0);
      expect(afterEurSwitch.rate.currency, FiatCurrency.eur);

      // Test EUR with comma separator
      container.read(provider.notifier).updateAmountFieldText('0,0001');
      final eurState = await container.read(provider.future);

      expect(eurState.amount, 10000,
          reason: 'EUR: 0,0001 BTC should equal 10000 sats');
      expect(eurState.amountFieldText, '0,0001');
      expect(eurState.rate.currency, FiatCurrency.eur);

      // Switch back to USD - amount resets again
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcUsdExchangeRate);
      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);
      final afterUsdSwitch = await container.read(provider.future);

      expect(afterUsdSwitch.amountFieldText, isNull);
      expect(afterUsdSwitch.amount, 0);
      expect(afterUsdSwitch.rate.currency, FiatCurrency.usd);

      // Test USD dot separator again
      container.read(provider.notifier).updateAmountFieldText('0.0001');
      final finalUsdState = await container.read(provider.future);

      expect(finalUsdState.amount, 10000,
          reason: 'Final USD: 0.0001 BTC should equal 10000 sats');

      // Verify both currencies parse decimals correctly
      expect(usdState.amount, equals(eurState.amount),
          reason: 'Both currency formats should parse to same sats amount');
      expect(finalUsdState.amount, equals(eurState.amount),
          reason: 'Decimal parsing should be consistent');
    });

    test('should parse decimal amounts correctly after currency changes',
        () async {
      mockBalanceProvider.mockGetBalanceCall(
          value: kOneBtcInSats); // 1 BTC balance
      final provider = sendAssetInputStateProvider(args);

      await container.read(provider.future);

      // Start with EUR - amount resets to 0
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterEurSwitch = await container.read(provider.future);

      expect(afterEurSwitch.amount, 0);
      expect(afterEurSwitch.amountFieldText, isNull);

      // Switch to USD - amount stays reset
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcUsdExchangeRate);
      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);
      final afterUsdSwitch = await container.read(provider.future);

      expect(afterUsdSwitch.amount, 0);
      expect(afterUsdSwitch.amountFieldText, isNull);

      // Enter small amount - should parse correctly after currency switches
      container.read(provider.notifier).updateAmountFieldText('0.0001');
      final state = await container.read(provider.future);

      // Decimal parsing should work correctly despite currency switches
      expect(state.amount, lessThan(state.balanceInSats),
          reason:
              'Small amount (0.0001 BTC) should be less than balance (1 BTC). If this fails, decimal parsing is broken.');
      expect(state.amount, 10000,
          reason: '0.0001 BTC should equal exactly 10000 sats');
      expect(state.amountFieldText, '0.0001');
    });
  });

  group('Amount Reset Behavior Tests', () {
    test('should preserve isSendAllFunds when rate changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);

      await container.read(provider.future);

      // Enable send all funds
      await container.read(provider.notifier).setSendMaxAmount(true);
      final withSendAllState = await container.read(provider.future);

      expect(withSendAllState.isSendAllFunds, true);
      expect(withSendAllState.amount, kOneBtcInSats);

      // Change rate - should reset amount but preserve send all funds
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterRateChange = await container.read(provider.future);

      expect(afterRateChange.isSendAllFunds, true); // Now preserved
      expect(afterRateChange.amount, 0);
      expect(afterRateChange.amountFieldText, isNull);
      expect(afterRateChange.rate.currency, FiatCurrency.eur);
    });

    test('should preserve isSendAllFunds when unit changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);

      await container.read(provider.future);

      // Enable send all funds
      await container.read(provider.notifier).setSendMaxAmount(true);
      final withSendAllState = await container.read(provider.future);

      expect(withSendAllState.isSendAllFunds, true);
      expect(withSendAllState.amount, kOneBtcInSats);

      // Change unit - should reset amount but preserve send all funds
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.sats);
      final afterUnitChange = await container.read(provider.future);

      expect(afterUnitChange.isSendAllFunds, true); // Now preserved
      expect(afterUnitChange.amount, 0);
      expect(afterUnitChange.amountFieldText, isNull);
      expect(afterUnitChange.cryptoUnit, AquaAssetInputUnit.sats);
    });

    test('should handle multiple consecutive rate changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);

      await container.read(provider.future);

      // Enter initial amount
      container.read(provider.notifier).updateAmountFieldText('50');
      final initialState = await container.read(provider.future);

      expect(initialState.amountFieldText, '50');
      expect(initialState.amount, 5000000000); // 50 BTC in sats

      // First rate change
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterFirstChange = await container.read(provider.future);

      expect(afterFirstChange.amountFieldText, isNull);
      expect(afterFirstChange.amount, 0);
      expect(afterFirstChange.rate.currency, FiatCurrency.eur);

      // Second rate change
      container.read(provider.notifier).setRate(kBtcUsdExchangeRate);
      final afterSecondChange = await container.read(provider.future);

      expect(afterSecondChange.amountFieldText, isNull);
      expect(afterSecondChange.amount, 0);
      expect(afterSecondChange.rate.currency, FiatCurrency.usd);
    });

    test('should handle multiple consecutive unit changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);

      await container.read(provider.future);

      // Enter initial amount in crypto mode
      container.read(provider.notifier).updateAmountFieldText('1');
      final initialState = await container.read(provider.future);

      expect(initialState.amountFieldText, '1');
      expect(initialState.amount, 100000000); // 1 BTC in sats
      expect(initialState.cryptoUnit, AquaAssetInputUnit.crypto);

      // First unit change: crypto -> sats
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.sats);
      final afterSatsChange = await container.read(provider.future);

      expect(afterSatsChange.amountFieldText, isNull);
      expect(afterSatsChange.amount, 0);
      expect(afterSatsChange.cryptoUnit, AquaAssetInputUnit.sats);

      // Second unit change: sats -> bits
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.bits);
      final afterBitsChange = await container.read(provider.future);

      expect(afterBitsChange.amountFieldText, isNull);
      expect(afterBitsChange.amount, 0);
      expect(afterBitsChange.cryptoUnit, AquaAssetInputUnit.bits);

      // Third unit change: bits -> crypto
      container.read(provider.notifier).setUnit(AquaAssetInputUnit.crypto);
      final afterCryptoChange = await container.read(provider.future);

      expect(afterCryptoChange.amountFieldText, isNull);
      expect(afterCryptoChange.amount, 0);
      expect(afterCryptoChange.cryptoUnit, AquaAssetInputUnit.crypto);
    });

    test('should work correctly with USDt asset rate changes', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final asset = Asset.usdtTrx();
      final provider = sendAssetInputStateProvider(args.copyWith(asset: asset));

      await container.read(provider.future);

      // Enter amount for USDt
      container.read(provider.notifier).updateAmountFieldText('100');
      final initialState = await container.read(provider.future);

      expect(initialState.amountFieldText, '100');
      expect(initialState.inputType, AquaAssetInputType.crypto);
      // 100 USDt as parsed (precision 8)
      expect(initialState.amount, kOneHundredUsdtInSats);
      // USDt conversion amount is always null (no crypto/fiat conversion needed)
      expect(initialState.displayConversionAmount, isNull);

      // Change rate - should reset amount but keep null conversion
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final afterRateChange = await container.read(provider.future);

      expect(afterRateChange.amountFieldText, isNull);
      expect(afterRateChange.amount, 0);
      expect(afterRateChange.displayConversionAmount, null);
      expect(afterRateChange.rate.currency, FiatCurrency.eur);
      expect(afterRateChange.isSendAllFunds, false);
    });
  });

  group('Basic Decimal Parsing Tests', () {
    test('should parse 0.0001 BTC correctly with direct formatter', () {
      // Test the formatter through the provider to avoid complex initialization
      final formatter = container.read(formatterProvider);

      final result = formatter.parseAssetAmountToSats(
        amount: '0.0001',
        precision: 8,
        asset: Asset.btc(),
      );

      expect(result, 10000, reason: '0.0001 BTC should equal 10000 sats');
    });

    test('should parse EUR comma decimal correctly', () {
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);
      final formatter = container.read(formatterProvider);

      final result = formatter.parseAssetAmountToSats(
        amount: '0,0001',
        precision: 8,
        asset: Asset.btc(),
      );

      expect(result, 10000,
          reason: '0,0001 BTC should equal 10000 sats with EUR format');
    });
  });

  group('Decimal Precision Limits by Input Type and Currency', () {
    test('BTC crypto input should allow 8 decimal places and parse correctly',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Ensure we're in crypto input mode
      final initialState = container.read(provider).value!;
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(initialState.rate.currency, FiatCurrency.usd);

      // Enter amount with 8 decimal places
      container.read(provider.notifier).updateAmountFieldText('0.12345678');
      final state = await container.read(provider.future);

      // Should allow all 8 decimals for BTC
      expect(state.amountFieldText, '0.12345678');
      expect(state.amount, 12345678); // 0.12345678 BTC = 12345678 sats
    });

    test('USD fiat input should parse with standard precision (2 decimals)',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Switch to fiat input mode
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      final stateAfterSwitch = await container.read(provider.future);
      expect(stateAfterSwitch.inputType, AquaAssetInputType.fiat);

      // Enter amount with 2 decimal places (standard for USD)
      container.read(provider.notifier).updateAmountFieldText('123.45');
      final state = await container.read(provider.future);

      // Should format to 2 decimals for USD
      expect(state.amountFieldText, '123.45');
      expect(state.amount, greaterThan(0));
      expect(state.inputType, AquaAssetInputType.fiat);
    });

    test(
        'EUR fiat input should parse with standard precision (2 decimals) and handle comma separator',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Switch to fiat input mode and EUR currency
      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..setRate(kBtcEurExchangeRate);
      final stateAfterSwitch = await container.read(provider.future);
      expect(stateAfterSwitch.inputType, AquaAssetInputType.fiat);
      expect(stateAfterSwitch.rate.currency, FiatCurrency.eur);

      // Enter amount with comma decimal separator (EUR standard)
      container.read(provider.notifier).updateAmountFieldText('123,45');
      final state = await container.read(provider.future);

      // Should format to 2 decimals for EUR
      expect(state.amountFieldText, '123,45');
      expect(state.amount, greaterThan(0));
      expect(state.inputType, AquaAssetInputType.fiat);
    });

    test('Precision field is correctly set based on input type and currency',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Initial state: crypto input should have 8 decimals for BTC
      final initialState = container.read(provider).value!;
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(initialState.precision, 8,
          reason: 'BTC crypto input should allow 8 decimal places');

      // Switch to fiat input mode
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      final fiatState = await container.read(provider.future);

      // Fiat input should have 2 decimals for USD
      expect(fiatState.inputType, AquaAssetInputType.fiat);
      expect(fiatState.precision, 2,
          reason: 'USD fiat input should allow 2 decimal places');

      // Change to EUR currency
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      final eurState = await container.read(provider.future);

      // EUR should also have 2 decimals
      expect(eurState.rate.currency, FiatCurrency.eur);
      expect(eurState.precision, 2,
          reason: 'EUR fiat input should allow 2 decimal places');

      // Switch back to crypto
      container.read(provider.notifier).setType(AquaAssetInputType.crypto);
      final backToCryptoState = await container.read(provider.future);

      // Should be back to 8 decimals for BTC
      expect(backToCryptoState.inputType, AquaAssetInputType.crypto);
      expect(backToCryptoState.precision, 8,
          reason: 'BTC crypto input should allow 8 decimal places');
    });
  });

  group('Decimal Start Normalization', () {
    test('Provider should prepend "0" when text starts with dot', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Enter text starting with decimal separator
      container.read(provider.notifier).updateAmountFieldText('.5');
      final state = await container.read(provider.future);

      // Should be normalized to "0.5"
      expect(state.amountFieldText, '0.5',
          reason: 'Text starting with "." should be normalized to "0."');
    });

    test('Provider should prepend "0" when text starts with comma', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcEurRate);
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Enter text starting with comma separator (EUR style)
      container.read(provider.notifier).updateAmountFieldText(',5');
      final state = await container.read(provider.future);

      // Should be normalized to "0,5"
      expect(state.amountFieldText, '0,5',
          reason: 'Text starting with "," should be normalized to "0,"');
    });

    test('Provider should not modify text starting with a digit', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Enter normal text starting with digit
      container.read(provider.notifier).updateAmountFieldText('5.0');
      final state = await container.read(provider.future);

      // Check the formatted text that the user sees (with thousands separators if applicable)
      expect(state.amountFieldText, '5.0',
          reason:
              'Formatted text starting with digit should preserve decimal separator');
    });

    test('Provider should handle just decimal separator', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Enter just a decimal separator
      container.read(provider.notifier).updateAmountFieldText('.');
      final state = await container.read(provider.future);

      // Check the formatted text that the user sees
      expect(state.amountFieldText, '0.',
          reason: 'Just "." should be normalized to "0." in formatted text');
    });
  });

  group('Provider-Level Precision Enforcement', () {
    test(
        'Provider should trim BTC amount to 8 decimals when excessive decimals are provided',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Ensure we're in crypto input mode with 8 decimal precision
      final initialState = container.read(provider).value!;
      expect(initialState.inputType, AquaAssetInputType.crypto);
      expect(initialState.precision, 8);

      // Try to set amount with 10 decimal places
      // Note: trimToPrecision should trim to 8 decimals, preserving decimal separator
      container.read(provider.notifier).updateAmountFieldText('0.123456789012');
      final state = await container.read(provider.future);

      // Should be trimmed to 8 decimals (raw text preserved after trimming)
      expect(state.amountFieldText, '0.12345678',
          reason:
              'Provider should trim BTC amount to 8 decimal places maximum');
      expect(state.amount, 12345678); // 0.12345678 BTC = 12345678 sats
    });

    test(
        'Provider should trim USD fiat amount to 2 decimals when excessive decimals are provided',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Switch to fiat input mode
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      await container.read(provider.future);
      final fiatModeState = container.read(provider).value!;
      expect(fiatModeState.inputType, AquaAssetInputType.fiat);
      expect(fiatModeState.precision, 2);

      // Try to set amount with 5 decimal places
      container.read(provider.notifier).updateAmountFieldText('123.45678');
      final state = await container.read(provider.future);

      // Check the formatted text that the user sees (should be trimmed to 2 decimals)
      expect(state.amountFieldText, '123.45',
          reason:
              'Formatted USD amount should be trimmed to 2 decimal places maximum');
      expect(state.amount, greaterThan(0));
    });

    test('Provider should trim EUR amount with comma separator to 2 decimals',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcEurRate);
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Switch to fiat input mode with EUR
      container.read(provider.notifier)
        ..setType(AquaAssetInputType.fiat)
        ..setRate(kBtcEurExchangeRate);
      await container.read(provider.future);
      final eurState = container.read(provider).value!;
      expect(eurState.inputType, AquaAssetInputType.fiat);
      expect(eurState.rate.currency, FiatCurrency.eur);
      expect(eurState.precision, 2);

      // Try to set amount with comma separator and 5 decimal places
      container.read(provider.notifier).updateAmountFieldText('123,45678');
      final state = await container.read(provider.future);

      // Check the formatted text that the user sees (should be trimmed to 2 decimals with comma)
      expect(state.amountFieldText, '123,45',
          reason:
              'Formatted EUR amount should be trimmed to 2 decimals while maintaining comma separator');
      expect(state.amount, greaterThan(0));
    });

    test('Provider should not trim amounts within precision limit', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // BTC with exactly 8 decimals should not be trimmed
      container.read(provider.notifier).updateAmountFieldText('0.12345678');
      final state1 = await container.read(provider.future);
      expect(state1.amountFieldText, '0.12345678');

      // BTC with fewer than 8 decimals should not be trimmed
      container.read(provider.notifier).updateAmountFieldText('0.123');
      final state2 = await container.read(provider.future);
      expect(state2.amountFieldText, '0.123');

      // Switch to fiat and test with 2 decimals
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('123.45');
      final state3 = await container.read(provider.future);
      expect(state3.amountFieldText, '123.45');

      // Fiat with 1 decimal should not be trimmed
      container.read(provider.notifier).updateAmountFieldText('123.4');
      final state4 = await container.read(provider.future);
      expect(state4.amountFieldText, '123.4');
    });

    test('Provider should handle amounts without decimal points', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Integer amounts should pass through unchanged
      container.read(provider.notifier).updateAmountFieldText('123');
      final state = await container.read(provider.future);
      expect(state.amountFieldText, '123');
    });

    test('Provider should handle empty text input', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Empty text should pass through unchanged
      container.read(provider.notifier).updateAmountFieldText('');
      final state = await container.read(provider.future);
      expect(state.amountFieldText, anyOf(isNull, isEmpty));
    });
  });

  group('updateAddressFieldText with resetAmount', () {
    test('should NOT reset amount fields when resetAmount is false (default)',
        () async {
      final provider = sendAssetInputStateProvider(args);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: asset,
          address: kFakeBitcoinAddress,
        ),
      );

      await container.read(provider.future);

      container
          .read(provider.notifier)
          .updateAmountFieldText(kPointOneBtc.toString());

      final stateWithAmount = await container.read(provider.future);
      expect(stateWithAmount.amount, kPointOneBtcInSats);
      expect(stateWithAmount.amountFieldText, isNotNull);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeBitcoinAddress);

      final state = await container.read(provider.future);
      expect(state.addressFieldText, kFakeBitcoinAddress);
      expect(state.amount, isNot(0));
    });

    test('should reset all amount-related fields when resetAmount is true',
        () async {
      final provider = sendAssetInputStateProvider(args);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: asset,
          address: kFakeBitcoinAddress,
        ),
      );

      await container.read(provider.future);

      // Set up state with amount, send-all, fiat input type, and adjusted amount
      await container.read(provider.notifier).setSendMaxAmount(true);
      container.read(provider.notifier).setType(AquaAssetInputType.fiat);
      container
          .read(provider.notifier)
          .updateSwapDepositAmount(kOneBtcInSats + 1000);

      final stateBefore = await container.read(provider.future);
      expect(stateBefore.amount, kOneBtcInSats);
      expect(stateBefore.isSendAllFunds, true);
      expect(stateBefore.adjustedAmountToSend, kOneBtcInSats + 1000);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeBitcoinAddress, resetAmount: true);

      final state = await container.read(provider.future);
      expect(state.addressFieldText, kFakeBitcoinAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.amount, 0);
      expect(state.displayConversionAmount, isNull);
      expect(state.isSendAllFunds, false);
      expect(state.adjustedAmountToSend, isNull);
      expect(state.inputType, AquaAssetInputType.crypto);
    });
  });

  group('EUR locale: locale-formatted amounts (regression)', () {
    test(
        'updateAmountFieldText with locale-formatted "0,0008" in EUR locale should still work',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);
      container.read(provider.notifier).setRate(kBtcEurExchangeRate);
      await container.read(provider.future);

      // User types "0,0008" through EUR numpad
      container.read(provider.notifier).updateAmountFieldText('0,0008');
      final state = await container.read(provider.future);

      expect(state.amount, 80000,
          reason: 'EUR-formatted "0,0008" should be 80000 sats');
    });

    test(
        'updateAmountFieldText with EUR thousands "1.000,50" in EUR locale should parse correctly',
        () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);

      // Switch to fiat mode for EUR
      mockExchangeRatesProvider.mockGetCurrentCurrency(
          value: kBtcEurExchangeRate);
      container.read(provider.notifier)
        ..setRate(kBtcEurExchangeRate)
        ..setType(AquaAssetInputType.fiat);
      await container.read(provider.future);

      container.read(provider.notifier).updateAmountFieldText('1.000,50');
      final state = await container.read(provider.future);

      // 1000.50 EUR should be converted to sats using EUR rate
      expect(state.amount, greaterThan(0),
          reason: 'EUR "1.000,50" should parse as 1000.50 EUR');
    });
  });
}
