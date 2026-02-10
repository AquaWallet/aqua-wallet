import 'package:flutter_test/flutter_test.dart';

import 'asset_transaction_test_infrastructure.dart';
import 'transactions_provider_test_helper.dart';

// Parameterized test suite for Aqua asset transactions (BTC, LBTC, and USDt)
void main() {
  final setup = TransactionsTestSetup();

  setUpAll(() {
    setUpTransactionsTestSuite();
  });

  setUp(() {
    setup.setUpMocks();
  });

  for (final config in AssetTestConfig.standardAssets()) {
    group('${config.ticker} Transactions', () {
      final runner = TransactionTestRunner(config, setup);

      runner.runLifecycleTests();
      runner.runEdgeCaseTests();
    });
  }
}
