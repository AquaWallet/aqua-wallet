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
  const kTransactionVsize = 1000;

  setUpAll(() {
    registerFallbackValue(Asset.liquidTest());
  });

  group('Liquid', () {
    const kLbtcFiatCurrency = 'USD';
    final asset = Asset.liquidTest();
    final args = SendAssetArguments.fromAsset(asset);
    final sendInput = SendAssetInputState(
      isSendAllFunds: false,
      asset: asset,
    );
    const kBtcFiatRate = BitcoinFiatRatesResponse(
      code: kLbtcFiatCurrency,
      rate: 10,
      name: 'US Dollar',
      cryptoCode: 'BTC',
      currencyPair: 'BTCUSD',
    );

    test('throws FeeTransactionNotFoundError if no GDK transaction', () async {
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider(
        throwError: true,
      );
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(transaction: null),
        ),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
      final provider = sendAssetFeeOptionsProvider(args);

      expect(
        () async => container.read(provider.future),
        throwsA(isA<FeeTransactionNotFoundError>()),
      );
    });
    test('throws FeeNotFoundError if no fee in GDK transaction', () async {
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider(
        throwError: true,
      );
      final container = ProviderContainer(overrides: [
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(),
            ),
          ),
        ),
      ]);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
      final provider = sendAssetFeeOptionsProvider(args);

      expect(
        () async => container.read(provider.future),
        throwsA(isA<FeeNotFoundError>()),
      );
    });
    test('returns fee options with L-BTC fee', () async {
      const kLbtcFeeSats = 100;
      const kLbtcFeeFiat = 0.00001;
      const kLbtcFeeRate = 2.0;

      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockBalanceProvider = MockBalanceProvider();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kLbtcFeeRate)),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(fee: kLbtcFeeSats),
            ),
          ),
        ),
        fiatRatesProvider.overrideWith(
          () => MockFiatRatesNotifier(rates: [kBtcFiatRate]),
        ),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kLbtcFiatCurrency);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
      mockBalanceProvider.mockGetBalanceCall(value: kLbtcFeeSats + 1);
      final provider = sendAssetFeeOptionsProvider(args);

      final state = await container.read(provider.future);

      expect(
        state,
        contains(isA<LiquidSendAssetFeeOptionModel>()
            .having((s) => s.fee.isEnabled, 'isEnabled', true)
            .having((s) => s.fee.availableForFeePayment, 'available', true)
            .having(
              (s) => s.fee,
              'fee',
              isA<LbtcLiquidFeeModel>()
                  .having((s) => s.feeSats, 'sats', kLbtcFeeSats)
                  .having((s) => s.feeFiat, 'fiat', kLbtcFeeFiat)
                  .having((s) => s.fiatCurrency, 'currency', kLbtcFiatCurrency)
                  .having((s) => s.fiatFeeDisplay, 'fiatFeeDisp', '≈ USD 0.00')
                  .having((s) => s.satsPerByte, 'satsPerByte', kLbtcFeeRate)
                  .having((s) => s.feeAsset, 'feeAsset', FeeAsset.lbtc),
            )),
      );
    });
    test('returns fee options with USDT fee if USDT asset enabled', () async {
      const kAmount = 1000;
      const kLbtcFeeSats = 100;
      const kTaxiFeeAmount = 200;
      const kTaxiFeeRate = 3.0;
      const kLbtcFeeFiatCurrency = 'USD';
      final kTaxiAsset = Asset.usdtEth();
      final kDeliverAsset = Asset.usdtTrx();

      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockBalanceProvider = MockBalanceProvider();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kTaxiFeeRate)),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        estimatedTaxiFeeUsdtProvider.overrideWith(
          (_, __) => Future.value(kTaxiFeeAmount),
        ),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(
            input: sendInput.copyWith(
              amount: kAmount,
              asset: kDeliverAsset,
            ),
          ),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(fee: kLbtcFeeSats),
            ),
          ),
        ),
        fiatRatesProvider.overrideWith(
          () => MockFiatRatesNotifier(rates: [kBtcFiatRate]),
        ),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kLbtcFeeFiatCurrency);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);
      mockManageAssetsProvider.mockLiquidUsdtAssetCall(asset: kTaxiAsset);
      mockBalanceProvider.mockGetBalanceCall(value: kTaxiFeeAmount + 1);
      final provider = sendAssetFeeOptionsProvider(args);
      final state = await container.read(provider.future);

      expect(
        state,
        contains(
          isA<LiquidSendAssetFeeOptionModel>()
              .having((s) => s.fee.isEnabled, 'isEnabled', true)
              .having((s) => s.fee.availableForFeePayment, 'available', true)
              .having(
                (s) => s.fee,
                'fee',
                isA<UsdtLiquidFeeModel>()
                    .having((s) => s.feeAmount, 'fee', kTaxiFeeAmount)
                    .having((s) => s.feeCurrency, 'currency', kTaxiAsset.ticker)
                    .having((s) => s.feeDisplay, 'feeDisplay', '~0.00 USDt')
                    .having((s) => s.feeAsset, 'feeAsset', FeeAsset.tetherUsdt),
              ),
        ),
      );
    });
    test('USDT fee option is disabled if deliver asset is not USDT', () async {
      const kAmount = 1000;
      const kLbtcFeeSats = 100;
      const kTaxiFeeSats = 200;
      const kTaxiFeeRate = 3.0;
      const kLbtcFeeFiatCurrency = 'USD';
      final kTaxiFeeAsset = Asset.usdtEth();
      final kDeliverAsset = Asset.liquidTest();

      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockBalanceProvider = MockBalanceProvider();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kTaxiFeeRate)),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        estimatedTaxiFeeUsdtProvider.overrideWith(
          (_, __) => Future.value(kTaxiFeeSats),
        ),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(
            input: SendAssetInputState(
              amount: kAmount,
              isSendAllFunds: false,
              asset: kDeliverAsset,
            ),
          ),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(fee: kLbtcFeeSats),
            ),
          ),
        ),
        fiatRatesProvider.overrideWith(
          () => MockFiatRatesNotifier(rates: [kBtcFiatRate]),
        ),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kLbtcFeeFiatCurrency);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);
      mockManageAssetsProvider.mockLiquidUsdtAssetCall(asset: kTaxiFeeAsset);
      mockBalanceProvider.mockGetBalanceCall(value: kTaxiFeeSats + 1);
      final provider = sendAssetFeeOptionsProvider(args);
      final state = await container.read(provider.future);

      expect(
        state,
        contains(
          isA<LiquidSendAssetFeeOptionModel>()
              .having((s) => s.fee.isEnabled, 'isEnabled', false)
              .having((s) => s.fee.availableForFeePayment, 'available', true)
              .having((s) => s.fee, 'fee', isA<UsdtLiquidFeeModel>()),
        ),
      );
    });
    test('USDT fee option is disabled if insufficient USDT balance', () async {
      const kAmount = 1000;
      const kLbtcFeeSats = 100;
      const kTaxiFeeSats = 200;
      const kTaxiFeeRate = 3.0;
      const kLbtcFeeFiatCurrency = 'USD';
      final kTaxiFeeAsset = Asset.usdtEth();
      final kDeliverAsset = Asset.usdtTrx();

      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockBalanceProvider = MockBalanceProvider();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kTaxiFeeRate)),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        estimatedTaxiFeeUsdtProvider.overrideWith(
          (_, __) => Future.value(kTaxiFeeSats),
        ),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(
            input: SendAssetInputState(
              amount: kAmount,
              isSendAllFunds: false,
              asset: kDeliverAsset,
            ),
          ),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(fee: kLbtcFeeSats),
            ),
          ),
        ),
        fiatRatesProvider.overrideWith(
          () => MockFiatRatesNotifier(rates: [kBtcFiatRate]),
        ),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kLbtcFeeFiatCurrency);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: true);
      mockManageAssetsProvider.mockLiquidUsdtAssetCall(asset: kTaxiFeeAsset);
      mockBalanceProvider.mockGetBalanceCall(value: kTaxiFeeSats - 1);
      final provider = sendAssetFeeOptionsProvider(args);
      final state = await container.read(provider.future);

      expect(
        state,
        contains(isA<SendAssetFeeOptionModel>().having(
          (s) => s.fee,
          'fee',
          isA<UsdtLiquidFeeModel>()
              .having((s) => s.feeAsset, 'feeAsset', FeeAsset.tetherUsdt)
              .having((s) => s.isEnabled, 'isEnabled', false),
        )),
      );
    });
    test('USDT fee option is NOT available if USDT is disabled', () async {
      const kLbtcFeeSats = 100;
      const kLbtcFeeRate = 3.0;
      const kLbtcFeeFiatCurrency = 'USD';

      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockBalanceProvider = MockBalanceProvider();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kLbtcFeeRate)),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(fee: kLbtcFeeSats),
            ),
          ),
        ),
        fiatRatesProvider.overrideWith(
          () => MockFiatRatesNotifier(rates: [kBtcFiatRate]),
        ),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kLbtcFeeFiatCurrency);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
      mockBalanceProvider.mockGetBalanceCall(value: kLbtcFeeSats + 1);
      final provider = sendAssetFeeOptionsProvider(args);
      final state = await container.read(provider.future);

      expect(state.length, 1);
      expect(
        state,
        contains(
          isA<LiquidSendAssetFeeOptionModel>()
              .having((s) => s.fee, 'fee', isA<LbtcLiquidFeeModel>()),
        ),
      );
    });
    test('USDT fee option is NOT available if Taxi is disabled', () async {
      const kLbtcFeeSats = 100;
      const kLbtcFeeRate = 3.0;
      const kLbtcFeeFiatCurrency = 'USD';

      final mockPrefsProvider = MockPrefsProvider();
      final mockManageAssetsProvider = MockManageAssetsProvider();
      final mockSideswapTaxiProvider = MockSideswapTaxiProvider(
        throwError: true,
      );
      final mockBalanceProvider = MockBalanceProvider();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        liquidFeeRateProvider.overrideWith((_) => Future.value(kLbtcFeeRate)),
        manageAssetsProvider.overrideWith((_) => mockManageAssetsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(fee: kLbtcFeeSats),
            ),
          ),
        ),
        fiatRatesProvider.overrideWith(
          () => MockFiatRatesNotifier(rates: [kBtcFiatRate]),
        ),
        sideswapTaxiProvider.overrideWith(() => mockSideswapTaxiProvider),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kLbtcFeeFiatCurrency);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockManageAssetsProvider.mockIsUsdtEnabledCall(value: false);
      mockBalanceProvider.mockGetBalanceCall(value: kLbtcFeeSats + 1);
      final provider = sendAssetFeeOptionsProvider(args);
      final state = await container.read(provider.future);

      expect(state.length, 1);
      expect(
        state,
        contains(isA<LiquidSendAssetFeeOptionModel>()
            .having((s) => s.fee, 'fee', isA<LbtcLiquidFeeModel>())),
      );
    });
  });

  group('Bitcoin', () {
    const kBtcFiatCurrency = 'USD';
    final asset = Asset.btc();
    final args = SendAssetArguments.fromAsset(asset);
    final sendInput = SendAssetInputState(
      isSendAllFunds: false,
      asset: asset,
    );
    const kBtcFeeSats = 100;
    const kBtcFiatRate = BitcoinFiatRatesResponse(
      code: kBtcFiatCurrency,
      rate: 10,
      name: 'US Dollar',
      cryptoCode: 'BTC',
      currencyPair: 'BTCUSD',
    );

    test('throws FeeTransactionNotFoundError if no GDK transaction', () async {
      final container = ProviderContainer(overrides: [
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(transaction: null),
        ),
      ]);
      final provider = sendAssetFeeOptionsProvider(args);

      expect(
        () async => container.read(provider.future),
        throwsA(isA<FeeTransactionNotFoundError>()),
      );
    });
    test(
        'throws TransactionSizeNotFoundError if no transaction size in GDK transaction',
        () async {
      final container = ProviderContainer(overrides: [
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(
              GdkNewTransactionReply(fee: kBtcFeeSats),
            ),
          ),
        ),
      ]);
      final provider = sendAssetFeeOptionsProvider(args);

      expect(
        () async => container.read(provider.future),
        throwsA(isA<TransactionSizeNotFoundError>()),
      );
    });
    test('returns fee options with BTC fee', () async {
      const kBtcFeeRateHigh = 4.0;
      const kBtcHighFeeSats = 4000;
      const kBtcHighFeeFiat = 0.0004;

      const kBtcFeeRateMedium = 3.0;
      const kBtcMediumFeeSats = 3000;
      const kBtcMediumFeeFiat = 0.0003;

      const kBtcFeeRateLow = 2.0;
      const kBtcLowFeeSats = 2000;
      const kBtcLowFeeFiat = 0.0002;

      const kBtcFeeRateMin = 1.0;
      const kBtcMinFeeSats = 1000;
      const kBtcMinFeeFiat = 0.0001;

      final mockPrefsProvider = MockPrefsProvider();
      final mockBalanceProvider = MockBalanceProvider();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWith((_) => mockPrefsProvider),
        balanceProvider.overrideWith((_) => mockBalanceProvider),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: sendInput),
        ),
        sendAssetTxnProvider.overrideWith(
          () => MockSendAssetTxnProvider(
            transaction: const SendAssetOnchainTx.gdkTx(GdkNewTransactionReply(
              fee: kBtcFeeSats,
              transactionVsize: kTransactionVsize,
            )),
          ),
        ),
        fiatRatesProvider.overrideWith(
          () => MockFiatRatesNotifier(rates: [kBtcFiatRate]),
        ),
        onChainFeeProvider.overrideWith(
          (_) => Future.value({
            TransactionPriority.high: kBtcFeeRateHigh,
            TransactionPriority.medium: kBtcFeeRateMedium,
            TransactionPriority.low: kBtcFeeRateLow,
            TransactionPriority.min: kBtcFeeRateMin,
          }),
        ),
      ]);
      mockPrefsProvider.mockGetReferenceCurrencyCall(kBtcFiatCurrency);
      mockPrefsProvider.mockGetLanguageCodeCall(kFakeLanguageCode);
      mockBalanceProvider.mockGetBalanceCall(value: kBtcFeeSats + 1);
      final provider = sendAssetFeeOptionsProvider(args);
      final state = await container.read(provider.future);

      expect(
        state,
        containsAll([
          isA<BitcoinSendAssetFeeOptionModel>().having(
            (s) => s.fee,
            'fees',
            isA<BitcoinFeeModelHigh>()
                .having((s) => s.feeSats, 'feeSats', kBtcHighFeeSats)
                .having((s) => s.feeRate, 'feeRate', kBtcFeeRateHigh)
                .having((s) => s.feeFiat, 'feeFiat', kBtcHighFeeFiat),
          ),
          isA<BitcoinSendAssetFeeOptionModel>().having(
            (s) => s.fee,
            'fee',
            isA<BitcoinFeeModelMedium>()
                .having((s) => s.feeSats, 'feeSats', kBtcMediumFeeSats)
                .having((s) => s.feeRate, 'feeRate', kBtcFeeRateMedium)
                .having((s) => s.feeFiat, 'feeFiat', kBtcMediumFeeFiat),
          ),
          isA<BitcoinSendAssetFeeOptionModel>().having(
            (s) => s.fee,
            'fee',
            isA<BitcoinFeeModelLow>()
                .having((s) => s.feeSats, 'feeSats', kBtcLowFeeSats)
                .having((s) => s.feeRate, 'feeRate', kBtcFeeRateLow)
                .having((s) => s.feeFiat, 'feeFiat', kBtcLowFeeFiat),
          ),
          isA<BitcoinSendAssetFeeOptionModel>().having(
            (s) => s.fee,
            'fee',
            isA<BitcoinFeeModelMin>()
                .having((s) => s.feeSats, 'feeSats', kBtcMinFeeSats)
                .having((s) => s.feeRate, 'feeRate', kBtcFeeRateMin)
                .having((s) => s.feeFiat, 'feeFiat', kBtcMinFeeFiat),
          )
        ]),
      );
    });
  });
}
