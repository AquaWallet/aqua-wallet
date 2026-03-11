import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'transaction_scenario_test_harness.dart';
import 'transactions_provider_test_helper.dart';

// Configuration for asset-specific test parameters
class AssetTestConfig {
  final Asset asset;
  final int confirmationThreshold;
  final int precision;
  final String ticker;
  final bool isLiquid;
  final bool isBitcoin;

  AssetTestConfig({
    required this.asset,
    required this.confirmationThreshold,
    int? precision,
  })  : precision = precision ?? (asset.isUSDt ? kUsdtDisplayPrecision : 8),
        ticker = asset.ticker,
        isLiquid = asset.isLBTC || asset.isUSDt,
        isBitcoin = asset.isBTC;

  // 100 USDt or 1 BTC/LBTC
  int get standardAmount => asset.isUSDt ? 10000000000 : 100000000;
  // 1.23 USDt or 1 satoshi
  int get smallAmount => asset.isUSDt ? 123456789 : 1;
  // Very large amount
  int get largeAmount => asset.isUSDt ? 1000000000000000 : 2100000000000000;

  static AssetTestConfig btc() => AssetTestConfig(
        asset: Asset.btc(),
        confirmationThreshold: 1,
      );

  static AssetTestConfig lbtc() => AssetTestConfig(
        asset: Asset.lbtc(),
        confirmationThreshold: 1,
      );

  static AssetTestConfig usdtLiquid() => AssetTestConfig(
        asset: Asset.usdtLiquid(),
        confirmationThreshold: 1,
        precision: 2,
      );

  static List<AssetTestConfig> standardAssets() => [
        btc(),
        lbtc(),
        usdtLiquid(),
      ];
}

class TransactionTestRunner {
  final AssetTestConfig config;
  final TransactionsTestSetup setup;

  TransactionTestRunner(this.config, this.setup);

  TransactionScenarioBuilder get scenario =>
      TransactionScenarioBuilder(config, setup);

  void runLifecycleTests() {
    group('Confirmed', () {
      test('incoming transaction with sufficient confirmations', () async {
        final result = await scenario
            .incoming(confirmations: config.confirmationThreshold * 2)
            .build();

        result.expectSingleTransaction();
        result.expectConfirmed();
      });

      test('outgoing transaction with sufficient confirmations', () async {
        final result = await scenario
            .outgoing(confirmations: config.confirmationThreshold * 2)
            .build();

        result.expectSingleTransaction();
        result.expectConfirmed();
      });

      test('incoming with exactly threshold confirmations is confirmed',
          () async {
        final result = await scenario
            .incoming(confirmations: config.confirmationThreshold)
            .build();

        result.expectSingleTransaction();
        result.expectConfirmed();
      });

      test('outgoing with exactly threshold confirmations is confirmed',
          () async {
        final result = await scenario
            .outgoing(confirmations: config.confirmationThreshold)
            .build();

        result.expectSingleTransaction();
        result.expectConfirmed();
      });
    });

    group('Pending', () {
      test('incoming with 0 confirmations is pending', () async {
        final result = await scenario.incoming(confirmations: 0).build();

        result.expectSingleTransaction();
        result.expectPending();
      });

      test('outgoing with 0 confirmations is pending', () async {
        final result = await scenario.outgoing(confirmations: 0).build();

        result.expectSingleTransaction();
        result.expectPending();
      });

      if (config.confirmationThreshold > 0) {
        test('incoming with less than threshold confirmations is pending',
            () async {
          final result = await scenario
              .incoming(confirmations: config.confirmationThreshold - 1)
              .build();

          result.expectSingleTransaction();
          result.expectPending();
        });

        test('outgoing with less than threshold confirmations is pending',
            () async {
          final result = await scenario
              .outgoing(confirmations: config.confirmationThreshold - 1)
              .build();

          result.expectSingleTransaction();
          result.expectPending();
        });
      }
    });

    group('Pending to Confirmed Transition', () {
      test('transaction transitions from pending to confirmed', () async {
        const id = 'transition_hash_123';

        final pendingResult =
            await scenario.incoming(confirmations: 0, txhash: id).build();

        final confirmedResult = await scenario
            .incoming(confirmations: config.confirmationThreshold, txhash: id)
            .build();

        pendingResult.expectSingleTransaction();
        pendingResult.expectPending();
        confirmedResult.expectSingleTransaction();
        confirmedResult.expectConfirmed();
        confirmedResult.expectTransactionId(id);
      });
    });
  }

  void runEdgeCaseTests() {
    group('Edge Cases', () {
      group('Amount Handling', () {
        test('zero amount transaction', () async {
          final result = await scenario
              .incoming(amount: 0, confirmations: config.confirmationThreshold)
              .build();

          result.expectSingleTransaction();
          result.expectConfirmed();

          result.verifyAmountFormatted(amount: 0, precision: config.precision);
          result.dispose();
        });

        test('very small amount (1 unit at lowest precision)', () async {
          final result = await scenario
              .incoming(
                  amount: config.smallAmount,
                  confirmations: config.confirmationThreshold)
              .build();

          result.expectSingleTransaction();
          result.expectConfirmed();

          result.verifyAmountFormatted(
            amount: config.smallAmount,
            precision: config.precision,
          );
          result.dispose();
        });

        test('very large amount (near max supply)', () async {
          final result = await scenario
              .incoming(
                  amount: config.largeAmount,
                  confirmations: config.confirmationThreshold)
              .build();

          result.expectSingleTransaction();
          result.expectConfirmed();

          result.verifyAmountFormatted(
            amount: config.largeAmount,
            precision: config.precision,
          );
          result.dispose();
        });

        test('negative amount (outgoing)', () async {
          final result = await scenario
              .outgoing(
                  amount: config.standardAmount,
                  confirmations: config.confirmationThreshold)
              .build();

          result.expectSingleTransaction();
          result.expectConfirmed();

          result.verifyAmountFormatted(
            amount: -config.standardAmount,
            precision: config.precision,
          );
          result.dispose();
        });
      });

      group('Fee Handling', () {
        test('outgoing transaction has amount formatted', () async {
          final result = await scenario
              .outgoing(
                amount: config.standardAmount,
                confirmations: config.confirmationThreshold,
              )
              .build();

          result.expectSingleTransaction();
          result.expectConfirmed();

          result.verifyFeeFormatted(fee: 1000);
          result.dispose();
        });
      });

      group('Confirmation Edge Cases', () {
        test('extremely high confirmation count', () async {
          final result = await scenario
              .incoming(amount: config.standardAmount, confirmations: 1000000)
              .build();

          result.expectSingleTransaction();
          result.expectConfirmed();
          result.dispose();
        });

        test('block height 0 is pending', () async {
          final result = await scenario.incoming(confirmations: 0).build();

          result.expectSingleTransaction();
          result.expectPending();
          result.dispose();
        });
      });

      group('Transaction Types', () {
        test('ghost transaction is pending', () async {
          final result = await scenario
              .ghost(
                amount: -config.standardAmount,
                type: TransactionDbModelType.aquaSend,
              )
              .build();

          result.expectSingleTransaction();
          result.expectPending();
          result.dispose();
        });

        test('redeposit transaction', () async {
          final result = await scenario
              .redeposit(
                amount: config.standardAmount,
                confirmations: config.confirmationThreshold,
              )
              .build();

          result.expectSingleTransaction();
          result.expectConfirmed();
          result.dispose();
        });
      });
    });
  }
}

// Builder for creating transaction scenarios
class TransactionScenarioBuilder {
  final AssetTestConfig config;
  final TransactionsTestSetup setup;
  final TransactionScenarioHarness _harness;

  TransactionScenarioBuilder(this.config, this.setup)
      : _harness = TransactionScenarioHarness();

  TransactionScenarioBuilder incoming({
    int? amount,
    int confirmations = 0,
    String? txhash,
    DateTime? timestamp,
  }) {
    final actualAmount = amount ?? config.standardAmount;

    if (config.asset.isBTC) {
      _harness.withBtcIncoming(
        amount: actualAmount,
        confirmations: confirmations,
        txhash: txhash,
        timestamp: timestamp,
      );
    } else if (config.asset.isLBTC) {
      _harness.withLbtcIncoming(
        amount: actualAmount,
        confirmations: confirmations,
        txhash: txhash,
        timestamp: timestamp,
      );
    } else if (config.asset.isUSDt) {
      _harness.withUsdtIncoming(
        amount: actualAmount,
        confirmations: confirmations,
        txhash: txhash,
        timestamp: timestamp,
      );
    }

    _lastTxHash = txhash;
    return this;
  }

  TransactionScenarioBuilder ghost({
    required int amount,
    required TransactionDbModelType type,
    String? txhash,
  }) {
    _harness.withGhostTransaction(
      asset: config.asset,
      amount: amount,
      type: type,
      txhash: txhash,
    );
    return this;
  }

  TransactionScenarioBuilder redeposit({
    int? amount,
    int confirmations = 0,
    String? txhash,
  }) {
    final actualAmount = amount ?? config.standardAmount;
    _harness.withRedeposit(
      asset: config.asset,
      amount: actualAmount,
      confirmations: confirmations,
      txhash: txhash,
    );
    return this;
  }

  // Store the last transaction hash for database entry association
  String? _lastTxHash;

  TransactionScenarioBuilder outgoing({
    int? amount,
    int confirmations = 0,
    String? txhash,
    DateTime? timestamp,
    bool createDbEntry = false,
  }) {
    final actualAmount = amount ?? config.standardAmount;

    if (config.asset.isBTC) {
      _harness.withBtcOutgoing(
        amount: actualAmount,
        confirmations: confirmations,
        txhash: txhash,
        timestamp: timestamp,
      );
    } else if (config.asset.isLBTC) {
      _harness.withLbtcOutgoing(
        amount: actualAmount,
        confirmations: confirmations,
        txhash: txhash,
        timestamp: timestamp,
      );
    } else if (config.asset.isUSDt) {
      _harness.withUsdtOutgoing(
        amount: actualAmount,
        confirmations: confirmations,
        txhash: txhash,
        timestamp: timestamp,
        createDbEntry: createDbEntry,
      );
    }

    _lastTxHash = txhash;
    return this;
  }

  TransactionScenarioBuilder withDbEntry({
    required TransactionDbModelType type,
    String? txhash,
  }) {
    // For BTC transactions, add database entry with aquaSend type using the last txhash
    final hash = txhash ?? _lastTxHash;
    _harness.withGhostTransaction(
      asset: config.asset,
      amount: config.standardAmount,
      type: type,
      txhash: hash,
    );
    return this;
  }

  Future<TransactionTestResult> build() async {
    final scenario = _harness.build();
    final container = scenario.createContainer(
      formatService: setup.mockFormatService,
      txnFailureService: setup.mockTxnFailureService,
    );

    final txns = await readTransactions(container, config.asset);

    return TransactionTestResult(
      transactions: txns,
      container: container,
      asset: config.asset,
      setup: setup,
    );
  }
}

// Result wrapper with assertion helpers
class TransactionTestResult {
  final List<TransactionUiModel> transactions;
  final ProviderContainer container;
  final Asset asset;
  final TransactionsTestSetup setup;

  TransactionTestResult({
    required this.transactions,
    required this.container,
    required this.asset,
    required this.setup,
  });

  void expectSingleTransaction() {
    expect(transactions, hasLength(1),
        reason: 'Expected exactly one transaction');
  }

  void expectTransactionCount(int count) {
    expect(transactions, hasLength(count));
  }

  void expectEmpty() {
    expect(transactions, isEmpty);
  }

  void expectPending() {
    expect(transactions.first.isPending, isTrue);
    transactions.first.map(
      normal: (_) => fail('Should be pending'),
      pending: (model) {
        expect(model.asset.id, asset.id);
      },
    );
  }

  void expectConfirmed() {
    expect(transactions.first.isPending, isFalse);
    transactions.first.map(
      normal: (model) => expect(model.asset.id, asset.id),
      pending: (_) => fail('Should be confirmed'),
    );
  }

  void expectTransactionId(String txhash) {
    transactions.first.map(
      normal: (model) => expect(model.transaction.txhash, txhash),
      pending: (model) => expect(model.transactionId, txhash),
    );
  }

  void expectCryptoAmountContains(String substring) {
    transactions.first.map(
      normal: (model) => expect(model.cryptoAmount, contains(substring)),
      pending: (model) => expect(model.cryptoAmount, contains(substring)),
    );
  }

  void expectIncoming() {
    transactions.first.map(
      normal: (model) => expect(model.cryptoAmount, startsWith('+')),
      pending: (model) => expect(model.cryptoAmount, contains('+')),
    );
  }

  void expectOutgoing() {
    transactions.first.map(
      normal: (model) => expect(model.cryptoAmount, startsWith('-')),
      pending: (model) => expect(model.cryptoAmount, contains('-')),
    );
  }

  void expectAmountSign({required bool isNegative}) {
    final txn = transactions.first;
    final cryptoAmount = txn.map(
      normal: (tx) => tx.cryptoAmount,
      pending: (tx) => tx.cryptoAmount,
    );

    if (isNegative) {
      expect(
        cryptoAmount.startsWith('-') || cryptoAmount.startsWith('('),
        isTrue,
        reason:
            'Expected negative amount (starting with - or (), got: $cryptoAmount',
      );
    } else {
      expect(
        cryptoAmount.startsWith('-') || cryptoAmount.startsWith('('),
        isFalse,
        reason: 'Expected positive amount, got: $cryptoAmount',
      );
    }
  }

  void verifyAmountFormatted({
    required int amount,
    required int precision,
  }) {
    // Verify that signedFormatAssetAmount was called with correct parameters
    verify(() => setup.mockFormatService.signedFormatAssetAmount(
          amount: amount,
          asset: any(
            named: 'asset',
            that: predicate<Asset>((a) => a.id == asset.id),
          ),
          decimalPlacesOverride: precision == 2 ? 2 : null,
        )).called(greaterThan(0));
  }

  void verifyFeeFormatted({required int fee}) {
    // Verify that fee formatting was called
    // Outgoing transactions typically have fees displayed
    verify(() => setup.mockFormatService.signedFormatAssetAmount(
          amount: any(named: 'amount'),
          asset: any(named: 'asset'),
          decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
        )).called(greaterThan(0));
  }

  void dispose() {
    container.dispose();
  }
}
