import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
import 'transaction_details_test_helper.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Asset.usdtLiquid());
    registerFallbackValue(Asset.usdtEth());
    registerFallbackValue(MockAppLocalizations());
  });

  group('AltUsdtTransactionUiModelCreator - Details Methods', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;
    late AltUsdtTransactionUiModelCreator strategy;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
      container = setup.createContainer(
        additionalOverrides: [
          // Mock swap DB order provider to return a test order
          swapDBOrderProvider.overrideWith(() {
            return MockSwapDBOrderNotifier(mockBuilder: (orderId) {
              // Return a mock swap order for all test orders
              if (orderId == 'test_order_id' || orderId == 'test_order') {
                return SwapOrderDbModel(
                  orderId: orderId,
                  createdAt: DateTime.now(),
                  fromAsset: 'usdtliquid',
                  toAsset: 'usdteth',
                  depositAddress: 'deposit_address',
                  settleAddress: 'settle_address',
                  depositAmount: '100.0',
                  settleAmount: '99.0',
                  serviceFeeType: SwapFeeType.percentageFee,
                  serviceFeeValue: '0.9',
                  serviceFeeCurrency: SwapFeeCurrency.usd,
                  depositCoinNetworkFee: '0.0',
                  settleCoinNetworkFee: '0.0',
                  status: SwapOrderStatus.waiting,
                  type: SwapOrderType.variable,
                  serviceType: SwapServiceSource.sideshift,
                );
              }
              return null;
            });
          }),
          // Mock fiat rates provider for fee calculation
          fiatRatesProvider.overrideWith(() {
            return MockFiatRatesNotifier(rates: [
              const BitcoinFiatRatesResponse(
                name: 'US Dollar',
                cryptoCode: 'BTC',
                currencyPair: 'BTC/USD',
                code: 'USD',
                rate: 50000.0,
              ),
            ]);
          }),
          // Mock display units provider
          displayUnitsProvider.overrideWith((ref) {
            final mock = MockDisplayUnitsProvider();
            mock.mockGetForcedDisplayUnit(value: SupportedDisplayUnits.btc);
            return mock;
          }),
          // Mock fiat to sats provider for fee calculation
          fiatToSatsAsIntProvider.overrideWith((ref, params) async {
            // Convert USD amount to sats: 1 USD = 1/50000 BTC = 2000 sats (at $50k/BTC)
            final amount = params.$2;
            const usdRate = 50000.0; // From fiatRatesProvider mock
            final btcAmount = amount.toDouble() / usdRate;
            return (btcAmount * satsPerBtc).toInt();
          }),
        ],
      );

      strategy = container.read(altUsdtTransactionUiModelsProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('createPendingDetails', () {
      test('creates pending alt USDt send details (Liquid -> Ethereum)',
          () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.usdtLiquid(),
          toAsset: Asset.usdtEth(),
        ));

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_usdt_swap',
          assetId: Asset.usdtEth().id,
          type: TransactionDbModelType.sideshiftSwap,
          serviceOrderId: 'test_order_id',
          swapServiceSource: SwapServiceSource.sideshift,
          isGhost: true,
          ghostTxnAmount: -10000000000,
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.usdtLiquid().id,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'pending_usdt_swap');
            expect(details.isPending, isTrue);
            expect(details.deliverAsset, Asset.usdtEth());
            expect(details.feeAsset, Asset.usdtLiquid());
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test(
          'returns result with empty date when ghost transaction has no createdAt',
          () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.usdtLiquid(),
          toAsset: Asset.usdtEth(),
        ));

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_no_created_at',
          assetId: Asset.usdtEth().id,
          type: TransactionDbModelType.sideshiftSwap,
          serviceOrderId: 'test_order_id',
          swapServiceSource: SwapServiceSource.sideshift,
          isGhost: true,
          ghostTxnAmount: -10000000000,
          ghostTxnCreatedAt: null,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.date, '');
            expect(details.isPending, isTrue);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('returns null when asset resolution fails', () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: null,
          toAsset: null,
        ));

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_no_assets',
          assetId: Asset.usdtEth().id,
          type: TransactionDbModelType.sideshiftSwap,
          isGhost: true,
          ghostTxnAmount: -10000000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNull);
      });
    });

    group('createConfirmedDetails', () {
      test('creates confirmed alt USDt send details', () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.usdtLiquid(),
          toAsset: Asset.usdtEth(),
        ));

        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_usdt_swap',
          blockHeight: 100,
          type: GdkTransactionTypeEnum.outgoing,
          satoshi: {Asset.usdtLiquid().id: -10000000000},
          swapOutgoingAssetId: Asset.usdtLiquid().id,
          swapIncomingAssetId: Asset.usdtEth().id,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_usdt_swap',
          assetId: Asset.usdtLiquid().id,
          type: TransactionDbModelType.sideshiftSwap,
          serviceOrderId: 'test_order_id',
          swapServiceSource: SwapServiceSource.sideshift,
          feeAssetId: Asset.usdtLiquid().id,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'confirmed_usdt_swap');
            expect(details.isPending, isFalse);
            expect(details.deliverAsset, Asset.usdtEth());
            expect(details.feeAsset, Asset.usdtLiquid());
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('returns null when network transaction is missing', () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_no_network',
          assetId: Asset.usdtLiquid().id,
          type: TransactionDbModelType.sideshiftSwap,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
          networkTransaction: null,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNull);
      });

      test('returns null when transaction type is not outgoing', () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_incoming',
          blockHeight: 100,
          type: GdkTransactionTypeEnum.incoming,
          satoshi: {Asset.usdtLiquid().id: 10000000000},
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_incoming',
          assetId: Asset.usdtLiquid().id,
          type: TransactionDbModelType.sideshiftSwap,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNull);
      });
    });

    group('createConfirmedListItems', () {
      test('returns null for ghost transactions', () {
        final dbTxn = createMockDbTransaction(
          txhash: 'ghost_swap',
          assetId: Asset.usdtLiquid().id,
          type: TransactionDbModelType.sideshiftSwap,
          isGhost: true,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
          networkTransaction: null,
        );

        final result = strategy.createConfirmedListItems(args);

        expect(result, isNull);
      });

      test('returns null when createdAt cannot be determined', () {
        final dbTxn = createMockDbTransaction(
          txhash: 'swap_no_created_at',
          assetId: Asset.usdtLiquid().id,
          type: TransactionDbModelType.sideshiftSwap,
          ghostTxnCreatedAt: null,
        );

        final args = TransactionStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
          networkTransaction: null,
        );

        final result = strategy.createConfirmedListItems(args);

        expect(result, isNull);
      });
    });

    group('USDt Fee Calculation', () {
      // Note: Fee calculation logic is tested in transaction_fee_structure_provider_test.dart
      // The strategy correctly uses transactionFeeStructureProvider.totalFeesCrypto
      // This matches the approach in usdt_swap_transaction_review_content.dart (the review screen)

      test('uses correct fee values when fee paid in USDt', () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.usdtLiquid(),
          toAsset: Asset.usdtEth(),
        ));

        final dbTxn = createMockDbTransaction(
          txhash: 'usdt_fee_swap',
          assetId: Asset.usdtEth().id,
          type: TransactionDbModelType.sideshiftSwap,
          serviceOrderId: 'test_order',
          swapServiceSource: SwapServiceSource.sideshift,
          isGhost: true,
          ghostTxnAmount: -10000000000,
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.usdtLiquid().id,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Fee is paid in USDt
            expect(details.feeAsset, Asset.usdtLiquid());
            // Fees come from the calculated values based on swap order
            expect(details.feeAmount, isEmpty);
            expect(details.feeAmountFiat, isNotEmpty);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('uses correct fee values when fee paid in LBTC', () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.usdtLiquid(),
          toAsset: Asset.usdtEth(),
        ));

        final dbTxn = createMockDbTransaction(
          txhash: 'lbtc_fee_swap',
          assetId: Asset.usdtEth().id,
          type: TransactionDbModelType.sideshiftSwap,
          serviceOrderId: 'test_order',
          swapServiceSource: SwapServiceSource.sideshift,
          isGhost: true,
          ghostTxnAmount: -10000000000,
          ghostTxnCreatedAt: DateTime.now(),
          feeAssetId: Asset.lbtc().id, // Fee paid in LBTC
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth(), Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Fee is paid in LBTC
            expect(details.feeAsset, Asset.lbtc());
            // Fees come from the calculated values based on swap order
            expect(details.feeAmount, isEmpty);
            expect(details.feeAmountFiat, isNotEmpty);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test(
          'confirmed transaction uses correct fee values when fee paid in USDt',
          () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.usdtLiquid(),
          toAsset: Asset.usdtEth(),
        ));

        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_usdt_fee',
          blockHeight: 100,
          type: GdkTransactionTypeEnum.outgoing,
          satoshi: {Asset.usdtLiquid().id: -10000000000},
          swapOutgoingAssetId: Asset.usdtLiquid().id,
          swapIncomingAssetId: Asset.usdtEth().id,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_usdt_fee',
          assetId: Asset.usdtLiquid().id,
          type: TransactionDbModelType.sideshiftSwap,
          serviceOrderId: 'test_order',
          swapServiceSource: SwapServiceSource.sideshift,
          feeAssetId: Asset.usdtLiquid().id,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Fee is paid in USDt
            expect(details.feeAsset, Asset.usdtLiquid());
            // Fees come from the calculated values based on swap order
            expect(details.feeAmount, isEmpty);
            expect(details.feeAmountFiat, isNotEmpty);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test(
          'confirmed transaction uses correct fee values when fee paid in LBTC',
          () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.usdtLiquid(),
          toAsset: Asset.usdtEth(),
        ));

        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_lbtc_fee',
          blockHeight: 100,
          type: GdkTransactionTypeEnum.outgoing,
          satoshi: {Asset.usdtLiquid().id: -10000000000},
          swapOutgoingAssetId: Asset.usdtLiquid().id,
          swapIncomingAssetId: Asset.usdtEth().id,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_lbtc_fee',
          assetId: Asset.usdtLiquid().id,
          type: TransactionDbModelType.sideshiftSwap,
          serviceOrderId: 'test_order',
          swapServiceSource: SwapServiceSource.sideshift,
          feeAssetId: Asset.lbtc().id, // Fee paid in LBTC
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.usdtLiquid(),
          availableAssets: [Asset.usdtLiquid(), Asset.usdtEth(), Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Fee is paid in LBTC
            expect(details.feeAsset, Asset.lbtc());
            // Fees come from the calculated values based on swap order
            expect(details.feeAmount, isEmpty);
            expect(details.feeAmountFiat, isNotEmpty);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });
    });
  });
}
