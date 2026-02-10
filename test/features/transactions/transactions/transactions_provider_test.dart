/// Transaction Provider Tests - Split into separate files by transaction type
///
/// This file contains general tests that are not specific to a single asset or transaction type.
/// Asset/transaction-specific tests are organized into separate files:
/// - receive_transactions_test.dart - Incoming BTC/L-BTC/USDt transactions
/// - send_transactions_test.dart - Outgoing BTC/L-BTC/USDt transactions
/// - lightning_transactions_test.dart - Lightning transactions
/// - sideswap_swaps_test.dart - Sideswap swaps (L-BTC ↔ USDt)
/// - alt_usdt_swaps_test.dart - Alt USDt swaps (Sideshift/Changelly)
/// - peg_transactions_test.dart - Peg transactions
///
/// Flutter test runner will automatically discover and run all test files in this directory.
library;

import 'package:aqua/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
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

  group('Failed Transactions', () {
    test('failed transaction is marked correctly', () async {
      final failedTxnService = MockTxnFailureService();
      when(() => failedTxnService.isFailed(any())).thenReturn(true);

      final scenario = TransactionScenarioHarness()
          .withBtcIncoming(amount: 100000000, confirmations: 6)
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: failedTxnService,
      );

      final btcTxns = await readTransactions(container, Asset.btc());

      expect(btcTxns, hasLength(1));
      btcTxns.first.map(
        normal: (model) => expect(model.isFailed, isTrue),
        pending: (_) {},
      );

      container.dispose();
    });

    test('failed pending transaction is still shown', () async {
      final failedTxnService = MockTxnFailureService();
      when(() => failedTxnService.isFailed(any())).thenReturn(true);

      final scenario = TransactionScenarioHarness()
          .withBtcIncoming(amount: 100000000, confirmations: 0)
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: failedTxnService,
      );

      final btcTxns = await readTransactions(container, Asset.btc());

      // Pending transactions don't have isFailed property, but they are still shown
      expect(btcTxns, hasLength(1));
      btcTxns.first.map(
        normal: (_) => fail('Should be pending'),
        pending: (model) => expect(model.asset.id, Asset.btc().id),
      );

      container.dispose();
    });
  });

  group('Mixed Transaction States', () {
    test('pending transactions appear before confirmed transactions', () async {
      final now = DateTime.now();
      final scenario = TransactionScenarioHarness()
          .withBtcIncoming(
            amount: 100000000,
            confirmations: 1, // Confirmed (meets threshold of 1)
            timestamp: now.subtract(const Duration(hours: 2)),
          )
          .withBtcIncoming(
            amount: 50000000,
            confirmations: 0, // Pending
            timestamp: now.subtract(const Duration(minutes: 5)),
          )
          .withBtcOutgoing(
            amount: 25000000,
            confirmations: 0, // Pending (needs 1)
            timestamp: now.subtract(const Duration(hours: 1)),
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final btcTxns = await readTransactions(container, Asset.btc());

      expect(btcTxns, hasLength(3));

      // First two should be pending
      btcTxns[0].map(
        normal: (_) => fail('First should be pending'),
        pending: (_) {},
      );

      btcTxns[1].map(
        normal: (_) => fail('Second should be pending'),
        pending: (_) {},
      );

      // Third should be confirmed
      btcTxns[2].map(
        normal: (_) {},
        pending: (_) => fail('Third should be confirmed'),
      );

      container.dispose();
    });

    test('multiple assets with mixed states', () async {
      final scenario = TransactionScenarioHarness()
          .withBtcIncoming(amount: 100000000, confirmations: 6)
          .withBtcIncoming(amount: 50000000, confirmations: 0)
          .withLbtcIncoming(amount: 100000000, confirmations: 2)
          .withLbtcIncoming(amount: 50000000, confirmations: 0)
          .withUsdtIncoming(amount: 10000000000, confirmations: 2)
          .withUsdtIncoming(amount: 5000000000, confirmations: 0)
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Each asset should have 2 transactions
      final btcTxns = await readTransactions(container, Asset.btc());
      expect(btcTxns, hasLength(2));

      final lbtcTxns = await readTransactions(container, Asset.lbtc());
      expect(lbtcTxns, hasLength(2));

      final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
      expect(usdtTxns, hasLength(2));

      // Each should have 1 pending, 1 confirmed
      for (final txns in [btcTxns, lbtcTxns, usdtTxns]) {
        var pendingCount = 0;
        var confirmedCount = 0;

        for (final txn in txns) {
          txn.map(
            normal: (_) => confirmedCount++,
            pending: (_) => pendingCount++,
          );
        }

        expect(pendingCount, 1);
        expect(confirmedCount, 1);
      }

      container.dispose();
    });
  });
}
