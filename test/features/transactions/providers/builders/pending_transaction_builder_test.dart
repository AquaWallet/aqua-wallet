import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late PendingTransactionUiModelsBuilder builder;
  late MockConfirmationService mockConfirmationService;
  late MockSwapOrderStorageNotifier mockSwapStorage;
  late MockPegStorageProvider mockPegStorage;
  late MockTransactionStrategyFactory mockStrategyFactory;

  setUpAll(() {
    registerFallbackValue(Asset.btc());
    registerFallbackValue(_createMockNetworkTransaction());
    registerFallbackValue(_createMockDbTransaction());
    registerFallbackValue(_createMockStrategyArgs());
  });

  setUp(() {
    mockConfirmationService = MockConfirmationService();
    mockSwapStorage = MockSwapOrderStorageNotifier();
    mockPegStorage = MockPegStorageProvider();
    mockStrategyFactory = MockTransactionStrategyFactory();

    builder = PendingTransactionUiModelsBuilder(
      confirmationService: mockConfirmationService,
      swapStorage: mockSwapStorage,
      pegStorage: mockPegStorage,
      strategyFactory: mockStrategyFactory,
      boltzSwaps: [], // Empty list for most tests
    );

    // Default mocks
    when(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
          depositAsset: any(named: 'depositAsset'),
          settleAsset: any(named: 'settleAsset'),
        )).thenAnswer((_) async => []);
    when(() => mockPegStorage.getAllPendingSettlementPegOrders())
        .thenAnswer((_) async => []);
    when(() => mockPegStorage.getAllPegOrders())
        .thenAnswer((_) async => <PegOrderDbModel>[]);
  });

  group('PendingTransactionBuilder - collectPendingTransactions', () {
    test('collects pending swap orders', () async {
      final swapOrder = _createMockSwapOrder(
        orderId: 'swap_1',
        onchainTxHash: 'swap_tx_1',
      );

      when(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
            depositAsset: any(named: 'depositAsset'),
            settleAsset: any(named: 'settleAsset'),
          )).thenAnswer(
        (_) async => [swapOrder],
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.usdtLiquid(),
        networkTxns: [],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
      verify(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
            depositAsset: any(named: 'depositAsset'),
            settleAsset: Asset.usdtLiquid(),
          )).called(1);
    });

    test('collects pending peg orders for BTC', () async {
      final pegOrder = _createMockPegOrder(
        orderId: 'peg_1',
        txhash: 'peg_tx_1',
      );

      when(() => mockPegStorage.getAllPendingSettlementPegOrders())
          .thenAnswer((_) async => [pegOrder]);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
      verify(() => mockPegStorage.getAllPendingSettlementPegOrders()).called(1);
    });

    test('does not collect peg orders for non-BTC/LBTC assets', () async {
      when(() => mockPegStorage.getAllPendingSettlementPegOrders())
          .thenAnswer((_) async => [_createMockPegOrder()]);

      final args = TransactionBuilderArgs(
        asset: Asset.usdtLiquid(),
        networkTxns: [],
        localDbTxns: [],
        availableAssets: [],
      );

      await builder.build(args);

      // Should not try to fetch peg orders for USDt
      verifyNever(() => mockPegStorage.getAllPendingSettlementPegOrders());
    });

    test('deduplicates transactions with same txhash', () async {
      final swapOrder = _createMockSwapOrder(
        orderId: 'swap_1',
        onchainTxHash: 'same_hash',
      );
      final pegOrder = _createMockPegOrder(
        orderId: 'peg_1',
        txhash: 'same_hash',
      );

      when(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
            depositAsset: any(named: 'depositAsset'),
            settleAsset: any(named: 'settleAsset'),
          )).thenAnswer(
        (_) async => [swapOrder],
      );
      when(() => mockPegStorage.getAllPendingSettlementPegOrders())
          .thenAnswer((_) async => [pegOrder]);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      // Should only have one transaction despite two orders with same hash
      expect(result, hasLength(1));
    });

    test('includes ghost transactions not yet in network', () async {
      final ghostTxn = _createMockDbTransaction(
        txhash: 'ghost_1',
        isGhost: true,
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [],
        localDbTxns: [ghostTxn],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('includes ghost transactions with insufficient confirmations',
        () async {
      final ghostTxn = _createMockDbTransaction(
        txhash: 'ghost_1',
        isGhost: true,
      );
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'ghost_1',
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.getConfirmationCount(
            any(),
            any(),
          )).thenAnswer((_) async => 0);
      when(() => mockConfirmationService.getRequiredConfirmationCount(any()))
          .thenReturn(1);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [ghostTxn],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('excludes ghost transactions with sufficient confirmations', () async {
      final ghostTxn = _createMockDbTransaction(
        txhash: 'ghost_1',
        isGhost: true,
      );
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'ghost_1',
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.getConfirmationCount(
            any(),
            any(),
          )).thenAnswer((_) async => 10);
      when(() => mockConfirmationService.getRequiredConfirmationCount(any()))
          .thenReturn(1);
      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false); // Has enough confirmations

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [ghostTxn],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });
  });

  group('PendingTransactionBuilder - Ghost Send Transactions', () {
    test(
        'ghost send with null ghostTxnCreatedAt does not show (expected behavior)',
        () async {
      final ghostSendTxn = _createMockDbTransaction(
        txhash: 'ghost_send_no_date',
        isGhost: true,
        type: TransactionDbModelType.aquaSend,
        assetId: Asset.btc().id,
        ghostTxnAmount: -10000000,
        ghostTxnCreatedAt: null, // Missing timestamp
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any())).thenReturn(
          null); // Strategy returns null because getCreatedAt returns null

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [],
        localDbTxns: [ghostSendTxn],
        availableAssets: [Asset.btc()],
      );

      final result = await builder.build(args);

      // EXPECTED: Transaction doesn't show because ghostTxnCreatedAt is null
      // This means ghost transactions MUST have ghostTxnCreatedAt set when created
      expect(result, isEmpty);
    });

    test('shows ghost send transaction not yet on network', () async {
      final ghostSendTxn = _createMockDbTransaction(
        txhash: 'ghost_send_1',
        isGhost: true,
        type: TransactionDbModelType.aquaSend,
        assetId: Asset.btc().id,
        ghostTxnAmount: -10000000, // Negative for send
        ghostTxnCreatedAt: DateTime.now(),
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [], // Not on network yet
        localDbTxns: [ghostSendTxn],
        availableAssets: [Asset.btc()],
      );

      final result = await builder.build(args);

      // Verify the ghost send transaction shows up
      expect(result, hasLength(1));

      // Verify strategy was called with correct arguments
      final capturedArgs = verify(
        () => mockStrategy.createPendingListItems(captureAny()),
      ).captured.single as TransactionStrategyArgs;

      expect(capturedArgs.asset, Asset.btc());
      expect(capturedArgs.dbTransaction, ghostSendTxn);
      expect(capturedArgs.networkTransaction, isNull);
    });

    test('shows ghost receive transaction not yet on network', () async {
      final ghostReceiveTxn = _createMockDbTransaction(
        txhash: 'ghost_receive_1',
        isGhost: true,
        // No type specified - receive transactions don't have a specific db type
        assetId: Asset.btc().id,
        ghostTxnAmount: 10000000, // Positive for receive
        ghostTxnCreatedAt: DateTime.now(),
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [], // Not on network yet
        localDbTxns: [ghostReceiveTxn],
        availableAssets: [Asset.btc()],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test(
        'ghost send transaction filters out if strategy returns false for shouldShow',
        () async {
      final ghostSendTxn = _createMockDbTransaction(
        txhash: 'ghost_send_wrong_asset',
        isGhost: true,
        type: TransactionDbModelType.aquaSend,
        assetId: Asset.usdtLiquid().id,
        ghostTxnAmount: -10000000,
        ghostTxnCreatedAt: DateTime.now(),
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(false); // Should not show on BTC page
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(), // Looking at BTC page
        networkTxns: [],
        localDbTxns: [ghostSendTxn],
        availableAssets: [Asset.btc(), Asset.usdtLiquid()],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });

    test(
        'ghost send transaction with null createPendingListItems is filtered out',
        () async {
      final ghostSendTxn = _createMockDbTransaction(
        txhash: 'ghost_send_null_result',
        isGhost: true,
        type: TransactionDbModelType.aquaSend,
        assetId: Asset.btc().id,
        ghostTxnAmount: -10000000,
        ghostTxnCreatedAt: DateTime.now(),
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(null); // Strategy returns null

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [],
        localDbTxns: [ghostSendTxn],
        availableAssets: [Asset.btc()],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });
  });

  group('PendingTransactionBuilder - buildPendingDbTransactions', () {
    test('filters out transactions that should not show on asset page',
        () async {
      final swapOrder = _createMockSwapOrder(
        orderId: 'swap_1',
        onchainTxHash: 'swap_tx_1',
      );

      when(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
            depositAsset: any(named: 'depositAsset'),
            settleAsset: any(named: 'settleAsset'),
          )).thenAnswer(
        (_) async => [swapOrder],
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(false); // Should not show
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.usdtLiquid(),
        networkTxns: [],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });

    test('filters out transactions where strategy returns null', () async {
      final swapOrder = _createMockSwapOrder(
        orderId: 'swap_1',
        onchainTxHash: 'swap_tx_1',
      );

      when(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
            depositAsset: any(named: 'depositAsset'),
            settleAsset: any(named: 'settleAsset'),
          )).thenAnswer(
        (_) async => [swapOrder],
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any())).thenReturn(null);

      final args = TransactionBuilderArgs(
        asset: Asset.usdtLiquid(),
        networkTxns: [],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });
  });

  group('PendingTransactionBuilder - buildUnconfirmedNetworkTransactions', () {
    test('includes network transactions that are pending', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'pending_tx',
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => true);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('excludes network transactions that are not pending', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'confirmed_tx',
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });

    test('excludes transactions already processed as pending db transactions',
        () async {
      final swapOrder = _createMockSwapOrder(
        orderId: 'swap_1',
        onchainTxHash: 'tx_1',
      );
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'tx_1', // Same hash as swap order
        blockHeight: 800000,
      );

      when(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
            depositAsset: any(named: 'depositAsset'),
            settleAsset: any(named: 'settleAsset'),
          )).thenAnswer(
        (_) async => [swapOrder],
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.usdtLiquid(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      // Should only have one transaction, not two
      expect(result, hasLength(1));
    });
  });

  group('PendingTransactionBuilder - Boltz Transactions', () {
    test(
        'shows Boltz transaction broadcasted by Aqua but not yet seen in network',
        () async {
      // Boltz transaction with a txhash (broadcasted) but not in network yet
      final boltzTxn = _createMockDbTransaction(
        txhash: 'boltz_tx_hash_1',
        isBoltz: true,
        serviceOrderId: 'boltz_order_1',
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [], // Not seen in network
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builder.build(args);

      // Should show as pending since it's broadcasted but not in network
      expect(result, hasLength(1));
    });

    test(
        'shows Boltz transaction seen in network with insufficient confirmations',
        () async {
      final boltzTxn = _createMockDbTransaction(
        txhash: 'boltz_tx_hash_2',
        isBoltz: true,
        serviceOrderId: 'boltz_order_2',
      );
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'boltz_tx_hash_2',
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.getConfirmationCount(
            any(),
            any(),
          )).thenAnswer((_) async => 0); // 0 confirmations
      when(() => mockConfirmationService.getRequiredConfirmationCount(any()))
          .thenReturn(2); // Requires 2

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builder.build(args);

      // Should show as pending since confirmations < threshold
      expect(result, hasLength(1));
    });

    test(
        'excludes Boltz transaction seen in network with sufficient confirmations',
        () async {
      final boltzTxn = _createMockDbTransaction(
        txhash: 'boltz_tx_hash_3',
        isBoltz: true,
        serviceOrderId: 'boltz_order_3',
      );
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'boltz_tx_hash_3',
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.getConfirmationCount(
            any(),
            any(),
          )).thenAnswer((_) async => 10); // 10 confirmations
      when(() => mockConfirmationService.getRequiredConfirmationCount(any()))
          .thenReturn(2); // Requires 2
      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builder.build(args);

      // Should NOT show as pending since confirmations >= threshold
      expect(result, isEmpty);
    });

    test('excludes Boltz transaction without txhash and not in network',
        () async {
      // Boltz transaction with empty txhash (not broadcasted yet)
      final boltzTxn = _createMockDbTransaction(
        txhash: '', // Empty txhash - not broadcasted
        isBoltz: true,
        serviceOrderId: 'boltz_order_4',
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [],
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builder.build(args);

      // Should NOT show - not broadcasted AND not in network
      expect(result, isEmpty);
    });

    test('excludes Boltz transaction in terminal state (swapExpired)',
        () async {
      final boltzTxn = _createMockDbTransaction(
        txhash: 'boltz_terminal_tx',
        isBoltz: true,
        serviceOrderId: 'boltz_order_terminal',
      );

      // Create builder with a terminal Boltz swap
      final terminalBoltzSwap = _createMockBoltzSwapDbModel(
        boltzId: 'boltz_order_terminal',
        lastKnownStatus: BoltzSwapStatus.swapExpired, // Terminal state
      );

      final builderWithTerminalSwap = PendingTransactionUiModelsBuilder(
        confirmationService: mockConfirmationService,
        swapStorage: mockSwapStorage,
        pegStorage: mockPegStorage,
        strategyFactory: mockStrategyFactory,
        boltzSwaps: [terminalBoltzSwap],
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [],
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builderWithTerminalSwap.build(args);

      // Should NOT show - terminal state should be filtered out
      expect(result, isEmpty);
    });

    test('excludes Boltz transaction in terminal state (transactionClaimed)',
        () async {
      final boltzTxn = _createMockDbTransaction(
        txhash: 'boltz_claimed_tx',
        isBoltz: true,
        serviceOrderId: 'boltz_order_claimed',
      );

      final claimedBoltzSwap = _createMockBoltzSwapDbModel(
        boltzId: 'boltz_order_claimed',
        lastKnownStatus: BoltzSwapStatus.transactionClaimed,
      );

      final builderWithClaimedSwap = PendingTransactionUiModelsBuilder(
        confirmationService: mockConfirmationService,
        swapStorage: mockSwapStorage,
        pegStorage: mockPegStorage,
        strategyFactory: mockStrategyFactory,
        boltzSwaps: [claimedBoltzSwap],
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [],
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builderWithClaimedSwap.build(args);

      expect(result, isEmpty);
    });

    test('deduplicates Boltz transactions by serviceOrderId', () async {
      // Two Boltz transactions with same serviceOrderId
      final boltzTxn1 = _createMockDbTransaction(
        txhash: 'boltz_tx_dup_1',
        isBoltz: true,
        serviceOrderId: 'same_order_id',
      );
      final boltzTxn2 = _createMockDbTransaction(
        txhash: 'boltz_tx_dup_2',
        isBoltz: true,
        serviceOrderId: 'same_order_id', // Same order ID
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [],
        localDbTxns: [boltzTxn1, boltzTxn2],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builder.build(args);

      // Should only have one, second one deduplicated
      expect(result, hasLength(1));
    });

    test('deduplicates Boltz transactions by txhash', () async {
      // Two Boltz transactions with same txhash
      final boltzTxn1 = _createMockDbTransaction(
        txhash: 'same_boltz_hash',
        isBoltz: true,
        serviceOrderId: 'boltz_order_a',
      );
      final boltzTxn2 = _createMockDbTransaction(
        txhash: 'same_boltz_hash', // Same txhash
        isBoltz: true,
        serviceOrderId: 'boltz_order_b',
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [],
        localDbTxns: [boltzTxn1, boltzTxn2],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builder.build(args);

      // Should only have one, second one deduplicated by txhash
      expect(result, hasLength(1));
    });

    test('shows non-terminal Boltz swap as pending', () async {
      final boltzTxn = _createMockDbTransaction(
        txhash: 'boltz_pending_tx',
        isBoltz: true,
        serviceOrderId: 'boltz_order_pending',
      );

      // Non-terminal status
      final pendingBoltzSwap = _createMockBoltzSwapDbModel(
        boltzId: 'boltz_order_pending',
        lastKnownStatus: BoltzSwapStatus.transactionMempool, // Pending state
      );

      final builderWithPendingSwap = PendingTransactionUiModelsBuilder(
        confirmationService: mockConfirmationService,
        swapStorage: mockSwapStorage,
        pegStorage: mockPegStorage,
        strategyFactory: mockStrategyFactory,
        boltzSwaps: [pendingBoltzSwap],
      );

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [],
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builderWithPendingSwap.build(args);

      // Should show - non-terminal status
      expect(result, hasLength(1));
    });

    test('Boltz transaction with blockHeight null is pending when in network',
        () async {
      final boltzTxn = _createMockDbTransaction(
        txhash: 'boltz_mempool_tx',
        isBoltz: true,
        serviceOrderId: 'boltz_order_mempool',
      );
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'boltz_mempool_tx',
        blockHeight: null, // In mempool, not confirmed
      );

      when(() => mockConfirmationService.getConfirmationCount(
            any(),
            0, // blockHeight ?? 0
          )).thenAnswer((_) async => 0);
      when(() => mockConfirmationService.getRequiredConfirmationCount(any()))
          .thenReturn(1);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.shouldShowTransactionForAsset(any()))
          .thenReturn(true);
      when(() => mockStrategy.createPendingListItems(any()))
          .thenReturn(_createMockPendingUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [boltzTxn],
        availableAssets: [Asset.lbtc()],
      );

      final result = await builder.build(args);

      // Should show as pending - in mempool, 0 confirmations
      expect(result, hasLength(1));
    });
  });
}

GdkTransaction _createMockNetworkTransaction({
  String? txhash,
  int? blockHeight,
}) {
  return GdkTransaction(
    txhash: txhash ?? 'mock_tx',
    blockHeight: blockHeight,
    type: GdkTransactionTypeEnum.incoming,
    satoshi: {},
  );
}

TransactionDbModel _createMockDbTransaction({
  String? txhash,
  bool? isGhost,
  bool isBoltz = false,
  TransactionDbModelType? type,
  String? assetId,
  int? ghostTxnAmount,
  DateTime? ghostTxnCreatedAt,
  String? serviceOrderId,
}) {
  // If isBoltz is true and no type is specified, default to boltzSwap
  final effectiveType =
      type ?? (isBoltz ? TransactionDbModelType.boltzSwap : null);

  return TransactionDbModel(
    txhash: txhash ?? 'mock_db_tx',
    assetId: assetId ?? Asset.btc().id,
    isGhost: isGhost ?? false,
    type: effectiveType,
    ghostTxnAmount: ghostTxnAmount,
    ghostTxnCreatedAt: ghostTxnCreatedAt,
    serviceOrderId: serviceOrderId,
  );
}

SwapOrderDbModel _createMockSwapOrder({
  String? orderId,
  String? onchainTxHash,
}) {
  return SwapOrderDbModel(
    orderId: orderId ?? 'mock_order',
    createdAt: DateTime.now(),
    fromAsset: Asset.lbtc().id,
    toAsset: Asset.usdtLiquid().id,
    depositAddress: 'mock_deposit',
    settleAddress: 'mock_settle',
    depositAmount: '1000000',
    serviceFeeType: SwapFeeType.flatFee,
    serviceFeeValue: '1000',
    serviceFeeCurrency: SwapFeeCurrency.sats,
    status: SwapOrderStatus.waiting,
    type: SwapOrderType.fixed,
    serviceType: SwapServiceSource.sideshift,
    onchainTxHash: onchainTxHash,
  );
}

PegOrderDbModel _createMockPegOrder({
  String? orderId,
  String? txhash,
}) {
  // Create minimal PegOrderDbModel directly
  return PegOrderDbModel(
    orderId: orderId ?? 'mock_peg',
    isPegIn: true,
    amount: 100000000,
    statusJson: '{}',
    createdAt: DateTime.now(),
    txhash: txhash,
  );
}

TransactionUiModel _createMockPendingUiModel() {
  return TransactionUiModel.pending(
    createdAt: DateTime.now(),
    cryptoAmount: '0.01 BTC',
    asset: Asset.btc(),
    transactionId: 'mock_tx',
    otherAsset: null,
  );
}

TransactionStrategyArgs _createMockStrategyArgs() {
  return TransactionStrategyArgs(
    asset: Asset.btc(),
    availableAssets: [],
  );
}

BoltzSwapDbModel _createMockBoltzSwapDbModel({
  required String boltzId,
  BoltzSwapStatus? lastKnownStatus,
}) {
  return BoltzSwapDbModel(
    boltzId: boltzId,
    kind: SwapType.submarine,
    network: Chain.liquid,
    hashlock: 'mock_hashlock',
    receiverPubkey: 'mock_receiver_pubkey',
    senderPubkey: 'mock_sender_pubkey',
    invoice: 'lnbc1mock_invoice',
    outAmount: 100000,
    blindingKey: 'mock_blinding_key',
    locktime: 144,
    scriptAddress: 'mock_script_address',
    lastKnownStatus: lastKnownStatus,
    createdAt: DateTime.now(),
  );
}
