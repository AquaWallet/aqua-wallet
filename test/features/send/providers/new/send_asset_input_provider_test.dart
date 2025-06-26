import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';

const kFakeContent = 'test content';
const kFakeBitcoinAddress = 'fake-bitcoin-address';
const kFakeEthereumAddress = 'fake-ethereum-address';
const kFakeLiquidAddress = 'fake-liquid-address';
const kFakeLiquidUsdtAddress = 'fake-liquid-usdt-address';
const kFakeLanguageCode = 'en_US';
const kFakeLightningInvoice = 'fake-lightning-invoice';
const kPointOneBtc = 0.1;
const kPointOneBtcInSats = 10000000;
const kOneBtc = 1;
const kOneBtcInSats = 100000000;
const kBtcUsdRate = 56690;
const kBtcUsdRateStr = '56,690.00';
const kBtcUsdRateSats = kBtcUsdRate / kOneBtcInSats;
const kOneHundredUsdInBtcSats = 176397;
const kOneHundredUsdInBtc = 0.00176397;
const kUsdCurrency = 'USD';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final asset = Asset.btc();
  final args = SendAssetArguments.fromAsset(asset);
  final mockAddressParser = MockAddressParserProvider();
  final mockManageAssetsProvider = MockManageAssetsProvider();
  final mockBitcoinProvider = MockBitcoinProvider();
  final mockBalanceProvider = MockBalanceProvider();
  final mockPrefsProvider = MockPrefsProvider();
  final container = ProviderContainer(overrides: [
    clipboardContentProvider.overrideWith((_) => Future.value(null)),
    addressParserProvider.overrideWith((_) => mockAddressParser),
    manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
    bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
    balanceProvider.overrideWith((_) => mockBalanceProvider),
    prefsProvider.overrideWith((_) => mockPrefsProvider),
  ]);

  setUpAll(() {
    registerFallbackValue(asset);
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
      expect(state.balanceDisplay, kOneHundredUsdInBtc.toString());
      expect(state.balanceFiatDisplay, '$kUsdCurrency 100.00');
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

      expect(state.amountConversionDisplay, null);
    });
    test('Initial state amount input is fiat', () async {
      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.amountInputType, CryptoAmountInputType.crypto);
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
  });

  group('Initialize with arguments', () {
    test('Inital state address text field is NOT empty', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.btc(asset).copyWith(
        input: kFakeBitcoinAddress,
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

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.asset.id, asset.id);
      expect(state.amountInputType, CryptoAmountInputType.crypto);
      expect(state.amountFieldText, cryptoDecimalAmount.toString());
      expect(state.isAmountFieldEmpty, false);
    });
    test('Inital state converted crypto amount is NOT empty', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.btc(asset).copyWith(
        input: kFakeBitcoinAddress,
        userEnteredAmount: Decimal.parse(kPointOneBtc.toString()),
      );

      final state =
          await container.read(sendAssetInputStateProvider(args).future);

      expect(state.amount, kPointOneBtcInSats);
      expect(state.amountConversionDisplay, "$kUsdCurrency 5,669.00");
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
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amount: Decimal.fromInt(kFakeAmount),
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
      expect(state.amountFieldText, kFakeAmount.toString());
      expect(state.isAmountEditable, isFalse);
    });
    test('amount is NOT empty when pasted address has amount', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      final otherAsset = Asset.lightning();
      const kFakeAmount = 150;
      final container = ProviderContainer(overrides: [
        clipboardContentProvider
            .overrideWith((_) => Future.value(kFakeLiquidAddress)),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockAddressParser.mockIsValidAddressForAssetCall(value: true);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amount: Decimal.fromInt(kFakeAmount),
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
      expect(state.amountFieldText, kFakeAmount.toString());
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
      final otherAsset = Asset.btc();
      const kFakeOriginalAmount = 100;
      const kFakeLnUrlAmount = 200;
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => null),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amount: Decimal.fromInt(kFakeOriginalAmount),
          lnurlParseResult: LNURLParseResult(
            payParams: LNURLPayParams(
              minSendable: kFakeLnUrlAmount * 1000,
              maxSendable: kFakeLnUrlAmount * 1000,
            ),
          ),
        ),
      );

      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);
      expect(initialState.amount, 0);

      await container
          .read(provider.notifier)
          .updateAddressFieldText(kFakeContent);

      final state = await container.read(provider.future);
      expect(state.asset.id, otherAsset.id);
      expect(state.clipboardAddress, isNull);
      expect(state.isClipboardEmpty, true);
      expect(state.addressFieldText, kFakeLiquidAddress);
      expect(state.isAddressFieldEmpty, false);
      expect(state.isLnurl, true);
      expect(state.lnurlData, isNotNull);
      expect(state.lnurlData?.payParams?.isFixedAmount, true);
      expect(state.amount, kFakeLnUrlAmount);
      expect(state.isAmountEditable, isFalse);
    });
    test('use params when scanned QR code is BIP21 BTC Invoice', () async {
      final asset = Asset.lightning();
      final args = SendAssetArguments.fromAsset(asset);
      const kInvoiceAddress = 'BC1234567890';
      const kInvoiceAmount = 1000;
      const kInvoiceAmountFiat = (kBtcUsdRate * kInvoiceAmount) / satsPerBtc;
      const kInvoiceLabel = 'Invoice Label';
      const kInvoiceMessage = 'Invoice Message';
      const kInvoiceLightningAddress = 'lnbc100xxx';
      const kFakeBtcBip21Url = 'bitcoin:$kInvoiceAddress?'
          'amount=$kInvoiceAmount&'
          'label=$kInvoiceLabel&'
          'message=$kInvoiceMessage&'
          'lightning=$kInvoiceLightningAddress';
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => null),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
      ]);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          address: kInvoiceAddress,
          amount: Decimal.fromInt(kInvoiceAmount),
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
      expect(state.amountFieldText, kInvoiceAmount.toString());
      expect(
        state.amountConversionDisplay,
        '$kUsdCurrency ${kInvoiceAmountFiat.toStringAsFixed(2)}',
      );
      expect(state.isAmountEditable, isFalse);
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
      expect(state.isAmountEditable, isFalse);
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
      expect(state.isAmountEditable, isTrue);
    });
  });

  group('Clipboard', () {
    final container = ProviderContainer(overrides: [
      clipboardContentProvider.overrideWith((_) => kFakeContent),
      addressParserProvider.overrideWith((_) => mockAddressParser),
      bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
      balanceProvider.overrideWith((_) => mockBalanceProvider),
      prefsProvider.overrideWith((_) => mockPrefsProvider),
    ]);

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
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => kFakeBitcoinAddress),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
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
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => null),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
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
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => null),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
      mockManageAssetsProvider.mockIsNonLbtcLiquidToLbtcCall(value: false);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amount: Decimal.fromInt(kFakeAmount),
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
      final otherAsset = Asset.btc();
      const kFakeOriginalAmount = 100;
      const kFakeLnUrlAmount = 200;
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => null),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amount: Decimal.fromInt(kFakeOriginalAmount),
          lnurlParseResult: LNURLParseResult(
            payParams: LNURLPayParams(
              minSendable: kFakeLnUrlAmount * 1000,
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
      expect(state.lnurlData?.payParams?.isFixedAmount, true);
      expect(state.amount, kFakeLnUrlAmount);
      expect(state.isAmountEditable, isFalse);
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
      expect(state.isAmountEditable, isFalse);
    });
  });

  group('Asset switching', () {
    test('keep asset when an address from the same asset is found', () async {
      final asset = Asset.btc();
      final args = SendAssetArguments.fromAsset(asset);
      const kOtherAssetName = 'Same Asset with Different Name';
      final otherAsset = asset.copyWith(name: kOtherAssetName);
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => kFakeBitcoinAddress),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
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

      await container
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

        container
            .read(provider.notifier)
            .setInputType(CryptoAmountInputType.crypto);
        await container
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

        container
            .read(provider.notifier)
            .setInputType(CryptoAmountInputType.fiat);
        await container.read(provider.notifier).updateAmountFieldText('100');

        // Based on the mocked rate: 100 USD = 0.0017639795 BTC
        final state = await container.read(provider.future);
        expect(initialState.amount, 0);
        expect(state.amount, kOneHundredUsdInBtcSats);
        expect(state.amountFieldText, '100');
      },
    );
    test('When input type changed, amount should reset', () async {
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);
      await container
          .read(provider.notifier)
          .updateAmountFieldText(kPointOneBtc.toString());
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .setInputType(CryptoAmountInputType.fiat);

      final state = await container.read(provider.future);
      expect(initialState.amount, kPointOneBtcInSats);
      expect(initialState.amountFieldText, kPointOneBtc.toString());
      expect(initialState.amountInputType, CryptoAmountInputType.crypto);
      expect(state.amount, 0);
      expect(state.amountFieldText, null);
      expect(state.amountInputType, CryptoAmountInputType.fiat);
    });
    test('When input type changed, send max should reset', () async {
      final provider = sendAssetInputStateProvider(args);
      await container.read(provider.future);
      await container.read(provider.notifier).setSendMaxAmount(true);
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .setInputType(CryptoAmountInputType.fiat);

      final state = await container.read(provider.future);
      expect(initialState.amount, kOneBtcInSats);
      expect(initialState.amountFieldText, kOneBtc.toString());
      expect(initialState.amountInputType, CryptoAmountInputType.crypto);
      expect(initialState.isSendAllFunds, true);
      expect(state.amount, 0);
      expect(state.amountFieldText, null);
      expect(state.amountInputType, CryptoAmountInputType.fiat);
      expect(state.isSendAllFunds, false);
    });
    test('When send all crypto, entire balance is used for amount', () async {
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .setInputType(CryptoAmountInputType.crypto);
      await container.read(provider.notifier).setSendMaxAmount(true);

      final state = await container.read(provider.future);
      expect(initialState.isSendAllFunds, false);
      expect(initialState.amount, 0);
      expect(initialState.amountFieldText, null);
      expect(initialState.amountInputType, CryptoAmountInputType.crypto);
      expect(state.isSendAllFunds, true);
      expect(state.amount, kOneBtcInSats);
      expect(state.amountFieldText, kOneBtc.toString());
      expect(state.amountInputType, CryptoAmountInputType.crypto);
      expect(state.amountConversionDisplay, '$kUsdCurrency $kBtcUsdRateStr');
    });
    test('When send all fiat, entire balance is used for amount', () async {
      mockBalanceProvider.mockGetBalanceCall(value: kOneHundredUsdInBtcSats);
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .setInputType(CryptoAmountInputType.fiat);
      await container.read(provider.notifier).setSendMaxAmount(true);

      final state = await container.read(provider.future);
      expect(initialState.isSendAllFunds, false);
      expect(initialState.amount, 0);
      expect(initialState.amountFieldText, null);
      expect(initialState.amountInputType, CryptoAmountInputType.crypto);
      expect(state.isSendAllFunds, true);
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.amountFieldText, '100.00');
      expect(state.amountInputType, CryptoAmountInputType.fiat);
    });
    test('When amount is zero, converted amount is null', () async {
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container.read(provider.notifier).updateAmountFieldText('0');

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountConversionDisplay, null);
      expect(state.amount, 0);
      expect(state.amountConversionDisplay, null);
    });
    test('When non-zero crypto amount, converted amount is NOT null', () async {
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      await container
          .read(provider.notifier)
          .updateAmountFieldText(kOneHundredUsdInBtc.toString());

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountConversionDisplay, null);
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.amountConversionDisplay, '$kUsdCurrency 100.00');
    });
    test('When non-zero fiat amount, converted amount is NOT null', () async {
      final provider = sendAssetInputStateProvider(args);
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .setInputType(CryptoAmountInputType.fiat);
      await container.read(provider.notifier).updateAmountFieldText('100.00');

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountConversionDisplay, null);
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.amountConversionDisplay, kOneHundredUsdInBtc.toString());
    });
    test('When USDt fiat amount, converted amount is null', () async {
      final asset = Asset.usdtTrx();
      final provider = sendAssetInputStateProvider(args.copyWith(asset: asset));
      final initialState = await container.read(provider.future);

      container
          .read(provider.notifier)
          .setInputType(CryptoAmountInputType.fiat);
      await container.read(provider.notifier).updateAmountFieldText('100.00');

      final state = await container.read(provider.future);

      expect(initialState.amount, 0);
      expect(initialState.amountConversionDisplay, null);
      expect(state.amount, kOneHundredUsdInBtcSats);
      expect(state.amountConversionDisplay, null);
    });

    test('Amount is editable when LNURL param amount is NOT fixed', () async {
      final otherAsset = Asset.lightning();
      const kFakeOriginalAmount = 100;
      const kFakeLnUrlAmount = 200;
      final container = ProviderContainer(overrides: [
        clipboardContentProvider.overrideWith((_) => null),
        addressParserProvider.overrideWith((_) => mockAddressParser),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
      ]);
      mockAddressParser.mockParseInputCall(
        value: ParsedAddress(
          asset: otherAsset,
          address: kFakeLiquidAddress,
          amount: Decimal.fromInt(kFakeOriginalAmount),
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
}
