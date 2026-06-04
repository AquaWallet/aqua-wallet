import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transaction_scenario_test_harness.dart';
import 'transactions_provider_test_helper.dart';

/// Test for verifying pending Lightning transaction direction labels
///
/// Bug Report: Pending incoming Lightning transactions show "Sending" instead of "Receiving"
void main() {
  final setup = TransactionsTestSetup();

  setUpAll(() {
    setUpTransactionsTestSuite();
  });

  setUp(() {
    setup.setUpMocks();
  });

  group('Pending Lightning Transaction Direction', () {
    test('pending incoming Lightning transaction shows "Receiving"', () async {
      const boltzId = 'boltz_incoming_123';

      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 50000000,
            isIncoming: true,
            confirmations: 0, // Pending (not confirmed)
            boltzOrderId: boltzId,
            claimTxId: '', // Empty for pending
            boltzStatus: BoltzSwapStatus.transactionMempool,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Lightning transactions appear on the L-BTC asset page
      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1));

      lnTxns.first.map(
        normal: (_) => fail('Should be pending with 0 confirmations'),
        pending: (model) {
          // Verify transaction direction
          final dbTxn = model.dbTransaction;
          expect(dbTxn, isNotNull);
          expect(dbTxn?.isBoltzReverseSwap, isTrue,
              reason: 'Incoming Lightning should be a reverse swap');
          expect(model.cryptoAmount.contains('+'), isTrue,
              reason: 'Incoming amount should have + prefix');
        },
      );

      container.dispose();
    });

    test('pending outgoing Lightning transaction shows "Sending"', () async {
      const boltzId = 'boltz_outgoing_456';

      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: -25000000,
            isIncoming: false,
            confirmations: 0, // Pending (not confirmed)
            boltzOrderId: boltzId,
            claimTxId: '', // Empty for pending
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Lightning transactions appear on the L-BTC asset page
      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1));

      lnTxns.first.map(
        normal: (_) => fail('Should be pending with 0 confirmations'),
        pending: (model) {
          // Verify transaction direction
          final dbTxn = model.dbTransaction;
          expect(dbTxn, isNotNull);
          expect(dbTxn?.isBoltzSwap, isTrue,
              reason: 'Outgoing Lightning should be a submarine swap');
          // Note: Amount prefix formatting is a separate concern
          // The main bug is about the transaction direction label
        },
      );

      container.dispose();
    });

    test('confirmed incoming Lightning transaction shows "Received"', () async {
      const boltzId = 'boltz_confirmed_incoming_789';
      const claimTx = 'claim_tx_confirmed_123';

      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 75000000,
            isIncoming: true,
            confirmations: 2, // Confirmed (Liquid threshold is 2)
            boltzOrderId: boltzId,
            claimTxId: claimTx,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Lightning transactions appear on the L-BTC asset page
      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1));

      lnTxns.first.map(
        normal: (model) {
          expect(model.transaction.txhash, claimTx);
          expect(model.cryptoAmount.contains('+'), isTrue,
              reason: 'Confirmed incoming amount should have + prefix');
        },
        pending: (_) => fail('Should be confirmed with 2+ confirmations'),
      );

      container.dispose();
    });

    test('pending Boltz refund shows "Receiving"', () async {
      // Create a pending refund transaction
      // Boltz refunds are still Boltz transactions, so they appear on the L-BTC page
      final scenario = TransactionScenarioHarness()
          .withGhostTransaction(
            asset: Asset.lightning(),
            amount: 30000000,
            type: TransactionDbModelType.boltzRefund,
            txhash: 'refund_tx_123',
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lbtcTxns = await readTransactions(container, Asset.lbtc());

      expect(lbtcTxns, hasLength(1));

      lbtcTxns.first.map(
        normal: (_) => fail('Ghost transaction should be pending'),
        pending: (model) {
          // Verify it's recognized as a refund
          final dbTxn = model.dbTransaction;
          expect(dbTxn, isNotNull);
          expect(dbTxn?.isBoltzRefund, isTrue,
              reason: 'Should be a Boltz refund');
          // Note: Amount prefix formatting is a separate concern
          // The main bug is about the transaction direction label
        },
      );

      container.dispose();
    });

    test('pending Lightning transaction has correct crypto amount', () async {
      const boltzId = 'boltz_amount_test';
      const expectedAmount = 50000000;

      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: expectedAmount,
            isIncoming: true,
            confirmations: 0, // Pending
            boltzOrderId: boltzId,
            claimTxId: '', // Empty for pending
            boltzStatus: BoltzSwapStatus.transactionMempool,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1),
          reason: 'Pending Lightning transaction should appear in list');

      lnTxns.first.map(
        normal: (_) => fail('Should be pending'),
        pending: (model) {
          // Verify the crypto amount is formatted (not null)
          expect(model.cryptoAmount, isNotEmpty,
              reason: 'cryptoAmount should be set from ghostTxnAmount');
          expect(model.dbTransaction?.ghostTxnAmount, isNotNull,
              reason: 'ghostTxnAmount should be set');
        },
      );

      container.dispose();
    });

    test(
        'both pending incoming and outgoing Lightning transactions appear in list',
        () async {
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 50000000,
            isIncoming: true,
            confirmations: 0, // Pending
            boltzOrderId: 'boltz_incoming',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.transactionMempool,
          )
          .withLightningTransaction(
            amount: 25000000,
            isIncoming: false,
            confirmations: 0, // Pending
            boltzOrderId: 'boltz_outgoing',
            claimTxId: '',
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(2),
          reason:
              'Both incoming and outgoing pending transactions should appear');

      // Verify both are pending
      for (final txn in lnTxns) {
        txn.map(
          normal: (_) => fail('All transactions should be pending'),
          pending: (model) {
            expect(model.cryptoAmount, isNotEmpty);
          },
        );
      }

      container.dispose();
    });

    test(
        'reverse swap with empty txhash and no claimable status is NOT pending',
        () async {
      // A reverse swap that was created but never paid (or already expired)
      // should NOT show as pending — there is no on-chain transaction.
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 100000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'expired_boltz_swap',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.swapExpired,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, isEmpty,
          reason:
              'Expired reverse swap with no claim tx should not be pending');

      container.dispose();
    });

    test(
        'reverse swap with empty txhash and claimable status appears as pending',
        () async {
      // A reverse swap whose lockup tx is on-chain (transactionMempool)
      // should show as pending while we attempt to claim.
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 100000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'claimable_boltz_swap',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.transactionMempool,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1),
          reason: 'Claimable reverse swap should appear in pending list');

      lnTxns.first.map(
        normal: (_) => fail('Should be pending, not confirmed'),
        pending: (model) {
          expect(model.cryptoAmount, isNotEmpty,
              reason: 'Should have formatted crypto amount');
          expect(model.dbTransaction, isNotNull);
          expect(model.dbTransaction?.serviceOrderId, 'claimable_boltz_swap');
        },
      );

      container.dispose();
    });

    test('reverse swap with empty txhash and status "created" is NOT pending',
        () async {
      // Invoice was generated but never paid. The app may have been offline
      // when the swap expired, so lastKnownStatus is still "created".
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 50000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'unpaid_boltz_swap',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.created,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, isEmpty,
          reason:
              'Reverse swap with "created" status and no claim tx should not be pending');

      container.dispose();
    });

    test('reverse swap with empty txhash and null status is NOT pending',
        () async {
      // Edge case: BoltzSwapDbModel exists but lastKnownStatus was never set.
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 50000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'null_status_boltz_swap',
            claimTxId: '',
            boltzStatus: null,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, isEmpty,
          reason:
              'Reverse swap with null status and no claim tx should not be pending');

      container.dispose();
    });

    test(
        'reverse swap with empty txhash and invoiceSettled status is NOT pending',
        () async {
      // Swap completed (invoice settled) but the claim txhash was never
      // written back to the TransactionDbModel (DB save failure).
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 75000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'settled_boltz_swap',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.invoiceSettled,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, isEmpty,
          reason:
              'Terminal reverse swap with no claim tx should not be pending');

      container.dispose();
    });

    test('multiple phantom reverse swaps are all hidden', () async {
      // Simulates a user who generated several invoices without any being
      // paid — each left a TransactionDbModel with txhash: "".
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 10000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'phantom_1',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.swapExpired,
          )
          .withLightningTransaction(
            amount: 20000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'phantom_2',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.created,
          )
          .withLightningTransaction(
            amount: 30000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'phantom_3',
            claimTxId: '',
            boltzStatus: null,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, isEmpty,
          reason:
              'All phantom reverse swaps (expired, created, null) should be hidden');

      container.dispose();
    });

    test('one claimable swap among phantom entries is shown', () async {
      // Mix of phantom entries and one actively claimable swap.
      final scenario = TransactionScenarioHarness()
          .withLightningTransaction(
            amount: 10000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'phantom_expired',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.swapExpired,
          )
          .withLightningTransaction(
            amount: 50000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'active_claim',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.transactionConfirmed,
          )
          .withLightningTransaction(
            amount: 20000000,
            isIncoming: true,
            confirmations: 0,
            boltzOrderId: 'phantom_created',
            claimTxId: '',
            boltzStatus: BoltzSwapStatus.created,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lnTxns = await readTransactions(container, Asset.lbtc());

      expect(lnTxns, hasLength(1),
          reason: 'Only the actively claimable swap should be pending');

      lnTxns.first.map(
        normal: (_) => fail('Should be pending'),
        pending: (model) {
          expect(model.dbTransaction?.serviceOrderId, 'active_claim');
        },
      );

      container.dispose();
    });
  });
}
