import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';
import 'send_asset_input_provider_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final asset = Asset.unknown();

  setUpAll(() {
    registerFallbackValue(asset);
  });

  test('throws unimplemented error on unknown fee structure type', () async {
    final args = SendAssetArguments.fromAsset(asset);
    final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
      input: SendAssetInputState(
        asset: asset,
        amount: 0,
      ),
    );
    final mocksendAssetTxnProvider = MockSendAssetTxnProvider(
      transaction: const SendAssetOnchainTx.gdkTx(
        GdkNewTransactionReply(fee: 1000),
      ),
    );

    final container = ProviderContainer(overrides: [
      sendAssetInputStateProvider
          .overrideWith(() => mockSendAssetInputStateNotifier),
      sendAssetTxnProvider.overrideWith(() => mocksendAssetTxnProvider),
    ]);

    expect(
      expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
      throwsUnimplementedError,
    );
  });

  group('L-BTC Send', () {
    final asset = Asset.liquidTest().copyWith(isLBTC: true);
    final args = SendAssetArguments.fromAsset(asset);
    final mockManageAssetsProvider = MockManageAssetsProvider();
    final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
      input: SendAssetInputState(asset: asset),
    );

    final container = ProviderContainer(overrides: [
      sendAssetInputStateProvider
          .overrideWith(() => mockSendAssetInputStateNotifier),
      manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
    ]);
    mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

    test('throws FeeTransactionNotFoundError when send txn is null', () async {
      final provider = sendAssetFeeProvider(args);

      expect(
        expectAsync0(() => container.read(provider.future)),
        throwsA(isA<FeeTransactionNotFoundError>()),
      );
    });
    test('throws FeeNotFoundError when send txn fee is null', () async {
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(asset: asset),
      );
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: null),
        ),
      );
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

      expect(
        expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
        throwsA(isA<FeeNotFoundError>()),
      );
    });
    test('returns correct fee structure when fee & txn are present', () async {
      const kFakeFeeRate = 10.0;
      const kFakeFee = 1000;
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: kFakeFee),
        ),
      );
      final mockBalanceProvider = MockBalanceProvider();
      final mockPrefsProvider = MockPrefsProvider();
      final mockBitcoinProvider = MockBitcoinProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
      ]);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidFee>()
            .having((s) => s.estimatedFee, 'estimatedFee', kFakeFee)
            .having((s) => s.feeRate, 'feeRate', kFakeFeeRate * kVbPerKb),
      );
    });
    test(
      'throws FeeAssetMismatchError when fee asset is incompatible',
      () async {
        final asset = Asset.liquidTest().copyWith(isLBTC: true);
        final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
          input: SendAssetInputState(asset: asset, feeAsset: FeeAsset.btc),
        );
        final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
          transaction: const SendAssetOnchainTx.gdkTx(
            GdkNewTransactionReply(fee: 100),
          ),
        );
        final mockManageAssetsProvider = MockManageAssetsProvider();
        final container = ProviderContainer(overrides: [
          manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
          sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
          liquidFeeRateProvider.overrideWith((_) => Future.value(100)),
          sendAssetInputStateProvider
              .overrideWith(() => mockSendAssetInputStateNotifier),
        ]);
        mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

        expect(
          expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
          throwsA(isA<FeeAssetMismatchError>()),
        );
      },
    );
    test('returns correct fee structure when liquid taxi is used', () async {
      const kFakeUserAmountSats = kOneHundredUsdInBtcSats;
      const kFakeTaxiFeeSats = kOneHundredUsdInBtcSats ~/ kOneBtcInSats;
      const kFakeFee = 1000;
      const kFakeFeeRate = 10.0;
      const kFakeUsdRate = 100.0;
      final asset = Asset.liquidTest().copyWith(isLBTC: true);
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(
          asset: asset,
          feeAsset: FeeAsset.tetherUsdt,
          amount: kFakeUserAmountSats,
        ),
      );
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider();
      final mockFiatRatesNotifier = MockFiatRatesNotifier(rates: [
        const BitcoinFiatRatesResponse(
          code: 'USD',
          rate: kFakeUsdRate,
          name: 'US Dollar',
          cryptoCode: 'BTC',
          currencyPair: 'BTCUSD',
        ),
      ]);
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: kFakeFee),
        ),
      );
      final mockPrefsProvider = MockPrefsProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        fiatRatesProvider.overrideWith(() => mockFiatRatesNotifier),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kUsdCurrency);
      mockSideswapTaxiProvider.mockEstimatedTaxiFeeUsdt(kFakeTaxiFeeSats);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidTaxiFee>()
            .having((s) => s.lbtcFeeRate, 'feeRate', kFakeFeeRate * kVbPerKb)
            .having((s) => s.estimatedLbtcFee, 'estimatedLbtcFee', kFakeFee)
            .having((s) => s.usdtFeeRate, 'usdtFeeRate', kFakeUsdRate)
            .having((s) => s.estimatedUsdtFee, 'estimatedUsdtFee',
                kFakeTaxiFeeSats),
      );
    });
  });

  group('Liquid USDt Send', () {
    final asset = Asset.usdtLiquid();
    final args = SendAssetArguments.fromAsset(asset);
    final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
      input: SendAssetInputState(asset: asset),
    );

    test(
        'throws FeeTransactionNotFoundError when send txn is null && Taxi unavailable',
        () async {
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: null,
      );
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider(
        throwError: true,
      );
      final container = ProviderContainer(overrides: [
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);
      final provider = sendAssetFeeProvider(args);

      expect(
        expectAsync0(() => container.read(provider.future)),
        throwsA(isA<FeeTransactionNotFoundError>()),
      );
    });

    test(
        'throws FeeTransactionNotFoundError when send txn is null && USDt disabled',
        () async {
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(asset: asset),
      );
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider();
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: null,
      );
      final container = ProviderContainer(overrides: [
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
      mockSideswapTaxiProvider.mockEstimatedTaxiFeeUsdt(1000);
      final provider = sendAssetFeeProvider(args);

      expect(
        expectAsync0(() => container.read(provider.future)),
        throwsA(isA<FeeTransactionNotFoundError>()),
      );
    });
    test(
        'throws FeeNotFoundError when send txn fee is null && Taxi unavailable',
        () async {
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(asset: asset),
      );
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: null),
        ),
      );
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider(
        throwError: true,
      );
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);

      expect(
        expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
        throwsA(isA<FeeNotFoundError>()),
      );
    });
    test('throws FeeNotFoundError when send txn fee is null && USDt disabled',
        () async {
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(asset: asset),
      );
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: null),
        ),
      );
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
      mockSideswapTaxiProvider.mockEstimatedTaxiFeeUsdt(100);

      expect(
        expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
        throwsA(isA<FeeNotFoundError>()),
      );
    });
    test('returns correct LBTC fee structure when txn is available', () async {
      const kFakeFeeRate = 10.0;
      const kFakeFee = 100;
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: kFakeFee),
        ),
      );
      final mockBalanceProvider = MockBalanceProvider();
      final mockPrefsProvider = MockPrefsProvider();
      final mockBitcoinProvider = MockBitcoinProvider();
      final mockInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(
          asset: asset,
          feeAsset: FeeAsset.lbtc,
        ),
      );
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sendAssetInputStateProvider.overrideWith(() => mockInputStateNotifier),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
      ]);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidFee>()
            .having((s) => s.estimatedFee, 'estimatedFee', kFakeFee)
            .having((s) => s.feeRate, 'feeRate', kFakeFeeRate * kVbPerKb),
      );
    });
    test('returns correct USDT fee structure when taxi is used', () async {
      const kFakeFeeRate = 2.0;
      const kFakeFee = 50;
      const kFakeUsdtTaxiFee = 150;
      const kFakeUsdRate = 100.0;
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: kFakeFee),
        ),
      );
      final mockBalanceProvider = MockBalanceProvider();
      final mockPrefsProvider = MockPrefsProvider();
      final mockBitcoinProvider = MockBitcoinProvider();
      final mockInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(
          asset: asset,
          feeAsset: FeeAsset.tetherUsdt,
        ),
      );
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider();
      final mockFiatRatesNotifier = MockFiatRatesNotifier(rates: [
        const BitcoinFiatRatesResponse(
          code: 'USD',
          rate: kFakeUsdRate,
          name: 'US Dollar',
          cryptoCode: 'BTC',
          currencyPair: 'BTCUSD',
        ),
      ]);
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sendAssetInputStateProvider.overrideWith(() => mockInputStateNotifier),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        fiatRatesProvider.overrideWith(() => mockFiatRatesNotifier),
      ]);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kUsdCurrency);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockSideswapTaxiProvider.mockEstimatedTaxiFeeUsdt(kFakeUsdtTaxiFee);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidTaxiFee>()
            .having((s) => s.estimatedLbtcFee, 'estimatedLbtcFee', kFakeFee)
            .having((s) => s.lbtcFeeRate, 'feeRate', kFakeFeeRate * kVbPerKb)
            .having((s) => s.usdtFeeRate, 'usdtFeeRate', kFakeUsdRate)
            .having(
              (s) => s.estimatedUsdtFee,
              'estimatedUsdtFee',
              kFakeUsdtTaxiFee / satsPerBtc,
            ),
      );
    });
    test('returns correct USDT fee structure when no LBTC balance', () async {
      const kFakeFeeRate = 2.0;
      const kFakeUsdtTaxiCurrency = 'USDT';
      const kFakeUsdtTaxiFee = 150;
      const kFakeUsdRate = 100.0;
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: null,
      );
      final mockBalanceProvider = MockBalanceProvider();
      final mockPrefsProvider = MockPrefsProvider();
      final mockBitcoinProvider = MockBitcoinProvider();
      final mockInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(
          asset: asset,
          feeAsset: FeeAsset.tetherUsdt,
        ),
      );
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider();
      final mockFiatRatesNotifier = MockFiatRatesNotifier(rates: [
        const BitcoinFiatRatesResponse(
          code: 'USD',
          rate: kFakeUsdRate,
          name: 'US Dollar',
          cryptoCode: 'BTC',
          currencyPair: 'BTCUSD',
        ),
      ]);
      final mockSendAssetFeeOptionsNotifier = MockSendAssetFeeOptionsNotifier([
        SendAssetFeeOptionModel.liquid(
          LiquidFeeModel.lbtc(
            availableForFeePayment: false,
            isEnabled: false,
            feeSats: 0,
            feeFiat: 0,
            fiatCurrency: kUsdCurrency,
            fiatFeeDisplay: '0',
            satsPerByte: kVbPerKb.toDouble(),
          ),
        ),
        SendAssetFeeOptionModel.liquid(
          LiquidFeeModel.usdt(
            availableForFeePayment: true,
            isEnabled: true,
            feeAmount: kFakeUsdtTaxiFee,
            feeCurrency: kFakeUsdtTaxiCurrency,
            feeDisplay: (kFakeUsdtTaxiFee / satsPerBtc).toString(),
          ),
        ),
      ]);
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final container = ProviderContainer(overrides: [
        sendAssetInputStateProvider.overrideWith(() => mockInputStateNotifier),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        fiatRatesProvider.overrideWith(() => mockFiatRatesNotifier),
        sendAssetFeeOptionsProvider.overrideWith(
          () => mockSendAssetFeeOptionsNotifier,
        ),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
      ]);
      mockSideswapTaxiProvider.mockEstimatedTaxiFeeUsdt(kFakeUsdtTaxiFee);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kUsdCurrency);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidTaxiFee>()
            .having((s) => s.estimatedLbtcFee, 'estimatedLbtcFee', 0)
            .having((s) => s.lbtcFeeRate, 'feeRate', kFakeFeeRate * kVbPerKb)
            .having((s) => s.usdtFeeRate, 'usdtFeeRate', kFakeUsdRate)
            .having(
              (s) => s.estimatedUsdtFee,
              'estimatedUsdtFee',
              kFakeUsdtTaxiFee / satsPerBtc,
            ),
      );
    });
    test(
      'throws FeeAssetMismatchError when fee asset is incompatible',
      () async {
        final asset = Asset.liquidTest().copyWith(isLBTC: true);
        final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
          input: SendAssetInputState(asset: asset, feeAsset: FeeAsset.btc),
        );
        final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
          transaction: const SendAssetOnchainTx.gdkTx(
            GdkNewTransactionReply(fee: 100),
          ),
        );
        final mockManageAssetsProvider = MockManageAssetsProvider();
        final container = ProviderContainer(overrides: [
          manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
          sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
          liquidFeeRateProvider.overrideWith((_) => Future.value(100)),
          sendAssetInputStateProvider
              .overrideWith(() => mockSendAssetInputStateNotifier),
        ]);
        mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);
        expect(
          expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
          throwsA(isA<FeeAssetMismatchError>()),
        );
      },
    );
    test('returns correct fee structure when liquid taxi is used', () async {
      const kFakeUserAmountSats = kOneHundredUsdInBtcSats;
      const kFakeTaxiFeeSats = kOneHundredUsdInBtcSats ~/ kOneBtcInSats;
      const kFakeFee = 1000;
      const kFakeFeeRate = 10.0;
      const kFakeUsdRate = 100.0;
      final asset = Asset.liquidTest().copyWith(isLBTC: true);
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(
          asset: asset,
          feeAsset: FeeAsset.tetherUsdt,
          amount: kFakeUserAmountSats,
        ),
      );
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider();
      final mockFiatRatesNotifier = MockFiatRatesNotifier(rates: [
        const BitcoinFiatRatesResponse(
          code: 'USD',
          rate: kFakeUsdRate,
          name: 'US Dollar',
          cryptoCode: 'BTC',
          currencyPair: 'BTCUSD',
        ),
      ]);
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: kFakeFee),
        ),
      );
      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        fiatRatesProvider.overrideWith(() => mockFiatRatesNotifier),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kUsdCurrency);
      mockSideswapTaxiProvider.mockEstimatedTaxiFeeUsdt(kFakeTaxiFeeSats);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidTaxiFee>()
            .having((s) => s.lbtcFeeRate, 'feeRate', kFakeFeeRate * kVbPerKb)
            .having((s) => s.estimatedLbtcFee, 'estimatedLbtcFee', kFakeFee)
            .having((s) => s.usdtFeeRate, 'usdtFeeRate', kFakeUsdRate)
            .having((s) => s.estimatedUsdtFee, 'estimatedUsdtFee',
                kFakeTaxiFeeSats),
      );
    });
  });

  group('Lightning Send', () {
    final asset = Asset.lightning();
    final args = SendAssetArguments.fromAsset(asset);
    final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
      input: SendAssetInputState(asset: asset),
    );
    final mockManageAssetsProvider = MockManageAssetsProvider();
    final container = ProviderContainer(overrides: [
      manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
      sendAssetInputStateProvider
          .overrideWith(() => mockSendAssetInputStateNotifier),
    ]);
    mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

    test('throws FeeTransactionNotFoundError when send txn is null', () async {
      final provider = sendAssetFeeProvider(args);

      expect(
        expectAsync0(() => container.read(provider.future)),
        throwsA(isA<FeeTransactionNotFoundError>()),
      );
    });
    test('throws FeeNotFoundError when send txn fee is null', () async {
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(asset: asset),
      );
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: null),
        ),
      );
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

      expect(
        expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
        throwsA(isA<FeeNotFoundError>()),
      );
    });
    test('returns correct fee structure when fee & txn are present', () async {
      const kFakeFeeRate = 10.0;
      const kFakeFee = 1000;
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: kFakeFee),
        ),
      );
      final mockBalanceProvider = MockBalanceProvider();
      final mockPrefsProvider = MockPrefsProvider();
      final mockBitcoinProvider = MockBitcoinProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
      ]);
      mockBalanceProvider.mockGetBalanceCall(value: kOneBtcInSats);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockBitcoinProvider.mockBitcoinRateCall(rate: kBtcUsdRate);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidFee>()
            .having((s) => s.estimatedFee, 'estimatedFee', kFakeFee)
            .having((s) => s.feeRate, 'feeRate', kFakeFeeRate * kVbPerKb),
      );
    });
    test('returns correct fee structure when liquid taxi is used', () async {
      const kFakeUserAmountSats = kOneHundredUsdInBtcSats;
      const kFakeTaxiFeeSats = kOneHundredUsdInBtcSats ~/ kOneBtcInSats;
      const kFakeFee = 1000;
      const kFakeFeeRate = 10.0;
      const kFakeUsdRate = 100.0;
      final asset = Asset.liquidTest().copyWith(isLBTC: true);
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(
          asset: asset,
          feeAsset: FeeAsset.tetherUsdt,
          amount: kFakeUserAmountSats,
        ),
      );
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider();
      final mockFiatRatesNotifier = MockFiatRatesNotifier(rates: [
        const BitcoinFiatRatesResponse(
          code: 'USD',
          rate: kFakeUsdRate,
          name: 'US Dollar',
          cryptoCode: 'BTC',
          currencyPair: 'BTCUSD',
        ),
      ]);
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(fee: kFakeFee),
        ),
      );
      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kFakeFeeRate)),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        fiatRatesProvider.overrideWith(() => mockFiatRatesNotifier),
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kUsdCurrency);
      mockSideswapTaxiProvider.mockEstimatedTaxiFeeUsdt(kFakeTaxiFeeSats);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<LiquidTaxiFee>()
            .having((s) => s.lbtcFeeRate, 'feeRate', kFakeFeeRate * kVbPerKb)
            .having((s) => s.estimatedLbtcFee, 'estimatedLbtcFee', kFakeFee)
            .having((s) => s.usdtFeeRate, 'usdtFeeRate', kFakeUsdRate)
            .having((s) => s.estimatedUsdtFee, 'estimatedUsdtFee',
                kFakeTaxiFeeSats),
      );
    });
  });

  group('BTC Send', () {
    final asset = Asset.btc();
    final args = SendAssetArguments.fromAsset(asset);
    final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
      input: SendAssetInputState(asset: asset),
    );

    final container = ProviderContainer(overrides: [
      sendAssetInputStateProvider
          .overrideWith(() => mockSendAssetInputStateNotifier),
    ]);

    test('throws FeeTransactionNotFoundError when send txn is null', () async {
      final provider = sendAssetFeeProvider(args);

      expect(
        expectAsync0(() => container.read(provider.future)),
        throwsA(isA<FeeTransactionNotFoundError>()),
      );
    });
    test(
      'throws FeeTransactionNotFoundError when send GDK transaction is null',
      () async {
        final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
          transaction: const SendAssetOnchainTx.gdkPsbt('xxx'),
        );
        final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
          input: SendAssetInputState(asset: asset),
        );
        final container = ProviderContainer(overrides: [
          sendAssetInputStateProvider
              .overrideWith(() => mockSendAssetInputStateNotifier),
          sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        ]);
        final provider = sendAssetFeeProvider(args);

        expect(
          expectAsync0(() => container.read(provider.future)),
          throwsA(isA<FeeTransactionNotFoundError>()),
        );
      },
    );
    test(
      'throws UnknownTransactionSizeError when send gdk txn size is null',
      () async {
        final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
          transaction: const SendAssetOnchainTx.gdkTx(
            GdkNewTransactionReply(fee: 100),
          ),
        );
        final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
          input: SendAssetInputState(asset: asset),
        );
        final container = ProviderContainer(overrides: [
          sendAssetInputStateProvider
              .overrideWith(() => mockSendAssetInputStateNotifier),
          sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
        ]);
        final provider = sendAssetFeeProvider(args);

        expect(
          expectAsync0(() => container.read(provider.future)),
          throwsA(isA<UnknownTransactionSizeError>()),
        );
      },
    );
    test('throws FeeRateNotFoundError when selectedFeeRate is null', () async {
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: const SendAssetOnchainTx.gdkTx(
          GdkNewTransactionReply(
            transactionVsize: 10,
            fee: 100,
          ),
        ),
      );
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(asset: asset),
      );
      final container = ProviderContainer(overrides: [
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
      ]);

      expect(
        expectAsync0(() => container.read(sendAssetFeeProvider(args).future)),
        throwsA(isA<FeeRateNotFoundError>()),
      );
    });
    test('returns correct fee structure when fee & txn are present', () async {
      const kFakeFeeRate = 10.0;
      const kFakeFee = 1000;
      const kFakeFeeFiat = 15.0;
      const kFakeTransactionVsize = 5;
      const kFakeTransaction = SendAssetOnchainTx.gdkTx(
        GdkNewTransactionReply(
          fee: kFakeFee,
          transactionVsize: kFakeTransactionVsize,
        ),
      );
      final mockSendAssetTxnProvider = MockSendAssetTxnProvider(
        transaction: kFakeTransaction,
      );
      final mockSendAssetInputStateNotifier = MockSendAssetInputStateNotifier(
        input: SendAssetInputState(
          asset: asset,
          fee: SendAssetFeeOptionModel.bitcoin(BitcoinFeeModel.high(
            feeRate: kFakeFeeRate,
            feeSats: kFakeFee,
            feeFiat: kFakeFeeFiat,
          )),
        ),
      );
      final container = ProviderContainer(overrides: [
        sendAssetInputStateProvider
            .overrideWith(() => mockSendAssetInputStateNotifier),
        sendAssetTxnProvider.overrideWith(() => mockSendAssetTxnProvider),
      ]);

      final state = await container.read(sendAssetFeeProvider(args).future);

      expect(
        state,
        isA<BitcoinFee>()
            .having((s) => s.feeRate, 'feeRate', kFakeFeeRate)
            .having(
              (s) => s.estimatedFee,
              'estimatedFee',
              kFakeFeeRate * kFakeTransactionVsize,
            ),
      );
    });
  });
}
