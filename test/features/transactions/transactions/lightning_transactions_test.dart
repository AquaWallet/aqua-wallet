import 'package:aqua/features/boltz/boltz.dart';
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

  group('Lightning Transactions', () {
    test('incoming lightning transaction via Boltz', () async {
      const boltzId = 'boltz_order_123';
      const claimTx = 'claim_tx_456';

      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 50000000,
            isIncoming: true,
            confirmations: 2, // Lightning uses Liquid threshold (2)
            boltzOrderId: boltzId,
            claimTxId: claimTx,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Lightning transactions appear on the L-BTC page
      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1));
      lnTxns.first.map(
        normal: (model) {
          expect(model.transaction.txhash, claimTx);
          expect(model.cryptoAmount, contains('+'));
        },
        pending: (_) => fail('Should be normal with confirmation'),
      );

      container.dispose();
    });

    test('outgoing lightning transaction via Boltz', () async {
      const boltzId = 'boltz_order_456';
      const claimTx = 'claim_tx_789';

      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: -25000000,
            isIncoming: false,
            confirmations: 2, // Lightning uses Liquid threshold (2)
            boltzOrderId: boltzId,
            claimTxId: claimTx,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Lightning transactions appear on the L-BTC page
      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1));
      lnTxns.first.map(
        normal: (model) {
          expect(model.transaction.txhash, claimTx);
          // The model's asset is L-BTC since that's the page it appears on
          expect(model.asset.isLBTC, isTrue);
        },
        pending: (_) => fail('Should be normal with confirmation'),
      );

      container.dispose();
    });

    test('findLightningTransactionWithBoltzOrder links correctly', () async {
      const boltzId = 'boltz_order_123';
      const claimTx = 'claim_tx_456';

      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 50000000,
            isIncoming: true,
            confirmations: 1,
            boltzOrderId: boltzId,
            claimTxId: claimTx,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Lightning transactions appear on the L-BTC page
      final lnTxns = await readTransactions(container, Asset.lbtc());
      expect(lnTxns, hasLength(1));

      // Ensure boltzStorageProvider is loaded before testing the lookup
      await container.read(boltzStorageProvider.future);

      // Test the lookup method - but query via L-BTC since that's where they appear
      final notifier = container.read(
        transactionsProvider(Asset.lbtc()).notifier,
      );

      final foundTxn = notifier.findLightningTransactionWithBoltzOrder(boltzId);
      expect(foundTxn, isNotNull);
      foundTxn?.map(
        normal: (model) => expect(model.transaction.txhash, claimTx),
        pending: (_) {},
      );

      container.dispose();
    });
  });
}
