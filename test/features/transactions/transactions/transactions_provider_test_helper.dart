import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
import '../strategies/transaction_details_test_helper.dart'
    show createMockNetworkTransaction, createMockDbTransaction;

/// Helper to read transactions while keeping provider alive during async operations
Future<List<TransactionUiModel>> readTransactions(
  ProviderContainer container,
  Asset asset,
) async {
  List<TransactionUiModel>? result;
  final sub = container.listen(
    transactionsProvider(asset),
    (prev, next) {
      if (next.hasValue) result = next.value;
    },
  );

  await container.read(transactionsProvider(asset).future);
  sub.close();

  return result ?? [];
}

/// Shared test setup for all transaction provider tests
class TransactionsTestSetup {
  late MockFormatService mockFormatService;
  late MockTxnFailureService mockTxnFailureService;

  void setUpMocks() {
    mockFormatService = MockFormatService();
    mockTxnFailureService = MockTxnFailureService();

    // Setup default format service behavior
    when(() => mockFormatService.signedFormatAssetAmount(
          amount: any(named: 'amount'),
          asset: any(named: 'asset'),
          decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
        )).thenAnswer((invocation) {
      final amount = invocation.namedArguments[#amount] as int;
      final asset = invocation.namedArguments[#asset] as Asset;
      final precision =
          invocation.namedArguments[#decimalPlacesOverride] as int?;

      final sign = amount >= 0 ? '+' : '';
      final decimals = precision ?? (asset.isUSDt ? 2 : 8);
      const divisor = 100000000; // All assets use 8 decimals internally
      return '$sign${(amount / divisor).toStringAsFixed(decimals)}';
    });

    when(() => mockTxnFailureService.isFailed(any())).thenReturn(false);
  }
}

/// Global setup function called once for all test files
void setUpTransactionsTestSuite() {
  // Register fallback values for mocktail
  registerFallbackValue(Asset.btc());
  registerFallbackValue(createMockNetworkTransaction());
  registerFallbackValue(createMockDbTransaction());
}
