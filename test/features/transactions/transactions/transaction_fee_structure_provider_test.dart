import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

class MockFormatService extends Mock implements FormatService {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const SwapOrderRequest(
      from: SwapAsset(id: 'test', name: 'Test', ticker: 'TEST'),
      to: SwapAsset(id: 'test2', name: 'Test2', ticker: 'TEST2'),
    ));
    registerFallbackValue(Asset.btc());
    registerFallbackValue(SupportedDisplayUnits.btc);
    registerFallbackValue(Decimal.zero);
    registerFallbackValue(const CurrencyFormatSpec(
      symbol: ' ',
      decimalSeparator: '.',
      thousandsSeparator: ',',
      isSymbolLeading: true,
      decimalPlaces: 2,
    ));
  });

  group('Aqua Send', () {
    final container = ProviderContainer(overrides: []);
    test('throws argument error if send asset args are not provided', () async {
      const args = FeeStructureArguments.aquaSend();

      expect(
        expectAsync0(
          () => container.read(transactionFeeStructureProvider(args).future),
        ),
        throwsArgumentError,
      );
    });
    test('returns correct fee structure when BTC send', () async {
      const kFeeRate = 100;
      const kEstimatedFee = 1000;
      final asset = Asset.btc();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.btc(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.bitcoin(
          feeRate: kFeeRate,
          estimatedFee: kEstimatedFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<BitcoinSendFee>()
            .having((s) => s.feeRate, 'feeRate', kFeeRate)
            .having((s) => s.estimatedFee, 'estimatedFee', kEstimatedFee),
      );
    });
    test('returns correct fee structure when L-BTC send', () async {
      const kFeeRate = 200;
      const kEstimatedFee = 2000;
      final asset = Asset.lbtc();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.liquid(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquid(
          feeRate: kFeeRate,
          estimatedFee: kEstimatedFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<LiquidSendFee>()
            .having((s) => s.feeRate, 'feeRate', kFeeRate)
            .having((s) => s.estimatedFee, 'estimatedFee', kEstimatedFee),
      );
    });
    test('returns correct fee structure when L-BTC taxi send', () async {
      const kLbtcFeeRate = 50;
      const kEstimatedLbtcFee = 500;
      const kUsdtFeeRate = 0.1;
      const kEstimatedUsdtFee = 100.0;
      final asset = Asset.lbtc();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.liquidUsdt(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquidTaxi(
          lbtcFeeRate: kLbtcFeeRate,
          estimatedLbtcFee: kEstimatedLbtcFee,
          usdtFeeRate: kUsdtFeeRate,
          estimatedUsdtFee: kEstimatedUsdtFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<LiquidTaxiSendFee>()
            .having((s) => s.lbtcFeeRate, 'lbtcFeeRate', kLbtcFeeRate)
            .having((s) => s.estimatedLbtcFee, 'lbtcFee', kEstimatedLbtcFee)
            .having((s) => s.usdtFeeRate, 'usdtFeeRate', kUsdtFeeRate)
            .having((s) => s.estimatedUsdtFee, 'usdtFee', kEstimatedUsdtFee),
      );
    });
    test('returns correct fee structure when Lightning send', () async {
      const kFeeRate = 200;
      const kEstimatedFee = 2000;
      final asset = Asset.lightning();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.lightningBtc(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquid(
          feeRate: kFeeRate,
          estimatedFee: kEstimatedFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<BoltzSendFee>()
            .having((s) => s.onchainFeeRate, 'onchainFeeRate', kFeeRate)
            .having((s) => s.estimatedOnchainFee, 'onchainFee', kEstimatedFee)
            .having(
              (s) => s.swapFeePercentage,
              'swapFeePercentage',
              kBoltzSubmarinePercentFee,
            ),
      );
    });
  });

  group('Sideswap', () {
    const swapInput = SideswapInputState(
      assets: [],
      deliverAsset: null,
      receiveAsset: null,
      deliverAssetBalance: '',
      receiveAssetBalance: '',
    );

    test('returns correct fee when input is peg in', () async {
      const kOnchainFee = 5;
      const kSideswapFeePercentage = 0.1;
      const kSideswapFee = 10;
      final kDeliverAsset = Asset.btc();
      final kReceiveAsset = Asset.lbtc().copyWith(isLBTC: true);
      final input = swapInput.copyWith(
        deliverAsset: kDeliverAsset,
        receiveAsset: kReceiveAsset,
      );
      final pegState = PegState.pendingVerification(
        data: SwapPegReviewModel(
          asset: kDeliverAsset,
          order: const SwapStartPegResult(
            orderId: '',
            pegAddress: '',
          ),
          transaction: const GdkNewTransactionReply(
            fee: kOnchainFee,
          ),
          inputAmount: 0,
          sendTxAmount: 0,
          receiveAmount: 0,
          firstOnchainFeeAmount: kOnchainFee,
          secondOnchainFeeAmount: kOnchainFee,
          isSendAll: false,
        ),
      );
      final mockFeeEstimateClient = MockFeeEstimateClient();
      final container = ProviderContainer(overrides: [
        pegProvider.overrideWith(() => MockPegNotifier(pegState)),
        feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
        sideswapStatusStreamResultStateProvider.overrideWith(
          (_) => const ServerStatusResult(
            serverFeePercentPegIn: kSideswapFeePercentage,
          ),
        ),
        sideswapInputStateProvider
            .overrideWith((_) => MockSideswapInputStateNotifier(input)),
      ]);
      mockFeeEstimateClient.mockFetchBitcoinFeeRates({
        TransactionPriority.high: kOnchainFee.toDouble(),
      });
      mockFeeEstimateClient.mockGetLiquidFeeRate(kSideswapFee.toDouble());
      const args = FeeStructureArguments.sideswap();
      final provider = transactionFeeStructureProvider(args);

      expect(
        await container.read(provider.future),
        isA<SideswapPegInFee>()
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.estimatedBtcFee),
              'estimatedBtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.estimatedLbtcFee),
              'estimatedLbtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.btcFeeRate),
              'btcFeeRate',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.lbtcFeeRate),
              'lbtcFeeRate',
              kSideswapFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.swapFeePercentage),
              'swapFeePercentage',
              kSideswapFeePercentage,
            ),
      );
    });
    test('returns correct fee when input is peg out', () async {
      const kOnchainFee = 15;
      const kSideswapFeePercentage = 0.1;
      const kSideswapFee = 5;
      final kDeliverAsset = Asset.lbtc().copyWith(isLBTC: true);
      final kReceiveAsset = Asset.btc();
      final input = swapInput.copyWith(
        deliverAsset: kDeliverAsset,
        receiveAsset: kReceiveAsset,
      );
      final pegState = PegState.pendingVerification(
        data: SwapPegReviewModel(
          asset: kDeliverAsset,
          order: const SwapStartPegResult(
            orderId: '',
            pegAddress: '',
          ),
          transaction: const GdkNewTransactionReply(
            fee: kOnchainFee,
          ),
          inputAmount: 0,
          sendTxAmount: 0,
          receiveAmount: 0,
          firstOnchainFeeAmount: kOnchainFee,
          secondOnchainFeeAmount: kOnchainFee,
          isSendAll: false,
        ),
      );
      final mockFeeEstimateClient = MockFeeEstimateClient();
      final container = ProviderContainer(overrides: [
        pegProvider.overrideWith(() => MockPegNotifier(pegState)),
        feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
        sideswapStatusStreamResultStateProvider.overrideWith(
          (_) => const ServerStatusResult(
            serverFeePercentPegIn: kSideswapFeePercentage,
          ),
        ),
        sideswapInputStateProvider
            .overrideWith((_) => MockSideswapInputStateNotifier(input)),
      ]);
      mockFeeEstimateClient.mockFetchBitcoinFeeRates({
        TransactionPriority.high: kOnchainFee.toDouble(),
      });
      mockFeeEstimateClient.mockGetLiquidFeeRate(kSideswapFee.toDouble());
      const args = FeeStructureArguments.sideswap();
      final provider = transactionFeeStructureProvider(args);

      expect(
        await container.read(provider.future),
        isA<SideswapPegOutFee>()
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.estimatedBtcFee),
              'estimatedBtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.estimatedLbtcFee),
              'estimatedLbtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.btcFeeRate),
              'btcFeeRate',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.lbtcFeeRate),
              'lbtcFeeRate',
              kSideswapFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.swapFeePercentage),
              'swapFeePercentage',
              kSideswapFeePercentage,
            ),
      );
    });
    test('returns correct fee when input is instant swap', () async {
      const kOnchainFee = 25;
      const kSideswapFeePercentage = 0.6;
      const kSideswapFee = 5;
      final kDeliverAsset = Asset.lbtc().copyWith(isLBTC: true);
      final kReceiveAsset = Asset.usdtEth();
      final input = swapInput.copyWith(
        deliverAsset: kDeliverAsset,
        receiveAsset: kReceiveAsset,
      );
      final mockFeeEstimateClient = MockFeeEstimateClient();
      final container = ProviderContainer(overrides: [
        feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
        sideswapPriceStreamResultStateProvider.overrideWith(
          (_) => const PriceStreamResult(
            fixedFee: kOnchainFee,
          ),
        ),
        sideswapInputStateProvider
            .overrideWith((_) => MockSideswapInputStateNotifier(input)),
      ]);
      mockFeeEstimateClient.mockGetLiquidFeeRate(kSideswapFee.toDouble());
      const args = FeeStructureArguments.sideswap();
      final provider = transactionFeeStructureProvider(args);

      expect(
        await container.read(provider.future),
        isA<SideswapInstantSwapFee>()
            .having(
              (s) => s.mapOrNull(sideswapInstantSwap: (s) => s.estimatedFee),
              'estimatedFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapInstantSwap: (s) => s.feeRate),
              'feeRate',
              kSideswapFee,
            )
            .having(
              (s) =>
                  s.mapOrNull(sideswapInstantSwap: (s) => s.swapFeePercentage),
              'swapFeePercentage',
              kSideswapFeePercentage,
            ),
      );
    });
  });

  group('USDT Swap', () {
    late ProviderContainer container;
    late MockSharedPreferences mockSharedPreferences;
    late MockUserPreferencesNotifier mockPrefsNotifier;
    late ReferenceExchangeRateProviderMock mockExchangeRateProvider;
    late MockDisplayUnitsProvider mockDisplayUnitsProvider;
    late MockFormatService mockFormatService;
    late List<Override> baseOverrides;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      mockPrefsNotifier = MockUserPreferencesNotifier();
      mockExchangeRateProvider = ReferenceExchangeRateProviderMock();
      mockDisplayUnitsProvider = MockDisplayUnitsProvider();
      mockFormatService = MockFormatService();

      mockPrefsNotifier.mockGetDisplayUnitCall(SupportedDisplayUnits.btc);
      mockPrefsNotifier.mockGetReferenceCurrencyCall('USD');
      mockDisplayUnitsProvider.mockConvertSatsToUnit(value: Decimal.zero);
      mockDisplayUnitsProvider.mockCurrentDisplayUnit(
        value: SupportedDisplayUnits.btc,
      );
      when(() => mockDisplayUnitsProvider.getForcedDisplayUnit(any()))
          .thenReturn(SupportedDisplayUnits.btc);
      mockExchangeRateProvider.mockGetCurrentCurrency(
        value: kBtcUsdExchangeRate,
      );
      mockExchangeRateProvider.mockGetAvailableCurrencies(
        value: [kBtcUsdExchangeRate],
      );
      when(() => mockFormatService.formatAssetAmount(
            amount: any(named: 'amount'),
            asset: any(named: 'asset'),
            displayUnitOverride: any(named: 'displayUnitOverride'),
            specOverride: any(named: 'specOverride'),
            decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
            removeTrailingZeros: any(named: 'removeTrailingZeros'),
          )).thenReturn('0');
      when(() => mockFormatService.formatFiatAmount(
            amount: any(named: 'amount'),
            specOverride: any(named: 'specOverride'),
            decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
            withSymbol: any(named: 'withSymbol'),
          )).thenReturn(r'$0.00');

      final mockFiatProvider = MockFiatProvider();
      mockFiatProvider.mockFiatToSatoshi(
        returnValue: Decimal.fromInt(2000), // Default: 2000 sats
      );

      baseOverrides = [
        sharedPreferencesProvider.overrideWith((_) => mockSharedPreferences),
        prefsProvider.overrideWith((_) => mockPrefsNotifier),
        exchangeRatesProvider.overrideWith((_) => mockExchangeRateProvider),
        displayUnitsProvider.overrideWith((_) => mockDisplayUnitsProvider),
        formatProvider.overrideWith((_) => mockFormatService),
        fiatProvider.overrideWith((_) => mockFiatProvider),
        fiatToSatsAsIntProvider.overrideWith((ref, params) async => 0),
      ];

      // Create a fresh container for each test to avoid disposal issues
      container = ProviderContainer(overrides: baseOverrides);
    });

    tearDown(() {
      container.dispose();
    });

    test('returns correct fee structure for Changelly swap', () async {
      const kDepositAmount = '100.0';
      const kSettleAmount = '98.5';
      const kSettleCoinNetworkFee = '0.8';
      const kDepositCoinNetworkFee = '0.2';
      const kActualFeeInSats = 44;
      const kUsdRate = 50000.0;

      final deliverAsset = Asset.usdtEth();
      final args = FeeStructureArguments.usdtSwap(
        sendAssetArgs: SendAssetArguments.liquidUsdt(deliverAsset),
      );

      final mockSwapOrder = SwapOrder(
        createdAt: DateTime.now(),
        id: 'test_order_id',
        from: SwapAsset.fromAsset(Asset.lbtc()),
        to: SwapAsset.fromAsset(deliverAsset),
        depositAddress: 'test_deposit_address',
        settleAddress: 'test_settle_address',
        depositAmount: Decimal.parse(kDepositAmount),
        settleAmount: Decimal.parse(kSettleAmount),
        settleCoinNetworkFee: Decimal.parse(kSettleCoinNetworkFee),
        depositCoinNetworkFee: Decimal.parse(kDepositCoinNetworkFee),
        serviceFee: SwapFee(
          type: SwapFeeType.percentageFee,
          value: Decimal.parse('0.5'),
          currency: SwapFeeCurrency.usd,
        ),
        status: SwapOrderStatus.waiting,
        serviceType: SwapServiceSource.changelly,
      );

      final mockSwapRate = SwapRate(
        rate: Decimal.parse('0.985'),
        min: Decimal.parse('0.1'),
        max: Decimal.parse('1000'),
      );

      // Create a complete mock state with both order and rate
      final mockSwapOrderState = SwapOrderCreationState(
        order: mockSwapOrder,
        rate: mockSwapRate,
      );

      // Mock dependencies
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquid(
          feeRate: 100,
          estimatedFee: kActualFeeInSats,
        ),
      );

      // Dispose the existing container and create a new one with overrides
      container.dispose();
      container = ProviderContainer(
        overrides: [
          ...baseOverrides,
          preferredUsdtSwapServiceProvider.overrideWith(
            () => MockPreferredUsdtServiceNotifier(SwapServiceSource.changelly),
          ),
          swapOrderProvider.overrideWith(
            () => _MockSwapOrderNotifierWithState(mockSwapOrderState),
          ),
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
          fiatRatesProvider.overrideWith(
            () => MockFiatRatesNotifier(rates: [
              const BitcoinFiatRatesResponse(
                name: 'US Dollar',
                cryptoCode: 'BTC',
                currencyPair: 'BTCUSD',
                code: 'USD',
                rate: kUsdRate,
              ),
            ]),
          ),
        ],
      );

      // Get the provider and keep it alive during the async operation
      final provider = transactionFeeStructureProvider(args);

      // Keep the provider alive by listening to it
      final subscription = container.listen(provider, (previous, next) {});

      try {
        // Wait for the result
        final state = await container.read(provider.future);

        // Expected calculations based on Changelly logic:
        // Per Changelly docs: amountExpectedTo is BEFORE network fee deduction
        // depositAmount (amountExpectedFrom) = 100.0
        // settleAmount (amountExpectedTo) = 98.5 (BEFORE network fee)
        // settleCoinNetworkFee = 0.8
        // User actually receives = 98.5 - 0.8 = 97.7
        // serviceFee = 100.0 - 98.5 = 1.5
        // serviceFeePercentage = (1.5 / 100.0) * 100 = 1.5%
        // receiveNetworkFee = 0.8
        // estimatedSendNetworkFeeUsd = 0.00 (no historical rate provided)
        // totalFees = 1.5 + 0.8 + 0.00 = 2.3

        expect(
          state,
          isA<USDtSwapFee>()
              .having((s) => s.serviceFee, 'serviceFee', closeTo(1.5, 0.001))
              .having((s) => s.serviceFeePercentage, 'serviceFeePercentage',
                  closeTo(1.5, 0.001))
              .having((s) => s.receiveNetworkFee, 'receiveNetworkFee',
                  closeTo(0.8, 0.001))
              .having((s) => s.estimatedSendNetworkFee,
                  'estimatedSendNetworkFee', 0.00)
              .having((s) => s.totalFees, 'totalFees', closeTo(2.3, 0.01)),
        );
      } finally {
        // Clean up the subscription
        subscription.close();
      }
    });

    test('throws argument error if asset is not alt USDT', () async {
      final nonUsdtAsset = Asset.btc();
      final args = FeeStructureArguments.usdtSwap(
        sendAssetArgs: SendAssetArguments.btc(nonUsdtAsset),
      );

      // Dispose the existing container and create a new one with overrides
      container.dispose();
      container = ProviderContainer(overrides: [
        ...baseOverrides,
        preferredUsdtSwapServiceProvider.overrideWith(
          () => MockPreferredUsdtServiceNotifier(SwapServiceSource.changelly),
        ),
      ]);

      expect(
        expectAsync0(
          () => container.read(transactionFeeStructureProvider(args).future),
        ),
        throwsArgumentError,
      );
    });

    test('returns correct fee structure for SideShift swap', () async {
      const kDepositAmount = '100.0';
      const kSettleAmount = '98.2';
      const kSettleCoinNetworkFee = '0.9';
      const kDepositCoinNetworkFee = '0.3';
      const kActualFeeInSats = 44;
      const kUsdRate = 50000.0;

      final deliverAsset = Asset.usdtEth();
      final args = FeeStructureArguments.usdtSwap(
        sendAssetArgs: SendAssetArguments.liquidUsdt(deliverAsset),
      );

      final mockSwapOrder = SwapOrder(
        createdAt: DateTime.now(),
        id: 'test_order_id',
        from: SwapAsset.fromAsset(Asset.lbtc()),
        to: SwapAsset.fromAsset(deliverAsset),
        depositAddress: 'test_deposit_address',
        settleAddress: 'test_settle_address',
        depositAmount: Decimal.parse(kDepositAmount),
        settleAmount: Decimal.parse(kSettleAmount),
        settleCoinNetworkFee: Decimal.parse(kSettleCoinNetworkFee),
        depositCoinNetworkFee: Decimal.parse(kDepositCoinNetworkFee),
        serviceFee: SwapFee(
          type: SwapFeeType.percentageFee,
          value: Decimal.parse('0.6'),
          currency: SwapFeeCurrency.usd,
        ),
        status: SwapOrderStatus.waiting,
        serviceType: SwapServiceSource.sideshift,
      );

      final mockSwapRate = SwapRate(
        rate: Decimal.parse('0.982'),
        min: Decimal.parse('0.1'),
        max: Decimal.parse('1000'),
      );

      // Create a complete mock state with both order and rate
      final mockSwapOrderState = SwapOrderCreationState(
        order: mockSwapOrder,
        rate: mockSwapRate,
      );

      // Mock dependencies
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquid(
          feeRate: 100,
          estimatedFee: kActualFeeInSats,
        ),
      );

      // Dispose the existing container and create a new one with overrides
      container.dispose();
      container = ProviderContainer(
        overrides: [
          ...baseOverrides,
          preferredUsdtSwapServiceProvider.overrideWith(
            () => MockPreferredUsdtServiceNotifier(SwapServiceSource.sideshift),
          ),
          swapOrderProvider.overrideWith(
            () => _MockSwapOrderNotifierWithState(mockSwapOrderState),
          ),
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
          fiatRatesProvider.overrideWith(
            () => MockFiatRatesNotifier(rates: [
              const BitcoinFiatRatesResponse(
                name: 'US Dollar',
                cryptoCode: 'BTC',
                currencyPair: 'BTCUSD',
                code: 'USD',
                rate: kUsdRate,
              ),
            ]),
          ),
        ],
      );

      // Get the provider and keep it alive during the async operation
      final provider = transactionFeeStructureProvider(args);

      // Keep the provider alive by listening to it
      final subscription = container.listen(provider, (previous, next) {});

      try {
        // Wait for the result
        final state = await container.read(provider.future);

        // Expected calculations based on SideShift logic:
        // depositAmount = 100.0
        // settleAmount = 98.2
        // kSideshiftServiceFee = 0.009 (0.9%)
        // serviceFee = 100.0 * 0.009 = 0.9 (exact, no truncation)
        // totalFees = 100.0 - 98.2 = 1.8
        // receiveNetworkFees = 1.8 - 0.9 = 0.9 (exact, no truncation)
        // serviceFeePercentage = 0.009 * 100 = 0.9%
        // estimatedSendNetworkFeeUsd = 0.00 (no historical rate provided)
        // totalFees = 0.9 + 0.9 + 0.00 = 1.8

        expect(
          state,
          isA<USDtSwapFee>()
              .having((s) => s.serviceFee, 'serviceFee', closeTo(0.9, 0.001))
              .having((s) => s.serviceFeePercentage, 'serviceFeePercentage',
                  closeTo(0.9, 0.001))
              .having((s) => s.receiveNetworkFee, 'receiveNetworkFee',
                  closeTo(0.9, 0.001))
              .having((s) => s.estimatedSendNetworkFee,
                  'estimatedSendNetworkFee', 0.00)
              .having((s) => s.totalFees, 'totalFees', closeTo(1.8, 0.01)),
        );
      } finally {
        // Clean up the subscription
        subscription.close();
      }
    });

    test('throws state error if no swap service is selected', () async {
      final deliverAsset = Asset.usdtEth();
      final args = FeeStructureArguments.usdtSwap(
        sendAssetArgs: SendAssetArguments.liquidUsdt(deliverAsset),
      );

      // Dispose the existing container and create a new one with overrides
      container.dispose();
      container = ProviderContainer(overrides: [
        ...baseOverrides,
        preferredUsdtSwapServiceProvider.overrideWith(
          () => MockPreferredUsdtServiceNotifier(null),
        ),
      ]);

      expect(
        expectAsync0(
          () => container.read(transactionFeeStructureProvider(args).future),
        ),
        throwsStateError,
      );
    });

    test('uses USDT fee amount when USDT fee option is selected', () async {
      const kUsdtTaxiFeeSats = 50000; // 0.0005 USDT in sats
      const kLiquidFeeSats = 44;

      final deliverAsset = Asset.usdtEth();
      final args = FeeStructureArguments.usdtSwap(
        sendAssetArgs: SendAssetArguments.liquidUsdt(deliverAsset),
      );

      // Create input state with USDT fee selected
      final inputStateWithUsdtFee = SendAssetInputState(
        asset: deliverAsset,
        feeAsset: FeeAsset.tetherUsdt,
        rate: kBtcUsdExchangeRate,
        fee: SendAssetFeeOptionModel.liquid(
          LiquidFeeModel.usdt(
            feeAmount: kUsdtTaxiFeeSats,
            feeCurrency: 'USDt',
            feeDisplay: '0.0005 USDt',
          ),
        ),
      );

      // Use existing test setup but override input state
      final mockSwapOrder = SwapOrder(
        createdAt: DateTime.now(),
        id: 'test_order_id',
        from: SwapAsset.fromAsset(Asset.lbtc()),
        to: SwapAsset.fromAsset(deliverAsset),
        depositAddress: 'test_deposit_address',
        settleAddress: 'test_settle_address',
        depositAmount: Decimal.parse('100.0'),
        settleAmount: Decimal.parse('98.2'),
        serviceFee: SwapFee(
          type: SwapFeeType.percentageFee,
          value: Decimal.parse('0.6'),
          currency: SwapFeeCurrency.usd,
        ),
        status: SwapOrderStatus.waiting,
        serviceType: SwapServiceSource.sideshift,
      );

      final mockSwapOrderState = SwapOrderCreationState(
        order: mockSwapOrder,
        rate: SwapRate(
            rate: Decimal.parse('0.982'),
            min: Decimal.parse('0.1'),
            max: Decimal.parse('1000')),
      );

      container.dispose();
      container = ProviderContainer(overrides: [
        ...baseOverrides,
        preferredUsdtSwapServiceProvider.overrideWith(
          () => MockPreferredUsdtServiceNotifier(SwapServiceSource.sideshift),
        ),
        swapOrderProvider.overrideWith(
          () => _MockSwapOrderNotifierWithState(mockSwapOrderState),
        ),
        sendAssetFeeProvider.overrideWith(() => MockSendAssetFeeNotifier(
              const SendAssetFeeState.liquid(
                  feeRate: 100, estimatedFee: kLiquidFeeSats),
            )),
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: inputStateWithUsdtFee),
        ),
        fiatRatesProvider.overrideWith(() => MockFiatRatesNotifier(rates: [])),
      ]);

      final provider = transactionFeeStructureProvider(args);
      final subscription = container.listen(provider, (previous, next) {});

      try {
        final state = await container.read(provider.future);

        // The key assertion: when USDT fee is selected, estimatedSendNetworkFee should be
        // the USDT amount (0.0005) instead of the liquid fee converted to USD
        expect(
          state,
          isA<USDtSwapFee>().having(
            (s) => s.estimatedSendNetworkFee,
            'estimatedSendNetworkFee',
            0.0005, // USDT fee: 50000 sats / 100000000 = 0.0005
          ),
        );
      } finally {
        subscription.close();
      }
    });
  });
}

// Custom mock notifier that returns a specific state and extends SwapOrderNotifier
class _MockSwapOrderNotifierWithState extends SwapOrderNotifier {
  final SwapOrderCreationState _state;

  _MockSwapOrderNotifierWithState(this._state);

  @override
  Future<SwapOrderCreationState> build(SwapArgs arg) async {
    return _state;
  }
}
