import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:decimal/decimal.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

/// Mock notifier for boltzStorageProvider that returns empty list immediately
class MockBoltzSwapStorageNotifier extends BoltzSwapStorageNotifier {
  @override
  FutureOr<List<BoltzSwapDbModel>> build() => [];
}

/// Helper to create TransactionDetailsStrategyArgs for testing
class TransactionDetailsArgsBuilder {
  Asset asset;
  List<Asset>? availableAssets;
  TransactionDbModel? dbTransaction;
  GdkTransaction? networkTransaction;
  AppLocalizations? appLocalizations;
  ProviderContainer? container;

  TransactionDetailsArgsBuilder({
    required this.asset,
    this.availableAssets,
    this.dbTransaction,
    this.networkTransaction,
    this.appLocalizations,
    this.container,
  });

  TransactionDetailsStrategyArgs build() {
    return TransactionDetailsStrategyArgs(
      asset: asset,
      availableAssets: availableAssets ?? _defaultAssets(),
      dbTransaction: dbTransaction,
      networkTransaction: networkTransaction,
    );
  }

  static List<Asset> _defaultAssets() => [
        Asset.btc(),
        Asset.lbtc(),
        Asset.usdtLiquid(),
      ];

  static MockAppLocalizations _createMockLocalizations() {
    return MockAppLocalizations();
  }
}

/// Test setup for strategy details tests
class StrategyDetailsTestSetup {
  late MockFormatService mockFormatService;
  late MockAssetResolutionService mockAssetResolutionService;
  late MockTxnFailureService mockTxnFailureService;
  late MockConfirmationService mockConfirmationService;
  late MockRbfService mockRbfService;
  late MockAquaProvider mockAquaProvider;
  late MockBitcoinProvider mockBitcoinProvider;
  late MockLiquidProvider mockLiquidProvider;
  late MockPegStorageProvider mockPegStorageProvider;
  late MockFiatProvider mockFiatProvider;
  late MockPegSwapMatcher mockPegSwapMatcher;
  late MockFeeEstimateClient mockFeeEstimateClient;
  late AppLocalizations mockLocalizations;

  void setUp() {
    // Register fallback values for mocktail
    registerFallbackValue(MockAppLocalizations());
    registerFallbackValue(Decimal.zero);
    registerFallbackValue(createMockNetworkTransaction());
    registerFallbackValue(createMockDbTransaction());

    mockFormatService = MockFormatService();
    mockAssetResolutionService = MockAssetResolutionService();
    mockTxnFailureService = MockTxnFailureService();
    mockConfirmationService = MockConfirmationService();
    mockRbfService = MockRbfService();
    mockAquaProvider = MockAquaProvider();
    mockBitcoinProvider = MockBitcoinProvider();
    mockLiquidProvider = MockLiquidProvider();
    mockPegStorageProvider = MockPegStorageProvider();
    mockFiatProvider = MockFiatProvider();
    mockPegSwapMatcher = MockPegSwapMatcher();
    mockFeeEstimateClient = MockFeeEstimateClient();
    mockLocalizations =
        TransactionDetailsArgsBuilder._createMockLocalizations();

    _setupLocalizationMocks();
    _setupDefaultMocks();
    _setupFeeEstimateMocks();
  }

  void _setupLocalizationMocks() {
    // Mock AppLocalizations properties
    when(() => mockLocalizations.pending).thenReturn('Pending');
    when(() => mockLocalizations.oneConfirmation).thenReturn('1 Confirmation');
    when(() => mockLocalizations.nConfirmations(any())).thenAnswer((inv) {
      final count = inv.positionalArguments[0] as String;
      return '$count confirmations';
    });
  }

  void _setupDefaultMocks() {
    // Confirmation service defaults
    when(() => mockConfirmationService.getConfirmationCount(any(), any()))
        .thenAnswer((_) async => 2);
    when(() => mockConfirmationService.isTransactionPending(
          transaction: any(named: 'transaction'),
          asset: any(named: 'asset'),
          dbTransaction: any(named: 'dbTransaction'),
        )).thenAnswer((_) async => false);

    // Format service defaults

    // Mock formatFiatAmount (used by formatConfirmations internally)
    // Return the amount as a string for confirmation count formatting
    when(() => mockFormatService.formatFiatAmount(
          amount: any(named: 'amount'),
          specOverride: any(named: 'specOverride'),
          decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
          withSymbol: any(named: 'withSymbol'),
        )).thenAnswer((inv) {
      final amount = inv.namedArguments[const Symbol('amount')] as Decimal;
      return amount.toStringAsFixed(0);
    });

    when(() => mockFormatService.formatAssetAmount(
          amount: any(named: 'amount'),
          asset: any(named: 'asset'),
          removeTrailingZeros: any(named: 'removeTrailingZeros'),
          decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
          displayUnitOverride: any(named: 'displayUnitOverride'),
        )).thenAnswer((invocation) {
      final amount = invocation.namedArguments[#amount] as int;
      return '${amount / 100000000}';
    });

    when(() => mockFormatService.formatAssetAmountOrElseNull(
          amount: any(named: 'amount'),
          asset: any(named: 'asset'),
          removeTrailingZeros: any(named: 'removeTrailingZeros'),
          decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
          displayUnitOverride: any(named: 'displayUnitOverride'),
        )).thenAnswer((invocation) {
      final amount = invocation.namedArguments[#amount] as int?;
      final asset = invocation.namedArguments[#asset] as Asset?;
      if (amount == null || asset == null || amount <= 0) {
        return null;
      }
      return '${amount / 100000000}';
    });

    // Mock formatFiatAmount for use by formatConfirmations
    // Note: Don't use any() for optional params with defaults
    when(() => mockFormatService.formatFiatAmount(
          amount: any(named: 'amount'),
          specOverride: any(named: 'specOverride'),
          decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
        )).thenAnswer((invocation) {
      final amount = invocation.namedArguments[#amount] as Decimal;
      return amount.toStringAsFixed(2);
    });

    // Don't mock formatConfirmations - let it use the real implementation
    // which will call the mocked formatFiatAmount

    // Fiat provider defaults
    mockFiatProvider.mockFiatToSatoshi(
      returnValue: Decimal.fromInt(2000), // Default: 2000 sats
    );

    when(() => mockFormatService.signedFormatAssetAmount(
          amount: any(named: 'amount'),
          asset: any(named: 'asset'),
          removeTrailingZeros: any(named: 'removeTrailingZeros'),
          decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
        )).thenAnswer((invocation) {
      final amount = invocation.namedArguments[#amount] as int;
      final sign = amount >= 0 ? '+' : '';
      return '$sign${amount / 100000000}';
    });

    // Failure service defaults
    when(() => mockTxnFailureService.isFailed(any())).thenReturn(false);

    // RBF service defaults
    when(() => mockRbfService.isRbfAllowed(
          asset: any(named: 'asset'),
          txHash: any(named: 'txHash'),
        )).thenAnswer((_) async => false);

    // Aqua provider defaults - return Stream
    when(() => mockAquaProvider.getConfirmationCount(
          asset: any(named: 'asset'),
          transactionBlockHeight: any(named: 'transactionBlockHeight'),
        )).thenAnswer((_) => Stream.value(2));

    // Network providers defaults
    when(() => mockBitcoinProvider.getTransactions(
          requiresRefresh: any(named: 'requiresRefresh'),
        )).thenAnswer((_) async => []);

    when(() => mockLiquidProvider.getTransactions(
          requiresRefresh: any(named: 'requiresRefresh'),
        )).thenAnswer((_) async => []);

    // PegSwapMatcher defaults
    mockPegSwapMatcher.mockLookupPegSides();
  }

  void _setupFeeEstimateMocks() {
    when(() => mockFeeEstimateClient.getLiquidFeeRate(
          isLiquidTaxi: any(named: 'isLiquidTaxi'),
        )).thenReturn(0.1);
    when(() => mockFeeEstimateClient.fetchBitcoinFeeRates())
        .thenAnswer((_) async => {
              TransactionPriority.high: 10.0,
              TransactionPriority.medium: 5.0,
              TransactionPriority.low: 2.0,
              TransactionPriority.min: 1.0,
            });
  }

  ProviderContainer createContainer({
    List<Asset>? availableAssets,
    List<Override>? additionalOverrides,
  }) {
    final overrides = [
      formatProvider.overrideWith((_) => mockFormatService),
      assetResolutionServiceProvider
          .overrideWith((_) => mockAssetResolutionService),
      txnFailureServiceProvider.overrideWith((_) => mockTxnFailureService),
      confirmationServiceProvider.overrideWith((_) => mockConfirmationService),
      rbfServiceProvider.overrideWith((_) => mockRbfService),
      aquaProvider.overrideWith((_) => mockAquaProvider),
      bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
      liquidProvider.overrideWith((_) => mockLiquidProvider),
      pegStorageProvider.overrideWith(
          () => mockPegStorageProvider as PegOrderStorageNotifier),
      appLocalizationsProvider.overrideWith((_) => mockLocalizations),
      availableAssetsProvider.overrideWith(
          (ref) => Future.value(availableAssets ?? _defaultAssets())),
      fiatProvider.overrideWith((_) => mockFiatProvider),
      conversionProvider.overrideWith((ref, params) => null),
      boltzStorageProvider.overrideWith(MockBoltzSwapStorageNotifier.new),
      pegSwapMatcherProvider.overrideWith((_) => mockPegSwapMatcher),
      networkTransactionsProvider.overrideWith((ref, asset) async* {
        yield <GdkTransaction>[];
      }),
      feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
      sideswapStatusStreamResultStateProvider.overrideWith((_) => null),
      // Mock prefs provider (needed by exchangeRatesProvider)
      prefsProvider.overrideWith((ref) {
        return MockUserPreferencesNotifier();
      }),
      // Mock exchange rates provider for fee calculations
      exchangeRatesProvider.overrideWith((ref) {
        final mock = ReferenceExchangeRateProviderMock();
        mock.mockGetCurrentCurrency(
          value: const ExchangeRate(
            FiatCurrency.usd,
            ExchangeRateSource.coingecko,
          ),
        );
        return mock;
      }),
      ...?additionalOverrides,
    ];

    return ProviderContainer(overrides: overrides);
  }

  List<Asset> _defaultAssets() => [
        Asset.btc(),
        Asset.lbtc(),
        Asset.usdtLiquid(),
      ];
}

/// Creates a mock GdkTransaction for testing
GdkTransaction createMockNetworkTransaction({
  String? txhash,
  int? blockHeight,
  int? createdAtTs,
  Map<String, int>? satoshi,
  int? fee,
  GdkTransactionTypeEnum? type,
  List<GdkTransactionInOut>? outputs,
  List<GdkTransactionInOut>? inputs,
  String? memo,
  String? swapOutgoingAssetId,
  String? swapIncomingAssetId,
  int? swapOutgoingSatoshi,
  int? swapIncomingSatoshi,
  bool? canRbf,
}) {
  return GdkTransaction(
    txhash: txhash ?? 'mock_tx_hash',
    blockHeight: blockHeight ?? 100,
    createdAtTs: createdAtTs ?? DateTime.now().microsecondsSinceEpoch,
    satoshi: satoshi ?? {},
    fee: fee ?? 1000,
    type: type ?? GdkTransactionTypeEnum.incoming,
    outputs: outputs,
    inputs: inputs,
    memo: memo,
    swapOutgoingAssetId: swapOutgoingAssetId,
    swapIncomingAssetId: swapIncomingAssetId,
    swapOutgoingSatoshi: swapOutgoingSatoshi,
    swapIncomingSatoshi: swapIncomingSatoshi,
    canRbf: canRbf,
  );
}

/// Creates a mock TransactionDbModel for testing
///
/// Note: isPeg, isPegIn, swapServiceName, swapServiceUrl are derived from the type
/// field via extensions, so don't pass them as constructor parameters
TransactionDbModel createMockDbTransaction({
  String? txhash,
  String? assetId,
  TransactionDbModelType? type,
  String? serviceOrderId,
  SwapServiceSource? swapServiceSource,
  String? serviceAddress,
  bool? isGhost,
  DateTime? ghostTxnCreatedAt,
  int? ghostTxnAmount,
  int? ghostTxnFee,
  int? ghostTxnSideswapDeliverAmount,
  String? receiveAddress,
  String? feeAssetId,
  int? estimatedFee,
  double? exchangeRateAtExecution,
  String? currencyAtExecution,
}) {
  return TransactionDbModel(
    txhash: txhash ?? 'mock_db_tx_hash',
    assetId: assetId ?? Asset.lbtc().id,
    type: type,
    serviceOrderId: serviceOrderId,
    swapServiceSource: swapServiceSource,
    serviceAddress: serviceAddress,
    isGhost: isGhost ?? false,
    ghostTxnCreatedAt: ghostTxnCreatedAt,
    ghostTxnAmount: ghostTxnAmount,
    ghostTxnFee: ghostTxnFee,
    ghostTxnSideswapDeliverAmount: ghostTxnSideswapDeliverAmount,
    receiveAddress: receiveAddress,
    feeAssetId: feeAssetId,
    estimatedFee: estimatedFee,
    exchangeRateAtExecution: exchangeRateAtExecution,
    currencyAtExecution: currencyAtExecution,
  );
}
