import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
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

  group('Peg Transactions', () {
    test('peg-in shows as pending until peg completes', () async {
      final scenario = TransactionScenarioHarness()
          .withPegTransaction(
            isPegIn: true,
            amount: 100000000,
            confirmations: 1,
            detectedConfs: 1,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lbtcTxns = await readTransactions(container, Asset.lbtc());

      // Peg-in transactions should appear as pending on L-BTC page
      expect(lbtcTxns, hasLength(1));
      lbtcTxns.first.map(
        normal: (_) => fail('Should be pending until peg completes'),
        pending: (model) {
          expect(model.asset.id, Asset.btc().id); // from asset for peg-in
          expect(model.cryptoAmount, contains('+')); // Incoming
        },
      );

      container.dispose();
    });

    test('peg-out shows as pending until peg completes', () async {
      final scenario = TransactionScenarioHarness()
          .withPegTransaction(
            isPegIn: false,
            amount: 100000000,
            confirmations: 1,
            detectedConfs: 1,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final btcTxns = await readTransactions(container, Asset.btc());

      // Peg-out transactions should appear as pending on BTC page
      expect(btcTxns, hasLength(1));
      btcTxns.first.map(
        normal: (_) => fail('Should be pending until peg completes'),
        pending: (model) {
          expect(model.asset.id, Asset.btc().id);
          expect(model.cryptoAmount,
              contains('+')); // Incoming (receiving BTC from LBTC)
        },
      );

      container.dispose();
    });

    test('peg-in does not show on non-BTC/LBTC asset pages', () async {
      final scenario = TransactionScenarioHarness()
          .withPegTransaction(
            isPegIn: true,
            amount: 100000000,
            confirmations: 1,
            detectedConfs: 1,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Peg transactions should NOT appear on USDt page
      final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
      expect(usdtTxns, isEmpty);

      container.dispose();
    });

    test('peg-out does not show on non-BTC/LBTC asset pages', () async {
      final scenario = TransactionScenarioHarness()
          .withPegTransaction(
            isPegIn: false,
            amount: 100000000,
            confirmations: 1,
            detectedConfs: 1,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Peg transactions should NOT appear on USDt page
      final usdtTxns = await readTransactions(container, Asset.usdtLiquid());
      expect(usdtTxns, isEmpty);

      container.dispose();
    });
  });

  group('Direct Peg-In Transactions', () {
    test('pending direct peg-in shows on L-BTC page with correct assets',
        () async {
      // Direct peg-ins remain pending until the peg status indicates completion
      final scenario = TransactionScenarioHarness()
          .withDirectPegInTransaction(
            amount: 100000000,
            confirmations: 2,
            receiveAddress: 'lq1test_receive_address',
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lbtcTxns = await readTransactions(container, Asset.lbtc());

      expect(lbtcTxns, hasLength(1));
      lbtcTxns.first.map(
        normal: (_) => fail('Peg should be pending until peg status completes'),
        pending: (model) {
          // Direct peg-in should show BTC as the from asset
          expect(model.asset.id, Asset.btc().id);
          // Should have L-BTC as the other asset (destination)
          expect(model.otherAsset?.id, Asset.lbtc().id);
          expect(model.cryptoAmount, contains('+')); // Incoming
        },
      );

      container.dispose();
    });

    test('direct peg-in is matched by receiveAddress', () async {
      // The L-BTC transaction has a different txhash than what's stored
      // in the peg order. They should still be matched by receiveAddress.
      const receiveAddr = 'lq1unique_receive_address';

      final scenario = TransactionScenarioHarness()
          .withDirectPegInTransaction(
            amount: 50000000,
            confirmations: 2,
            lbtcTxhash: 'lbtc_different_hash_123',
            orderId: 'peg_order_456',
            receiveAddress: receiveAddr,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lbtcTxns = await readTransactions(container, Asset.lbtc());

      expect(lbtcTxns, hasLength(1));
      lbtcTxns.first.map(
        normal: (_) => fail('Peg should be pending until peg status completes'),
        pending: (model) {
          // Should be identified as a peg transaction (matched by receiveAddress)
          expect(model.dbTransaction?.isPeg, isTrue);
          expect(model.asset.id, Asset.btc().id);
          expect(model.otherAsset?.id, Asset.lbtc().id);
        },
      );

      container.dispose();
    });

    test('direct peg-in transaction has correct dbTransaction metadata',
        () async {
      const receiveAddr = 'lq1metadata_test';

      final scenario = TransactionScenarioHarness()
          .withDirectPegInTransaction(
            amount: 75000000,
            confirmations: 2,
            orderId: 'peg_order_meta_123',
            receiveAddress: receiveAddr,
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      final lbtcTxns = await readTransactions(container, Asset.lbtc());

      expect(lbtcTxns, hasLength(1));
      lbtcTxns.first.map(
        normal: (_) => fail('Peg should be pending'),
        pending: (model) {
          // Verify the dbTransaction was properly created from peg order
          expect(model.dbTransaction, isNotNull);
          expect(model.dbTransaction?.serviceOrderId, 'peg_order_meta_123');
          expect(model.dbTransaction?.isPegIn, isTrue);
          expect(
              model.dbTransaction?.type, TransactionDbModelType.sideswapPegIn);
        },
      );

      container.dispose();
    });
  });
}
