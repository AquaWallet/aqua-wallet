import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transaction_scenario_test_harness.dart';
import 'transactions_provider_test_helper.dart';

void main() {
  final setup = TransactionsTestSetup();

  setUpAll(() {
    setUpTransactionsTestSuite();
  });

  setUp(() {
    setup.setUpMocks();
  });

  group('Swap Transactions', () {
    group('Sideswap Swaps (L-BTC ↔ USDt)', () {
      test('pending swap shows on both asset sides (L-BTC out, USDt in)',
          () async {
        final scenario = TransactionScenarioHarness()
            .withLbtcSwapToUsdt(
              lbtcAmount: 50000000,
              usdtAmount: 10000000000,
              confirmations: 0,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        // Check L-BTC side (outgoing)
        final lbtcTxns = await readTransactions(container, Asset.lbtc());
        expect(lbtcTxns, hasLength(1));
        lbtcTxns.first.map(
          normal: (_) => fail('Should be pending with 0 confirmations'),
          pending: (model) {
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
            expect(model.cryptoAmount, contains('-')); // Outgoing
          },
        );

        // Check USDt side (incoming)
        final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
        expect(usdtTxns, hasLength(1));
        usdtTxns.first.map(
          normal: (_) => fail('Should be pending with 0 confirmations'),
          pending: (model) {
            // asset is always fromAsset (LBTC), not the current page's asset
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
            expect(model.cryptoAmount, contains('+')); // Incoming
          },
        );

        container.dispose();
      });

      test('confirmed swap shows normal on both sides', () async {
        final scenario = TransactionScenarioHarness()
            .withLbtcSwapToUsdt(
              lbtcAmount: 50000000,
              usdtAmount: 10000000000,
              confirmations: 2,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final lbtcTxns = await readTransactions(container, Asset.lbtc());
        final usdtTxns = await readTransactions(container, Asset.usdtLiquid());

        expect(lbtcTxns, hasLength(1));
        lbtcTxns.first.map(
          normal: (model) {
            // asset is always fromAsset (LBTC), regardless of page
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
          },
          pending: (_) => fail('Should be confirmed with 2 confirmations'),
        );

        expect(usdtTxns, hasLength(1));
        usdtTxns.first.map(
          normal: (model) {
            // asset is always fromAsset (LBTC), even on USDt page
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
          },
          pending: (_) => fail('Should be confirmed with 2 confirmations'),
        );

        container.dispose();
      });

      test('pending swap shows on both asset sides (USDt out, L-BTC in)',
          () async {
        final scenario = TransactionScenarioHarness()
            .withUsdtSwapToLbtc(
              usdtAmount: 10000000000,
              lbtcAmount: 50000000,
              confirmations: 0,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        // USDt side (outgoing)
        final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
        expect(usdtTxns, hasLength(1));
        usdtTxns.first.map(
          normal: (_) => fail('Should be pending with 0 confirmations'),
          pending: (model) {
            expect(model.asset.id, Asset.usdtLiquid().id);
            expect(model.otherAsset?.id, Asset.lbtc().id);
            expect(model.cryptoAmount, contains('-'));
            expect(model.transactionId, isNotNull);
          },
        );

        // L-BTC side (incoming)
        final lbtcTxns = await readTransactions(container, Asset.lbtc());
        expect(lbtcTxns, hasLength(1));
        lbtcTxns.first.map(
          normal: (_) => fail('Should be pending with 0 confirmations'),
          pending: (model) {
            expect(model.asset.id, Asset.usdtLiquid().id);
            expect(model.otherAsset?.id, Asset.lbtc().id);
            expect(model.cryptoAmount, contains('+'));
            expect(model.transactionId, isNotNull);
            expect(
              model.transactionId,
              usdtTxns.first.map(
                normal: (_) => null,
                pending: (p) => p.transactionId,
              ),
            );
          },
        );

        container.dispose();
      });

      test(
          'When USDt to L-BTC is swapped, pending transaction appears for both assets',
          () async {
        final scenario = TransactionScenarioHarness()
            .withUsdtSwapToLbtc(
              usdtAmount: 5000000000,
              lbtcAmount: 25000000,
              confirmations: 0,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        // Assert: USDt side has pending transaction
        final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
        expect(usdtTxns, hasLength(1));
        expect(usdtTxns.first.isPending, isTrue);

        // Assert: L-BTC side has pending transaction
        final lbtcTxns = await readTransactions(container, Asset.lbtc());
        expect(lbtcTxns, hasLength(1));
        expect(lbtcTxns.first.isPending, isTrue);

        // Verify transaction details match swap
        usdtTxns.first.map(
          normal: (_) => fail('Should be pending'),
          pending: (usdtModel) {
            lbtcTxns.first.map(
              normal: (_) => fail('Should be pending'),
              pending: (lbtcModel) {
                expect(usdtModel.transactionId, lbtcModel.transactionId);
                expect(usdtModel.asset.id, Asset.usdtLiquid().id);
                expect(lbtcModel.asset.id, Asset.usdtLiquid().id);
                expect(usdtModel.otherAsset?.id, Asset.lbtc().id);
                expect(lbtcModel.otherAsset?.id, Asset.lbtc().id);
                expect(usdtModel.cryptoAmount, contains('-'));
                expect(lbtcModel.cryptoAmount, contains('+'));
              },
            );
          },
        );

        container.dispose();
      });

      test(
          'When L-BTC to USDt is swapped, transaction appears for both assets in pending state',
          () async {
        final scenario = TransactionScenarioHarness()
            .withLbtcSwapToUsdt(
              lbtcAmount: 50000000,
              usdtAmount: 10000000000,
              confirmations: 0,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final lbtcTxns = await readTransactions(container, Asset.lbtc());
        expect(lbtcTxns, hasLength(1));
        expect(lbtcTxns.first.isPending, isTrue);
        lbtcTxns.first.map(
          normal: (_) => fail('Should be pending'),
          pending: (model) {
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
            expect(model.cryptoAmount, contains('-'));
          },
        );

        final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
        expect(usdtTxns, hasLength(1));
        expect(usdtTxns.first.isPending, isTrue);
        usdtTxns.first.map(
          normal: (_) => fail('Should be pending'),
          pending: (model) {
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
            expect(model.cryptoAmount, contains('+'));
            expect(
              model.transactionId,
              lbtcTxns.first.map(
                normal: (_) => null,
                pending: (p) => p.transactionId,
              ),
            );
          },
        );

        container.dispose();
      });

      test(
          'When L-BTC to USDt is swapped, transaction appears for both assets in confirmed state',
          () async {
        final scenario = TransactionScenarioHarness()
            .withLbtcSwapToUsdt(
              lbtcAmount: 50000000,
              usdtAmount: 10000000000,
              confirmations: 2,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final lbtcTxns = await readTransactions(container, Asset.lbtc());
        expect(lbtcTxns, hasLength(1));
        expect(lbtcTxns.first.isPending, isFalse);
        String? lbtcTxHash;
        lbtcTxns.first.map(
          normal: (model) {
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
            expect(model.cryptoAmount, contains('-'));
            lbtcTxHash = model.transaction.txhash;
            expect(lbtcTxHash, isNotNull);
          },
          pending: (_) => fail('Should be confirmed'),
        );

        final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
        expect(usdtTxns, hasLength(1));
        expect(usdtTxns.first.isPending, isFalse);
        usdtTxns.first.map(
          normal: (model) {
            expect(model.asset.id, Asset.lbtc().id);
            expect(model.otherAsset?.id, Asset.usdtLiquid().id);
            expect(model.cryptoAmount, contains('+'));
            expect(model.transaction.txhash, lbtcTxHash);
          },
          pending: (_) => fail('Should be confirmed'),
        );

        container.dispose();
      });

      test(
          'When USDt to L-BTC is swapped, transaction appears for both assets in confirmed state',
          () async {
        final scenario = TransactionScenarioHarness()
            .withUsdtSwapToLbtc(
              usdtAmount: 10000000000,
              lbtcAmount: 50000000,
              confirmations: 2,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
        expect(usdtTxns, hasLength(1));
        expect(usdtTxns.first.isPending, isFalse);
        String? usdtTxHash;
        usdtTxns.first.map(
          normal: (model) {
            expect(model.asset.id, Asset.usdtLiquid().id);
            expect(model.otherAsset?.id, Asset.lbtc().id);
            expect(model.cryptoAmount, contains('-'));
            usdtTxHash = model.transaction.txhash;
            expect(usdtTxHash, isNotNull);
          },
          pending: (_) => fail('Should be confirmed'),
        );

        final lbtcTxns = await readTransactions(container, Asset.lbtc());
        expect(lbtcTxns, hasLength(1));
        expect(lbtcTxns.first.isPending, isFalse);
        lbtcTxns.first.map(
          normal: (model) {
            expect(model.asset.id, Asset.usdtLiquid().id);
            expect(model.otherAsset?.id, Asset.lbtc().id);
            expect(model.cryptoAmount, contains('+'));
            expect(model.transaction.txhash, usdtTxHash);
          },
          pending: (_) => fail('Should be confirmed'),
        );

        container.dispose();
      });
    });

    group('Sideshift Swaps (Alt USDt Assets)', () {
      test('pending Sideshift swap shows on receiving asset side', () async {
        final scenario = TransactionScenarioHarness()
            .withSideshiftSwap(
              fromAsset: Asset.usdtLiquid(),
              toAsset: Asset.usdtEth(),
              fromAmount: 10000000000,
              toAmount: 9500000000,
              status: SwapOrderStatus.processing,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final usdtEthTxns = await readTransactions(container, Asset.usdtEth());
        expect(usdtEthTxns, hasLength(1));
        expect(usdtEthTxns.first.isPending, isTrue);
        usdtEthTxns.first.map(
          normal: (_) => fail('Should be pending'),
          pending: (model) {
            expect(model.asset.id, Asset.usdtEth().id);
            expect(model.cryptoAmount, contains('+'));
            expect(model.transactionId, isNotNull);
          },
        );

        container.dispose();
      });

      test('confirmed Sideshift swap shows normal transaction', () async {
        final scenario = TransactionScenarioHarness()
            .withSideshiftSwap(
              fromAsset: Asset.usdtLiquid(),
              toAsset: Asset.usdtTrx(),
              fromAmount: 5000000000,
              toAmount: 4750000000,
              status: SwapOrderStatus.completed,
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final usdtTrxTxns = await readTransactions(container, Asset.usdtTrx());
        expect(usdtTrxTxns.length, greaterThanOrEqualTo(0));

        container.dispose();
      });
    });

    group('Changelly Swaps (Alt USDt Assets)', () {
      test('pending Changelly swap shows on receiving asset side', () async {
        final scenario = TransactionScenarioHarness()
            .withChangellySwap(
              fromAsset: Asset.usdtLiquid(),
              toAsset: Asset.usdtBep(),
              fromAmount: 10000000000,
              toAmount: 9500000000,
              status: SwapOrderStatus.processing,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final usdtBepTxns = await readTransactions(container, Asset.usdtBep());
        expect(usdtBepTxns, hasLength(1));
        expect(usdtBepTxns.first.isPending, isTrue);
        usdtBepTxns.first.map(
          normal: (_) => fail('Should be pending'),
          pending: (model) {
            expect(model.asset.id, Asset.usdtBep().id);
            expect(model.cryptoAmount, contains('+'));
            expect(model.transactionId, isNotNull);
          },
        );

        container.dispose();
      });

      test('pending Changelly swap with different status shows correctly',
          () async {
        final scenario = TransactionScenarioHarness()
            .withChangellySwap(
              fromAsset: Asset.usdtLiquid(),
              toAsset: Asset.usdtSol(),
              fromAmount: 20000000000,
              toAmount: 19000000000,
              status: SwapOrderStatus.exchanging,
            )
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final usdtSolTxns = await readTransactions(container, Asset.usdtSol());
        expect(usdtSolTxns, hasLength(1));
        expect(usdtSolTxns.first.isPending, isTrue);

        container.dispose();
      });
    });
  });
}
