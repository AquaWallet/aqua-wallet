import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_components/ui_components.dart';

import '../mocks/mocks.dart';
import '../test_data/asset_transaction_test_data.dart';

// Provider overrides helper
class AssetTransactionTestProviders {
  static List<Override> createOverrides({
    List<TransactionUiModel>? transactions,
    List<Asset>? assets,
    String? displayUnit,
    SatoshiToFiatConversionModel? conversion,
    String? fiatAmount,
    List<GdkTransaction>? networkTransactions,
  }) {
    final mockTransactionsNotifier = MockTransactionsNotifier(
      transactions: transactions ?? [],
    );
    final mockAssetsNotifier = MockAssetsNotifier(
      assets: assets ?? TestTransactionFactory.mockAssets,
    );
    final mockDisplayUnitsProvider = MockDisplayUnitsProvider();
    final mockPegStatusNotifier = MockPegStatusNotifier();
    // Setup mock behaviors
    mockDisplayUnitsProvider.mockGetAssetDisplayUnit(
      value: displayUnit ?? 'BTC',
    );
    mockDisplayUnitsProvider.mockCurrentDisplayUnit(
      value: SupportedDisplayUnits.btc,
    );
    mockDisplayUnitsProvider.mockGetForcedDisplayUnit(
      value: SupportedDisplayUnits.btc,
    );
    mockDisplayUnitsProvider.mockConvertSatsToUnit(
      value: Decimal.fromInt(1), // Default conversion value
    );

    final mockPrefsProvider = MockUserPreferencesNotifier();

    // Setup mock preferences
    when(() => mockPrefsProvider.isBalanceHidden).thenReturn(false);
    when(() => mockPrefsProvider.displayUnits).thenReturn('BTC');

    return [
      transactionsProvider.overrideWith(() => mockTransactionsNotifier),
      assetsProvider.overrideWith(() => mockAssetsNotifier),
      displayUnitsProvider.overrideWith((ref) => mockDisplayUnitsProvider),
      pegStatusProvider.overrideWith(() => mockPegStatusNotifier as dynamic),
      prefsProvider.overrideWith((_) => mockPrefsProvider),
      // Mock conversion provider to avoid timer issues
      conversionProvider.overrideWith((ref, params) => null),
      // Mock fiat amount provider
      fiatAmountProvider.overrideWith((ref, model) =>
          MockFiatAmountProviderX.mockFiatAmount(fiatAmount ?? '')),
    ];
  }
}

// Test widget wrapper
class AssetTransactionTestWrapper extends ConsumerWidget {
  const AssetTransactionTestWrapper({
    super.key,
    required this.asset,
    required this.overrides,
  });

  final Asset asset;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AssetTransactions(asset: asset),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Asset.btc());
  });

  group('AssetTransactions', () {
    test('should create AssetTransactions widget instance', () {
      // Simple test to verify the widget can be instantiated
      final widget = AssetTransactions(asset: Asset.btc());
      expect(widget, isA<AssetTransactions>());
      expect(widget.asset, equals(Asset.btc()));
    });

    testWidgets('should display empty state message for BTC', (tester) async {
      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [], // Empty list to trigger empty state
        assets: [TestTransactionFactory.btcAsset],
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.btcAsset,
          overrides: overrides,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // The empty state should be visible when there are no transactions
      // We can verify this by checking that the transactions list is not present
      expect(find.byType(ListView), findsNothing);

      // Check that the empty state text is displayed
      // For BTC, it should show the Bitcoin empty message using the liquid format
      expect(find.textContaining('Bitcoin'), findsOneWidget);
      expect(find.textContaining('will show up here'), findsOneWidget);
    });

    testWidgets('should display empty state message for Liquid assets',
        (tester) async {
      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [], // Empty list to trigger empty state
        assets: [TestTransactionFactory.usdtAsset],
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.usdtAsset,
          overrides: overrides,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // The empty state should be visible when there are no transactions
      expect(find.byType(ListView), findsNothing);

      // Check that the empty state text is displayed
      // For Liquid assets, it should show the liquid empty message with asset name
      expect(find.textContaining('Liquid USDt'), findsOneWidget);
      expect(find.textContaining('will show up here'), findsOneWidget);
    });

    testWidgets('should display swap transaction with BTC → USDt',
        (tester) async {
      // Create a swap transaction from BTC to USDt using the factory
      final swapTransaction = TestTransactionFactory.swap(
        id: 'swap_txn_123',
        fromAsset: TestTransactionFactory.btcAsset,
        toAsset: TestTransactionFactory.usdtAsset,
        cryptoAmount: '-0.001',
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: TestTransactionFactory.mockAssets,
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.btcAsset,
          overrides: overrides,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions list is present
      expect(find.byType(ListView), findsOneWidget);

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "BTC → USDt"
      // The arrow is rendered as a separate AquaIcon, so we check for individual parts
      expect(find.text('BTC'), findsWidgets);
      expect(find.text('USDt'), findsWidgets);

      // Verify the arrow icon is present (part of swap display)
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify the crypto amount is displayed
      expect(find.text('-0.001'), findsOneWidget);

      // Verify the fiat amount is displayed
      expect(find.text('\$50.00'), findsNothing);

      // Verify the transaction icon is present (swap icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets('should display swap pending transaction with BTC → USDt',
        (tester) async {
      // Create a swap transaction from BTC to USDt using the factory
      final swapTransaction = TestTransactionFactory.swap(
        id: 'swap_txn_123',
        isPending: true,
        fromAsset: TestTransactionFactory.btcAsset,
        toAsset: TestTransactionFactory.usdtAsset,
        cryptoAmount: '-0.001',
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: TestTransactionFactory.mockAssets,
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: AssetTransactionTestWrapper(
            asset: TestTransactionFactory.btcAsset,
            overrides: overrides,
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions lists are present (pending and confirmed)
      expect(find.byType(ListView), findsNWidgets(2));

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "BTC → USDt"
      // The arrow is rendered as a separate AquaIcon, so we check for individual parts
      expect(find.text('BTC'), findsWidgets);
      expect(find.text('USDt'), findsWidgets);
      expect(find.byType(AquaLinearProgressIndicator), findsOneWidget);

      // Verify the arrow icon is present (part of swap display)
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify the crypto amount is displayed
      expect(find.text('-0.001'), findsOneWidget);

      // Note: Swap transactions don't display fiat amounts

      // Verify the transaction icon is present (swap icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets('should display swap transaction with L-BTC → EURx',
        (tester) async {
      // Create a swap transaction from L-BTC to EURx using the factory
      final swapTransaction = TestTransactionFactory.swap(
        id: 'swap_lbtc_eurx_123',
        fromAsset: TestTransactionFactory.lbtcAsset,
        toAsset: TestTransactionFactory.eurxAsset,
        cryptoAmount: '-0.001',
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: [
          TestTransactionFactory.lbtcAsset,
          TestTransactionFactory.eurxAsset
        ],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.lbtcAsset,
          overrides: overrides,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions list is present
      expect(find.byType(ListView), findsOneWidget);

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "L-BTC → EURx"
      // The arrow is rendered as a separate AquaIcon, so we check for individual parts
      expect(find.text('L-BTC'), findsWidgets);
      expect(find.text('EURx'), findsWidgets);

      // Verify the arrow icon is present (part of swap display)
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify the crypto amount is displayed
      expect(find.text('-0.001'), findsOneWidget);

      // Verify the fiat amount is displayed
      expect(find.text('\$50.00'), findsOneWidget);

      // Verify the transaction icon is present (swap icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets('should display pending swap transaction with L-BTC → EURx',
        (tester) async {
      // Create a pending swap transaction from L-BTC to EURx using the factory
      final swapTransaction = TestTransactionFactory.swap(
        id: 'pending_swap_lbtc_eurx_123',
        isPending: true,
        fromAsset: TestTransactionFactory.lbtcAsset,
        toAsset: TestTransactionFactory.eurxAsset,
        cryptoAmount: '-0.001',
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: [
          TestTransactionFactory.lbtcAsset,
          TestTransactionFactory.eurxAsset
        ],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: AssetTransactionTestWrapper(
            asset: TestTransactionFactory.lbtcAsset,
            overrides: overrides,
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions lists are present (pending and confirmed)
      expect(find.byType(ListView), findsNWidgets(2));

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "L-BTC → EURx"
      // The arrow is rendered as a separate AquaIcon, so we check for individual parts
      expect(find.text('L-BTC'), findsWidgets);
      expect(find.text('EURx'), findsWidgets);
      expect(find.byType(AquaLinearProgressIndicator), findsOneWidget);

      // Verify the arrow icon is present (part of swap display)
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify the crypto amount is displayed
      expect(find.text('-0.001'), findsOneWidget);

      // Note: Swap transactions don't display fiat amounts

      // Verify the transaction icon is present (swap icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets('should display swap transaction with EURx → L-BTC',
        (tester) async {
      // Create a swap transaction from EURx to L-BTC using the factory
      final swapTransaction = TestTransactionFactory.swap(
        id: 'swap_eurx_lbtc_123',
        fromAsset: TestTransactionFactory.eurxAsset,
        toAsset: TestTransactionFactory.lbtcAsset,
        cryptoAmount: '-0.001',
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: [
          TestTransactionFactory.eurxAsset,
          TestTransactionFactory.lbtcAsset
        ],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.eurxAsset,
          overrides: overrides,
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions list is present
      expect(find.byType(ListView), findsOneWidget);

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "EURx → L-BTC"
      // The arrow is rendered as a separate AquaIcon, so we check for individual parts
      expect(find.text('EURx'), findsWidgets);
      expect(find.text('L-BTC'), findsWidgets);

      // Verify the arrow icon is present (part of swap display)
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify the crypto amount is displayed
      expect(find.text('-0.001'), findsOneWidget);

      // Verify the fiat amount is displayed
      expect(find.text('\$50.00'), findsOneWidget);

      // Verify the transaction icon is present (swap icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets('should display pending swap transaction with EURx → L-BTC',
        (tester) async {
      // Create a pending swap transaction from EURx to L-BTC using the factory
      final swapTransaction = TestTransactionFactory.swap(
        id: 'pending_swap_eurx_lbtc_123',
        isPending: true,
        fromAsset: TestTransactionFactory.eurxAsset,
        toAsset: TestTransactionFactory.lbtcAsset,
        cryptoAmount: '-0.001',
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: [
          TestTransactionFactory.eurxAsset,
          TestTransactionFactory.lbtcAsset
        ],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: AssetTransactionTestWrapper(
            asset: TestTransactionFactory.eurxAsset,
            overrides: overrides,
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions lists are present (pending and confirmed)
      expect(find.byType(ListView), findsNWidgets(2));

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "EURx → L-BTC"
      // The arrow is rendered as a separate AquaIcon, so we check for individual parts
      expect(find.text('EURx'), findsWidgets);
      expect(find.text('L-BTC'), findsWidgets);
      expect(find.byType(AquaLinearProgressIndicator), findsOneWidget);

      // Verify the arrow icon is present (part of swap display)
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify the crypto amount is displayed
      expect(find.text('-0.001'), findsOneWidget);

      // Note: Swap transactions don't display fiat amounts

      // Verify the transaction icon is present (swap icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets(
        'should display swap transaction with correct EURx → L-BTC labeling',
        (tester) async {
      // This test demonstrates the CORRECT behavior for EURx swaps
      // It will fail initially because EURx is not in availableAssetsProvider
      // but shows what the expected behavior should be

      final swapTransaction = TestTransactionFactory.swap(
        id: 'swap_eurx_lbtc_correct_labeling',
        fromAsset: TestTransactionFactory.eurxAsset,
        toAsset: TestTransactionFactory.lbtcAsset,
        cryptoAmount: '-0.001',
      );

      // Include EURx in the assets list to simulate proper asset registration
      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: [
          TestTransactionFactory.eurxAsset,
          TestTransactionFactory.lbtcAsset,
          TestTransactionFactory.btcAsset,
          TestTransactionFactory.usdtAsset,
        ],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.eurxAsset,
          overrides: overrides,
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions list is present
      expect(find.byType(ListView), findsOneWidget);

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "EURx → L-BTC" (CORRECT labeling)
      expect(find.text('EURx'), findsWidgets);
      expect(find.text('L-BTC'), findsWidgets);

      // Verify the arrow icon is present
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify amounts are displayed
      expect(find.text('-0.001'), findsOneWidget);
      // Note: Swap transactions don't display fiat amounts

      // Verify the transaction icon is present
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets(
        'should display swap transaction with correct L-BTC → EURx labeling',
        (tester) async {
      // This test demonstrates the CORRECT behavior for L-BTC to EURx swaps

      final swapTransaction = TestTransactionFactory.swap(
        id: 'swap_lbtc_eurx_correct_labeling',
        fromAsset: TestTransactionFactory.lbtcAsset,
        toAsset: TestTransactionFactory.eurxAsset,
        cryptoAmount: '-0.001',
      );

      // Include EURx in the assets list to simulate proper asset registration
      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [swapTransaction],
        assets: [
          TestTransactionFactory.eurxAsset,
          TestTransactionFactory.lbtcAsset,
          TestTransactionFactory.btcAsset,
          TestTransactionFactory.usdtAsset,
        ],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.lbtcAsset,
          overrides: overrides,
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions list is present
      expect(find.byType(ListView), findsOneWidget);

      // Check that the swap transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the swap transaction shows "L-BTC → EURx" (CORRECT labeling)
      expect(find.text('L-BTC'), findsWidgets);
      expect(find.text('EURx'), findsWidgets);

      // Verify the arrow icon is present
      expect(find.byType(AquaIcon), findsWidgets);

      // Verify amounts are displayed
      expect(find.text('-0.001'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);

      // Verify the transaction icon is present
      expect(find.byType(AquaTransactionIcon), findsOneWidget);
    });

    testWidgets('should display lightning send transaction', (tester) async {
      // Create a lightning send transaction using the factory
      final lightningTransaction = TestTransactionFactory.transaction(
        id: 'lightning_send_123',
        asset: TestTransactionFactory.lightningAsset,
        cryptoAmount: '-0.001',
        gdkType: GdkTransactionTypeEnum.outgoing,
        dbType: TransactionDbModelType.aquaSend,
        isPending: false,
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [lightningTransaction],
        assets: [TestTransactionFactory.lightningAsset],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.lightningAsset,
          overrides: overrides,
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions list is present
      expect(find.byType(ListView), findsOneWidget);

      // Check that the lightning transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the lightning transaction shows the correct amount
      expect(find.text('-0.001'), findsOneWidget);

      // Verify the fiat amount is displayed
      expect(find.text('\$50.00'), findsOneWidget);

      // Verify the transaction icon is present (send icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);

      // Verify the lightning asset icon is present next to the title
      expect(find.byType(AquaAssetIcon), findsWidgets);
    });

    testWidgets('should display pending lightning send transaction',
        (tester) async {
      // Create a pending lightning send transaction
      final pendingLightningTransaction = TestTransactionFactory.transaction(
        id: 'pending_lightning_send_123',
        asset: TestTransactionFactory.lightningAsset,
        cryptoAmount: '-0.001',
        gdkType: GdkTransactionTypeEnum.outgoing,
        dbType: TransactionDbModelType.aquaSend,
        isPending: true,
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [pendingLightningTransaction],
        assets: [TestTransactionFactory.lightningAsset],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: AssetTransactionTestWrapper(
            asset: TestTransactionFactory.lightningAsset,
            overrides: overrides,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions lists are present (pending and confirmed)
      expect(find.byType(ListView), findsNWidgets(2));

      // Check that the lightning transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the lightning transaction shows the correct amount
      expect(find.text('-0.001'), findsOneWidget);

      // Verify the fiat amount is displayed
      expect(find.text('\$50.00'), findsOneWidget);

      // Verify the transaction icon is present (send icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);

      // Verify the lightning asset icon is present next to the title
      expect(find.byType(AquaAssetIcon), findsWidgets);

      // Verify it shows as pending (progress indicator)
      expect(find.byType(AquaLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display redeposit transaction', (tester) async {
      // Create a redeposit transaction using the factory
      final redepositTransaction = TestTransactionFactory.transaction(
        id: 'redeposit_123',
        asset: TestTransactionFactory.lbtcAsset,
        cryptoAmount: '0.001',
        gdkType: GdkTransactionTypeEnum.redeposit,
        dbType: TransactionDbModelType.aquaSend,
        isPending: false,
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [redepositTransaction],
        assets: [TestTransactionFactory.lbtcAsset],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        AssetTransactionTestWrapper(
          asset: TestTransactionFactory.lbtcAsset,
          overrides: overrides,
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions list is present
      expect(find.byType(ListView), findsOneWidget);

      // Check that the redeposit transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the redeposit transaction shows the correct amount
      expect(find.text('0.001'), findsOneWidget);

      // Verify the fiat amount is displayed
      expect(find.text('\$50.00'), findsOneWidget);

      // Verify the transaction icon is present
      expect(find.byType(AquaTransactionIcon), findsOneWidget);

      // Verify it shows "Redeposited" text
      expect(find.text('Redeposited'), findsOneWidget);
    });

    testWidgets('should display pending redeposit transaction', (tester) async {
      // Create a pending redeposit transaction
      final pendingRedepositTransaction = TestTransactionFactory.transaction(
        id: 'pending_redeposit_123',
        asset: TestTransactionFactory.lbtcAsset,
        cryptoAmount: '0.001',
        gdkType: GdkTransactionTypeEnum.redeposit,
        dbType: TransactionDbModelType.aquaSend,
        isPending: true,
      );

      final overrides = AssetTransactionTestProviders.createOverrides(
        transactions: [pendingRedepositTransaction],
        assets: [TestTransactionFactory.lbtcAsset],
        fiatAmount: '\$50.00',
      );

      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: AssetTransactionTestWrapper(
            asset: TestTransactionFactory.lbtcAsset,
            overrides: overrides,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the widget is rendered
      expect(find.byType(AssetTransactions), findsOneWidget);

      // Verify that the transactions lists are present (pending and confirmed)
      expect(find.byType(ListView), findsNWidgets(2));

      // Check that the redeposit transaction item is displayed
      expect(find.byType(AquaTransactionItem), findsOneWidget);

      // Verify the redeposit transaction shows the correct amount
      expect(find.text('0.001'), findsOneWidget);

      // Verify the fiat amount is displayed
      expect(find.text('\$50.00'), findsOneWidget);

      // Verify the transaction icon is present (redeposit icon)
      expect(find.byType(AquaTransactionIcon), findsOneWidget);

      // Verify it doesn't show "Redeposited" since it's pending
      expect(find.text('Redeposited'), findsNothing);

      // Verify it shows "Sending" since it's a pending send transaction
      expect(find.text('Sending'), findsOneWidget);

      // Verify it shows as pending (progress indicator)
      expect(find.byType(AquaLinearProgressIndicator), findsOneWidget);
    });
  });
}
