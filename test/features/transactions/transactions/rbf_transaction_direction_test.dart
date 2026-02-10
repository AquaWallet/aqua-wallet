import 'package:aqua/data/data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'asset_transaction_test_infrastructure.dart';
import 'transactions_provider_test_helper.dart';

// Test suite specifically for RBF transaction direction bug
//
// Bug: After a successful RBF (Replace-By-Fee) transaction for BTC,
// the transaction list shows "Receiving" instead of "Sending".
//
// Root cause: When an RBF transaction is broadcast, it creates a new
// transaction ID, but the database entry is not updated to reference
// the new transaction. This causes the system to lose the aquaSend
// type marker, and the transaction direction is incorrectly inferred
// from the network transaction alone.
void main() {
  final setup = TransactionsTestSetup();

  setUpAll(() {
    setUpTransactionsTestSuite();
  });

  setUp(() {
    setup.setUpMocks();
  });

  group('RBF Transaction Direction Bug', () {
    final config = AssetTestConfig.btc();

    test('outgoing transaction shows correct direction before RBF', () async {
      // Setup: Create an outgoing BTC transaction
      const originalTxHash = 'btc_send_original';
      final scenario = TransactionScenarioBuilder(config, setup);

      final result = await scenario
          .outgoing(
            amount: 100000000, // 1 BTC
            confirmations: 0, // Pending
            txhash: originalTxHash,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      // Verify: Transaction is pending and shows as outgoing (negative amount)
      result.expectSingleTransaction();
      result.expectPending();
      result.expectAmountSign(isNegative: true);

      result.dispose();
    });

    test('outgoing transaction maintains correct direction after RBF',
        () async {
      // Setup: Simulate RBF scenario where original transaction is replaced
      const originalTxHash = 'btc_send_original';
      const rbfTxHash = 'btc_send_rbf_replacement';

      // Step 1: Original transaction exists in database with aquaSend type
      var scenario = TransactionScenarioBuilder(config, setup);
      final originalResult = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: originalTxHash,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      originalResult.expectSingleTransaction();
      originalResult.expectPending();
      originalResult.expectAmountSign(isNegative: true);
      originalResult.dispose();

      // Step 2: After RBF, new transaction appears on network
      // but database still references old transaction
      //
      // BUG SCENARIO: Database entry has originalTxHash with aquaSend type,
      // but network only has rbfTxHash. The system can't match them,
      // so it treats rbfTxHash as a new transaction without the
      // aquaSend marker.
      scenario = TransactionScenarioBuilder(config, setup);
      final rbfResult = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: originalTxHash, // Old transaction still in DB
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: rbfTxHash, // New RBF transaction on network
          )
          .build();

      // We now have 2 transactions showing:
      // 1. Original (with DB entry) - shows correctly as outgoing
      // 2. RBF replacement (without DB entry) - relies on GDK transaction type
      expect(rbfResult.transactions.length, 2);

      // Find the RBF replacement transaction (without DB entry)
      final rbfTxn = rbfResult.transactions.firstWhere((txn) {
        final txId = txn.map(
          pending: (tx) => tx.transactionId,
          normal: (tx) => tx.transaction.txhash,
        );
        return txId == rbfTxHash;
      });

      // Check that the RBF transaction (without DB marker) still shows as outgoing
      final rbfAmount = rbfTxn.map(
        pending: (tx) => tx.cryptoAmount,
        normal: (tx) => tx.cryptoAmount,
      );

      expect(
        rbfAmount.startsWith('-'),
        isTrue,
        reason:
            'RBF transaction without DB entry should still show as outgoing based on GDK transaction type',
      );

      rbfResult.dispose();
    });

    test('RBF transaction with database update shows correct direction (fixed)',
        () async {
      // Setup: Simulate correct RBF scenario where database is properly updated
      const rbfTxHash = 'btc_send_rbf_replacement';
      final scenario = TransactionScenarioBuilder(config, setup);

      // After RBF with proper database update:
      // - Network has the new RBF transaction
      // - Database entry references the new RBF transaction hash
      // FIX: Database entry is updated to reference new RBF transaction hash
      final rbfResult = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: rbfTxHash,
          )
          .withDbEntry(
            type: TransactionDbModelType.aquaSend,
            txhash: rbfTxHash, // DB entry has the new transaction hash
          )
          .build();

      // EXPECTED: Transaction correctly shows as outgoing
      rbfResult.expectSingleTransaction();
      rbfResult.expectPending();
      rbfResult.expectAmountSign(isNegative: true); // Should pass

      rbfResult.dispose();
    });

    test('confirmed RBF transaction shows correct direction', () async {
      // Test that once an RBF transaction is confirmed,
      // it still maintains correct direction
      const rbfTxHash = 'btc_send_rbf_confirmed';
      final scenario = TransactionScenarioBuilder(config, setup);

      final result = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 6, // Confirmed
            txhash: rbfTxHash,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      result.expectSingleTransaction();
      result.expectConfirmed();
      result.expectAmountSign(isNegative: true);

      result.dispose();
    });

    test('RBF transaction details show send type not receive', () async {
      // Test that transaction details correctly identify as send transaction
      const rbfTxHash = 'btc_send_rbf_details';
      final scenario = TransactionScenarioBuilder(config, setup);

      final result = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: rbfTxHash,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      // Just verify transaction shows as outgoing (negative amount)
      result.expectSingleTransaction();
      result.expectPending();
      result.expectAmountSign(isNegative: true);

      result.dispose();
    });

    test('multiple RBF attempts maintain correct direction', () async {
      // Test scenario where a transaction is RBF'd multiple times
      const originalTxHash = 'btc_send_original';
      const rbf1TxHash = 'btc_send_rbf_1';
      const rbf2TxHash = 'btc_send_rbf_2';
      final scenario = TransactionScenarioBuilder(config, setup);

      // Original transaction
      final originalResult = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: originalTxHash,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      originalResult.expectAmountSign(isNegative: true);
      originalResult.dispose();

      // First RBF
      final rbf1Result = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: rbf1TxHash,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      rbf1Result.expectAmountSign(isNegative: true);
      rbf1Result.dispose();

      // Second RBF
      final rbf2Result = await scenario
          .outgoing(
            amount: 100000000,
            confirmations: 0,
            txhash: rbf2TxHash,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      rbf2Result.expectAmountSign(isNegative: true);
      rbf2Result.dispose();
    });
  });

  group('RBF Transaction Amount Sign Verification', () {
    final config = AssetTestConfig.btc();

    test('outgoing transaction always shows negative amount', () async {
      final scenario = TransactionScenarioBuilder(config, setup);

      final result = await scenario
          .outgoing(
            amount: 50000000,
            confirmations: 0,
          )
          .withDbEntry(type: TransactionDbModelType.aquaSend)
          .build();

      final txn = result.transactions.first;
      final cryptoAmount = txn.map(
        pending: (tx) => tx.cryptoAmount,
        normal: (tx) => tx.cryptoAmount,
      );

      // Outgoing transactions must have negative amounts (minus sign or parentheses)
      expect(
        cryptoAmount.startsWith('-') || cryptoAmount.startsWith('('),
        isTrue,
        reason: 'Outgoing transaction should have negative amount indicator',
      );

      result.dispose();
    });

    test('incoming transaction always shows positive amount', () async {
      final scenario = TransactionScenarioBuilder(config, setup);

      final result = await scenario
          .incoming(
            amount: 50000000,
            confirmations: 0,
          )
          .build();

      final txn = result.transactions.first;
      final cryptoAmount = txn.map(
        pending: (tx) => tx.cryptoAmount,
        normal: (tx) => tx.cryptoAmount,
      );

      // Incoming transactions must NOT have negative amounts
      expect(
        cryptoAmount.startsWith('-') || cryptoAmount.startsWith('('),
        isFalse,
        reason: 'Incoming transaction should have positive amount',
      );

      result.dispose();
    });
  });
}
