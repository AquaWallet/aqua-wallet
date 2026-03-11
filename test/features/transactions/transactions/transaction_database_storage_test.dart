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

  group('Transaction Database Storage', () {
    test('incoming transaction does NOT appear from database', () async {
      final scenario = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 0)
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final dbTxns = container.read(transactionStorageProvider).value ?? [];
      final txn = dbTxns
          .where((t) =>
              t.assetId == Asset.usdtLiquid().id &&
              t.type != TransactionDbModelType.aquaSend)
          .toList();

      expect(txn, isEmpty);

      container.dispose();
    });

    test('incoming transaction appears as pending with 0 confirmations',
        () async {
      final scenario = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 0)
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txns = await readTransactions(container, Asset.usdtLiquid());

      expect(txns, hasLength(1));
      expect(txns.first.isPending, isTrue);
      txns.first.map(
        normal: (_) => fail('Should be pending with 0 confirmations'),
        pending: (model) {
          expect(model.asset.id, Asset.usdtLiquid().id);
          expect(model.cryptoAmount, contains('+'));
          expect(model.transactionId, isNotNull);
          expect(model.dbTransaction, isNull);
        },
      );

      container.dispose();
    });

    test(
        'incoming transaction transitions to confirmed when confirmations cross threshold',
        () async {
      final scenarioPending = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 0)
          .build();

      final containerPending = scenarioPending.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txnsPending =
          await readTransactions(containerPending, Asset.usdtLiquid());
      expect(txnsPending, hasLength(1));
      expect(txnsPending.first.isPending, isTrue);

      containerPending.dispose();

      final scenarioConfirmed = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 1)
          .build();

      final containerConfirmed = scenarioConfirmed.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txnsConfirmed =
          await readTransactions(containerConfirmed, Asset.usdtLiquid());

      expect(txnsConfirmed, hasLength(1));
      expect(txnsConfirmed.first.isPending, isFalse);
      txnsConfirmed.first.map(
        normal: (model) {
          expect(model.asset.id, Asset.usdtLiquid().id);
          expect(model.cryptoAmount, contains('+'));
          expect(model.transaction.txhash, isNotNull);
        },
        pending: (_) => fail('Should be confirmed with >= 1 confirmation'),
      );

      final pendingCount = txnsConfirmed.where((t) => t.isPending).length;
      final normalCount = txnsConfirmed.where((t) => !t.isPending).length;
      expect(pendingCount, 0);
      expect(normalCount, 1);

      containerConfirmed.dispose();
    });

    test(
        'incoming transaction lifecycle: 0 confirmations -> pending, 1 confirmation -> confirmed',
        () async {
      final scenarioStage1 = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 0)
          .build();

      final containerStage1 = scenarioStage1.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txns1 = await readTransactions(containerStage1, Asset.usdtLiquid());
      expect(txns1, hasLength(1));
      expect(txns1.first.isPending, isTrue);

      final scenarioStage2 = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 1)
          .build();

      final containerStage2 = scenarioStage2.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txns2 = await readTransactions(containerStage2, Asset.usdtLiquid());
      expect(txns2, hasLength(1));
      expect(txns2.first.isPending, isFalse);

      containerStage1.dispose();
      containerStage2.dispose();
    });

    test(
        'incoming transaction does not duplicate between pending and confirmed',
        () async {
      final scenario = TransactionScenarioHarness()
          .withUsdtIncoming(amount: 10000000000, confirmations: 2)
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final txns = await readTransactions(container, Asset.usdtLiquid());

      expect(txns, hasLength(1));
      expect(txns.first.isPending, isFalse);

      final pendingTxns = txns.where((t) => t.isPending).toList();
      final confirmedTxns = txns.where((t) => !t.isPending).toList();

      expect(pendingTxns, isEmpty);
      expect(confirmedTxns, hasLength(1));

      container.dispose();
    });
  });
}
