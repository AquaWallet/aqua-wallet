import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
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

  group('Database Storage Behavior', () {
    test('incoming transactions are NOT stored in database', () async {
      final scenario = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 0)
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txns = await readTransactions(container, Asset.usdtLiquid());
      expect(txns, hasLength(1));

      final dbTxns = container.read(transactionStorageProvider).value ?? [];
      final txn = dbTxns
          .where((t) =>
              t.assetId == Asset.usdtLiquid().id &&
              t.type != TransactionDbModelType.aquaSend)
          .toList();

      expect(txn, isEmpty);

      container.dispose();
    });

    test('outgoing transactions stored in database', () async {
      const txHash = 'usdt_send_123';
      final scenario = TransactionScenarioHarness()
          .withUsdtOutgoing(
            amount: 10000000000,
            confirmations: 0,
            txhash: txHash,
            createDbEntry: true,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txns = await readTransactions(container, Asset.usdtLiquid());
      expect(txns, hasLength(1));

      final dbTxns = container.read(transactionStorageProvider).value ?? [];
      final txn = dbTxns
          .where((t) =>
              t.assetId == Asset.usdtLiquid().id &&
              t.type == TransactionDbModelType.aquaSend)
          .toList();

      expect(txn, isNotEmpty);

      container.dispose();
    });

    group('Precision', () {
      test('Uses special precision for USDt', () async {
        final scenario = TransactionScenarioHarness()
            .withUsdtIncoming(amount: 10000000000, confirmations: 2)
            .build();

        final container = scenario.createContainer(
          formatService: setup.mockFormatService,
          txnFailureService: setup.mockTxnFailureService,
        );

        final txns = await readTransactions(container, Asset.usdtLiquid());
        expect(txns, hasLength(1));

        txns.first.map(
          normal: (model) {
            expect(model.asset.isUSDt, isTrue);
            expect(model.cryptoAmount, isNotEmpty);
          },
          pending: (_) => fail('Should be confirmed'),
        );

        container.dispose();
      });
    });
  });
}
