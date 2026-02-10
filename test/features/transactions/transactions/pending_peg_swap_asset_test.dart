import 'package:aqua/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transaction_scenario_test_harness.dart';
import 'transactions_provider_test_helper.dart';

/// This test verifies the fix for a bug where pending swap/peg transactions
/// showed incorrect asset pairs in their titles.
///
/// Bug: BTC->L-BTC showed as "BTC->BTC", L-BTC->BTC showed as "L-BTC->L-BTC"
/// Fix: Corrected swapOutgoingAsset and swapIncomingAsset assignment in transactions_provider.dart
void main() {
  final setup = TransactionsTestSetup();

  setUpAll(() {
    setUpTransactionsTestSuite();
  });

  setUp(() {
    setup.setUpMocks();
  });

  group('Pending Peg Transaction Asset Assignment', () {
    test(
        'BTC->L-BTC pending peg-in shows correct fromAsset and toAsset on BTC page',
        () async {
      // SCENARIO: Peg-in from BTC to L-BTC, viewed from BTC page (sending side)
      // The transaction should show asset=BTC (outgoing) and otherAsset=L-BTC (incoming)
      final scenario = TransactionScenarioHarness()
          .withPegTransaction(
            isPegIn: true,
            amount: 100000000, // 1 BTC
            confirmations: 0, // Pending
          )
          .build();

      final container = scenario.createContainer(
        formatService: setup.mockFormatService,
        txnFailureService: setup.mockTxnFailureService,
      );

      // Check on BTC page (sending side)
      final btcTxns = await readTransactions(container, Asset.btc());

      // Should have 1 pending transaction
      expect(btcTxns, hasLength(1),
          reason: 'BTC page should show the pending peg-in transaction');

      btcTxns.first.map(
        normal: (_) => fail('Should be pending with 0 confirmations'),
        pending: (model) {
          // CRITICAL: Before fix, both asset and otherAsset were BTC
          // After fix, asset=BTC and otherAsset=L-BTC
          expect(model.asset.id, Asset.btc().id,
              reason: 'asset should be BTC (the outgoing asset)');
          expect(model.otherAsset?.id, Asset.lbtc().id,
              reason: 'otherAsset should be L-BTC (the incoming asset)');
        },
      );

      container.dispose();
    });
  });
}
