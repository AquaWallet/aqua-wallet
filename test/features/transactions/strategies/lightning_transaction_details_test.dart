import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
import 'transaction_details_test_helper.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Asset.lbtc());
    registerFallbackValue(TransactionStrategyArgs(
      asset: Asset.lbtc(),
      availableAssets: [],
    ));
    registerFallbackValue(MockAppLocalizations());
  });

  group('LightningTransactionUiModelCreator - Details Methods', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
      container = setup.createContainer();

      // Setup asset resolution for Lightning
      when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
            dbTxn: any(named: 'dbTxn'),
            asset: any(named: 'asset'),
            networkTxn: any(named: 'networkTxn'),
            availableAssets: any(named: 'availableAssets'),
          )).thenReturn((
        fromAsset: Asset.lbtc(),
        toAsset: Asset.lightning(),
      ));
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper to get strategy after providers stabilize
    Future<LightningTransactionUiModelCreator> getStrategy() async {
      // Wait for async providers to stabilize before reading strategy
      await container.read(availableAssetsProvider.future);
      await container.read(boltzStorageProvider.future);
      return container.read(lightningTransactionUiModelsProvider);
    }

    group('createPendingDetails', () {
      test('Lightning submarine swap shows as SEND with isLightning flag',
          () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          isGhost: true,
          ghostTxnAmount: -10000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'pending_ln_send');
            expect(details.isPending, true);
            expect(details.isLightning, true);
            expect(details.isFailed, false);
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.canRbf, false);
          },
          receive: (_) => fail('Submarine swap should be send'),
          swap: (_) => fail('Should be send, not swap'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('Lightning reverse swap shows as RECEIVE with isLightning flag',
          () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_ln_receive',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzReverseSwap,
          isGhost: true,
          ghostTxnAmount: 10000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Reverse swap should be receive'),
          receive: (details) {
            expect(details.transactionId, 'pending_ln_receive');
            expect(details.isPending, true);
            expect(details.isLightning, true);
            expect(details.receivedAsset.id, Asset.lbtc().id);
          },
          swap: (_) => fail('Should be receive, not swap'),
          peg: (_) => fail('Should be receive'),
          redeposit: (_) => fail('Should be receive'),
        );
      });

      test('returns null when not a Boltz swap', () async {
        final dbTxn = createMockDbTransaction(
          type: TransactionDbModelType.aquaSend,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [],
          dbTransaction: dbTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createPendingDetails(args);

        expect(result, isNull);
      });

      test('failed Lightning send shows as SEND with isFailed = true',
          () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'failed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSendFailed,
          isGhost: true,
          ghostTxnAmount: -10000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        // Mock failure service to return true for this transaction
        when(() => setup.mockTxnFailureService.isFailed(any()))
            .thenReturn(true);

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'failed_ln_send');
            expect(details.isPending, true);
            expect(details.isLightning, true);
            expect(details.isFailed, true);
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.canRbf, false);
          },
          receive: (_) => fail('Failed send should be send'),
          swap: (_) => fail('Should be send, not swap'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('Lightning refund shows as RECEIVE with isLightning flag', () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'refund_txn',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzRefund,
          isGhost: true,
          ghostTxnAmount: 10000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Refund should be receive'),
          receive: (details) {
            expect(details.transactionId, 'refund_txn');
            expect(details.isPending, true);
            expect(details.isLightning, true);
            expect(details.receivedAsset.id, Asset.lbtc().id);
          },
          swap: (_) => fail('Should be receive, not swap'),
          peg: (_) => fail('Should be receive'),
          redeposit: (_) => fail('Should be receive'),
        );
      });
    });

    group('createConfirmedDetails', () {
      test('creates confirmed Lightning submarine swap as SEND', () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_ln_send',
          blockHeight: 100,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          ghostTxnAmount: -10000000,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'confirmed_ln_send');
            expect(details.confirmations, '2 confirmations');
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.isLightning, true);
            expect(details.isFailed, false);
            expect(details.canRbf, false);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send, not swap'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('creates confirmed Lightning reverse swap as RECEIVE', () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_ln_receive',
          blockHeight: 100,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_ln_receive',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzReverseSwap,
          ghostTxnAmount: 10000000,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be receive'),
          receive: (details) {
            expect(details.transactionId, 'confirmed_ln_receive');
            expect(details.confirmations, '2 confirmations');
            expect(details.receivedAsset.id, Asset.lbtc().id);
            expect(details.isLightning, true);
          },
          swap: (_) => fail('Should be receive, not swap'),
          peg: (_) => fail('Should be receive'),
          redeposit: (_) => fail('Should be receive'),
        );
      });

      test('returns null when not a Boltz swap', () async {
        final dbTxn = createMockDbTransaction(
          type: TransactionDbModelType.aquaSend,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [],
          dbTransaction: dbTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNull);
      });

      test(
          'creates confirmed failed Lightning send as SEND with isFailed = true',
          () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_failed_ln_send',
          blockHeight: 100,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_failed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSendFailed,
          ghostTxnAmount: -10000000,
        );

        // Mock failure service to return true for this transaction
        when(() => setup.mockTxnFailureService.isFailed(any()))
            .thenReturn(true);

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.transactionId, 'confirmed_failed_ln_send');
            expect(details.confirmations, '2 confirmations');
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.isLightning, true);
            expect(details.isFailed, true);
            expect(details.canRbf, false);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send, not swap'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('creates confirmed Lightning refund as RECEIVE', () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_refund',
          blockHeight: 100,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_refund',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzRefund,
          ghostTxnAmount: 10000000,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be receive'),
          receive: (details) {
            expect(details.transactionId, 'confirmed_refund');
            expect(details.confirmations, '2 confirmations');
            expect(details.receivedAsset.id, Asset.lbtc().id);
            expect(details.isLightning, true);
          },
          swap: (_) => fail('Should be receive, not swap'),
          peg: (_) => fail('Should be receive'),
          redeposit: (_) => fail('Should be receive'),
        );
      });
    });

    group('shouldShowTransactionForAsset', () {
      test('returns true for Boltz transaction on LBTC page', () async {
        final strategy = await getStrategy();
        final dbTxn = createMockDbTransaction(
          assetId: AssetIds.lightning, // Boltz txns have lightning assetId
          type: TransactionDbModelType.boltzSwap,
        );

        final args = TransactionStrategyArgs(
          asset: Asset.lbtc(), // Viewing LBTC page
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final result = strategy.shouldShowTransactionForAsset(args);

        expect(result, true,
            reason: 'Boltz transactions should show on LBTC page');
      });

      test('returns false for Boltz transaction on non-LBTC page', () async {
        final strategy = await getStrategy();
        final dbTxn = createMockDbTransaction(
          assetId: AssetIds.lightning, // Boltz txns have lightning assetId
          type: TransactionDbModelType.boltzSwap,
        );

        final args = TransactionStrategyArgs(
          asset: Asset.btc(), // Viewing BTC page
          availableAssets: [Asset.lbtc(), Asset.btc()],
          dbTransaction: dbTxn,
        );

        final result = strategy.shouldShowTransactionForAsset(args);

        expect(result, false,
            reason: 'Boltz transactions should only show on LBTC page');
      });

      test('returns false when dbTransaction is null', () async {
        final strategy = await getStrategy();
        final args = TransactionStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: null,
        );

        final result = strategy.shouldShowTransactionForAsset(args);

        expect(result, false);
      });

      test('works correctly for all Boltz transaction types on LBTC page',
          () async {
        final strategy = await getStrategy();
        final boltzTypes = [
          TransactionDbModelType.boltzSwap,
          TransactionDbModelType.boltzSendFailed,
          TransactionDbModelType.boltzReverseSwap,
          TransactionDbModelType.boltzRefund,
        ];

        for (final type in boltzTypes) {
          final dbTxn = createMockDbTransaction(
            assetId: AssetIds.lightning, // Boltz txns have lightning assetId
            type: type,
          );

          final args = TransactionStrategyArgs(
            asset: Asset.lbtc(), // Viewing LBTC page
            availableAssets: [Asset.lbtc()],
            dbTransaction: dbTxn,
          );

          final result = strategy.shouldShowTransactionForAsset(args);

          expect(result, true, reason: '$type should show on LBTC asset page');
        }
      });
    });

    group('createPendingListItems', () {
      test('returns pending list item for non-failed submarine swap', () async {
        final strategy = await getStrategy();
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          isGhost: true,
          ghostTxnAmount: -10000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        // Mock failure service to return false
        when(() => setup.mockTxnFailureService.isFailed(any()))
            .thenReturn(false);

        final args = TransactionStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final result = strategy.createPendingListItems(args);

        expect(result, isNotNull);
        expect(result!.isPending, true);
        result.map(
          normal: (_) => fail('Should be pending'),
          pending: (model) {
            expect(model.dbTransaction?.type, TransactionDbModelType.boltzSwap);
          },
        );
      });

      test(
          'returns null for failed submarine swap (should go to confirmed list)',
          () async {
        final strategy = await getStrategy();
        final dbTxn = createMockDbTransaction(
          txhash: 'failed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSendFailed,
          isGhost: true,
          ghostTxnAmount: -10000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        // Mock failure service to return true
        when(() => setup.mockTxnFailureService.isFailed(any()))
            .thenReturn(true);

        final args = TransactionStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final result = strategy.createPendingListItems(args);

        // Failed transactions should NOT appear in pending list
        expect(result, isNull);
      });
    });

    group('createConfirmedListItems', () {
      test('returns confirmed list item for confirmed submarine swap',
          () async {
        final strategy = await getStrategy();
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_ln_send',
          blockHeight: 100,
          satoshi: {Asset.lbtc().id: -10000000},
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          ghostTxnAmount: -10000000,
        );

        final args = TransactionStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = strategy.createConfirmedListItems(args);

        expect(result, isNotNull);
        expect(result!.isPending, false);
        result.map(
          normal: (model) {
            expect(model.transaction.txhash, 'confirmed_ln_send');
            expect(model.isFailed, false);
          },
          pending: (_) => fail('Should be normal'),
        );
      });

      test(
          'returns confirmed list item for failed submarine swap WITHOUT network transaction',
          () async {
        final strategy = await getStrategy();
        final dbTxn = createMockDbTransaction(
          txhash: 'failed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSendFailed,
          isGhost: true,
          ghostTxnAmount: -10000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        // Mock failure service to return true
        when(() => setup.mockTxnFailureService.isFailed(any()))
            .thenReturn(true);

        final args = TransactionStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          // No network transaction
        );

        final result = strategy.createConfirmedListItems(args);

        // Failed transactions should appear in confirmed list even without network transaction
        expect(result, isNotNull);
        expect(result!.isPending, false);
        result.map(
          normal: (model) {
            expect(model.transaction.txhash, 'failed_ln_send');
            expect(model.isFailed, true);
          },
          pending: (_) => fail('Should be normal'),
        );
      });
    });

    group('Fiat conversion', () {
      test(
          'createPendingDetails uses L-BTC asset for fiat conversion of Lightning amounts',
          () async {
        // Mock conversion provider to verify it's called with L-BTC asset
        Asset? capturedAmountAsset;
        int? capturedAmountValue;

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) {
              // Capture the call for the amount (5445 sats), not the fee
              if (params.$1.id == Asset.lbtc().id && params.$2 == 5445) {
                capturedAmountAsset = params.$1;
                capturedAmountValue = params.$2;
                return SatoshiToFiatConversionModel(
                  currencySymbol: '\$',
                  decimal: Decimal.parse('5.00'),
                  formatted: '5.00',
                  formattedWithCurrency: '\$5.00',
                );
              }
              // Return null for fee conversions
              return null;
            }),
          ],
        );

        // 5445 sats should convert to approximately $5.00 (assuming ~$100k BTC)
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          isGhost: true,
          ghostTxnAmount: 5445,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        await container.read(availableAssetsProvider.future);
        await container.read(boltzStorageProvider.future);
        final strategy = container.read(lightningTransactionUiModelsProvider);
        final result = await strategy.createPendingDetails(args);

        // Verify conversion was called with L-BTC asset (not Lightning asset)
        expect(capturedAmountAsset, isNotNull);
        expect(capturedAmountAsset!.id, Asset.lbtc().id,
            reason:
                'Fiat conversion should use L-BTC asset for Lightning amounts');
        expect(capturedAmountValue, 5445,
            reason: 'Fiat conversion should use the absolute amount in sats');

        // Verify fiat amount is included in the result
        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.deliverAmountFiat, isNotEmpty);
            expect(details.deliverAmountFiat, equals('\$5.00'));
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test(
          'createConfirmedDetails uses L-BTC asset for fiat conversion of Lightning amounts',
          () async {
        // Mock conversion provider to verify it's called with L-BTC asset
        Asset? capturedAmountAsset;
        int? capturedAmountValue;

        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) {
              // Capture the call for the amount (5445 + fee 21 sats), not the fee
              if (params.$1.id == Asset.lbtc().id && params.$2 == 5466) {
                capturedAmountAsset = params.$1;
                capturedAmountValue = params.$2;
                return SatoshiToFiatConversionModel(
                  currencySymbol: '\$',
                  decimal: Decimal.parse('5.00'),
                  formatted: '5.00',
                  formattedWithCurrency: '\$5.00',
                );
              }
              // Return null for fee conversions
              return null;
            }),
          ],
        );

        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_ln_send',
          blockHeight: 100,
          fee: 21,
        );

        // 5445 sats should convert to approximately $5.00
        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          ghostTxnAmount: 5445,
          ghostTxnSideswapDeliverAmount: 5424,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        await container.read(availableAssetsProvider.future);
        await container.read(boltzStorageProvider.future);
        final strategy = container.read(lightningTransactionUiModelsProvider);
        final result = await strategy.createConfirmedDetails(args);

        // Verify conversion was called with L-BTC asset (not Lightning asset)
        expect(capturedAmountAsset, isNotNull);
        expect(capturedAmountAsset!.id, Asset.lbtc().id,
            reason:
                'Fiat conversion should use L-BTC asset for Lightning amounts');
        expect(capturedAmountValue, 5466,
            reason: 'Fiat conversion should use the absolute amount in sats');

        // Verify fiat amount is included in the result
        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.deliverAmountFiat, isNotEmpty);
            expect(details.deliverAmountFiat, equals('\$5.00'));
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test(
          'createPendingDetails correctly converts larger Lightning amounts to fiat',
          () async {
        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) {
              // For 100000000 sats (1 BTC), return $100,000
              if (params.$1.id == Asset.lbtc().id && params.$2 == 100000000) {
                return SatoshiToFiatConversionModel(
                  currencySymbol: '\$',
                  decimal: Decimal.parse('100000.00'),
                  formatted: '100,000.00',
                  formattedWithCurrency: '\$100,000.00',
                );
              }
              return null;
            }),
          ],
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_ln_large',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzReverseSwap,
          isGhost: true,
          ghostTxnAmount: 100000000, // 1 BTC
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        await container.read(availableAssetsProvider.future);
        await container.read(boltzStorageProvider.future);
        final strategy = container.read(lightningTransactionUiModelsProvider);
        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be receive'),
          receive: (details) {
            expect(details.receivedAmountFiat, equals('\$100,000.00'));
          },
          swap: (_) => fail('Should be receive'),
          peg: (_) => fail('Should be receive'),
          redeposit: (_) => fail('Should be receive'),
        );
      });

      test('fiat conversion handles null conversion provider gracefully',
          () async {
        container = setup.createContainer(
          additionalOverrides: [
            conversionProvider.overrideWith((ref, params) => null),
          ],
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_ln_no_fiat',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          isGhost: true,
          ghostTxnAmount: 5445,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        await container.read(availableAssetsProvider.future);
        await container.read(boltzStorageProvider.future);
        final strategy = container.read(lightningTransactionUiModelsProvider);
        final result = await strategy.createPendingDetails(args);

        // Should not crash, but fiat amount should be empty
        expect(result, isNotNull);
        result!.map(
          send: (details) {
            expect(details.deliverAmountFiat, isEmpty);
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });
    });

    group('Fee calculations', () {
      test('submarine swap (send) fee equals boltzFee + networkFee', () async {
        // Scenario: Phoenix requests 1235 sats
        // - Boltz fee: 21 sats
        // - Aqua user sends to Boltz: 1235 + 21 = 1256 sats (ghostTxnAmount)
        // - Liquid network fee: 30 sats
        // - Total fees: 21 + 30 = 51 sats
        // - Total amount sent: 1235 + 51 = 1286 sats
        final networkTxn = createMockNetworkTransaction(
          txhash: 'submarine_swap_fee_test',
          blockHeight: 100,
          fee: 30, // Liquid network fee
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'submarine_swap_fee_test',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          ghostTxnAmount:
              1256, // Amount sent to Boltz (absolute value: recipient gets + boltz fee)
          ghostTxnSideswapDeliverAmount:
              1235, // What Phoenix/recipient receives
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Fee should be formatted as 51 sats / 100000000 = 5.1e-7
            expect(details.feeAmount, '5.1e-7',
                reason:
                    'Fee should be boltzFee (21) + networkFee (30) = 51 sats');
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('reverse swap (receive) fee equals invoiceAmount - receivedAmount',
          () async {
        // Scenario: Aqua user requests 1234 sats
        // - Fee subtracted: 50 sats (includes Boltz fee and Liquid network fees)
        // - Aqua user receives: 1234 - 50 = 1184 sats on-chain
        final networkTxn = createMockNetworkTransaction(
          txhash: 'reverse_swap_fee_test',
          blockHeight: 100,
          outputs: [
            const GdkTransactionInOut(
              satoshi: 1184, // What user receives on-chain
              isRelevant: true,
            ),
          ],
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'reverse_swap_fee_test',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzReverseSwap,
          ghostTxnAmount: 1234, // Invoice amount (what user requested)
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be receive'),
          receive: (details) {
            // Fee should be formatted as 50 sats / 100000000 = 5.0e-7
            expect(details.feeAmount, '5e-7',
                reason:
                    'Fee should be invoiceAmount (1234) - receivedAmount (1184) = 50 sats');
          },
          swap: (_) => fail('Should be receive'),
          peg: (_) => fail('Should be receive'),
          redeposit: (_) => fail('Should be receive'),
        );
      });

      test('refund does not include fee information', () async {
        // Scenario: Failed submarine swap refund
        // - Original amount sent: 1256 sats
        // - Refund received: 1200 sats
        // - Fee info not shown for refunds (user already lost funds)
        final networkTxn = createMockNetworkTransaction(
          txhash: 'refund_fee_test',
          blockHeight: 100,
          satoshi: {Asset.lbtc().id: 1200},
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'refund_fee_test',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzRefund,
          ghostTxnAmount: 1256,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be receive'),
          receive: (details) {
            // Refund should not have fee information
            expect(details.feeAmount, isNull,
                reason: 'Refund should not include fee information');
            expect(details.feeAmountFiat, isNull,
                reason: 'Refund should not include fee fiat information');
          },
          swap: (_) => fail('Should be receive'),
          peg: (_) => fail('Should be receive'),
          redeposit: (_) => fail('Should be receive'),
        );
      });

      test(
          'submarine swap pending transaction shows only boltzFee when no network transaction',
          () async {
        // Scenario: Pending Lightning Send (no network transaction yet)
        // - Phoenix requests: 1235 sats
        // - Boltz fee: 21 sats
        // - Amount sent to Boltz: 1256 sats
        // - Network fee: unknown (0) since transaction not broadcast yet
        // - Displayed fee: only Boltz fee (21 sats)
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_submarine_fee_test',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          isGhost: true,
          ghostTxnAmount: 1256, // Amount sent to Boltz
          ghostTxnSideswapDeliverAmount: 1235, // What recipient receives
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc()],
          dbTransaction: dbTxn,
        );

        final strategy = await getStrategy();
        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (details) {
            // Without network transaction, networkFee = 0
            // boltzFee = 1256 - 1235 = 21 sats
            // totalFee = 21 + 0 = 21 sats
            expect(details.feeAmount, '2.1e-7',
                reason:
                    'Pending fee should be boltzFee only (21 sats) when no network transaction');
          },
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });
    });

    group('Notes', () {
      test('pending transaction includes note from dbTransaction', () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          isGhost: true,
          ghostTxnAmount: 10000,
          ghostTxnCreatedAt: DateTime.now(),
          note: 'paying for coffee',
        );

        final strategy = await getStrategy();
        final result = await strategy.createPendingDetails(
          TransactionDetailsStrategyArgs(
            asset: Asset.lbtc(),
            availableAssets: [Asset.lbtc()],
            dbTransaction: dbTxn,
          ),
        );

        result!.map(
          send: (d) => expect(d.notes, 'paying for coffee'),
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('confirmed transaction prefers dbTransaction note over network memo',
          () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          ghostTxnAmount: 10000,
          note: 'my note',
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(
          TransactionDetailsStrategyArgs(
            asset: Asset.lbtc(),
            availableAssets: [Asset.lbtc()],
            dbTransaction: dbTxn,
            networkTransaction: createMockNetworkTransaction(
              txhash: 'confirmed_ln_send',
              blockHeight: 100,
              memo: 'network memo',
            ),
          ),
        );

        result!.map(
          send: (d) => expect(d.notes, 'my note'),
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });

      test('confirmed transaction falls back to network memo when no db note',
          () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_ln_send',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.boltzSwap,
          ghostTxnAmount: 10000,
        );

        final strategy = await getStrategy();
        final result = await strategy.createConfirmedDetails(
          TransactionDetailsStrategyArgs(
            asset: Asset.lbtc(),
            availableAssets: [Asset.lbtc()],
            dbTransaction: dbTxn,
            networkTransaction: createMockNetworkTransaction(
              txhash: 'confirmed_ln_send',
              blockHeight: 100,
              memo: 'network memo',
            ),
          ),
        );

        result!.map(
          send: (d) => expect(d.notes, 'network memo'),
          receive: (_) => fail('Should be send'),
          swap: (_) => fail('Should be send'),
          peg: (_) => fail('Should be send'),
          redeposit: (_) => fail('Should be send'),
        );
      });
    });
  });
}
