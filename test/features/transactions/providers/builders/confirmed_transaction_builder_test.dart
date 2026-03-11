import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late ConfirmedTransactionUiModelsBuilder builder;
  late MockConfirmationService mockConfirmationService;
  late MockTransactionStrategyFactory mockStrategyFactory;
  late MockPegOrderStorage mockPegStorage;

  setUpAll(() {
    registerFallbackValue(Asset.btc());
    registerFallbackValue(_createMockNetworkTransaction());
    registerFallbackValue(_createMockDbTransaction());
    registerFallbackValue(_createMockStrategyArgs());
  });

  setUp(() {
    mockConfirmationService = MockConfirmationService();
    mockStrategyFactory = MockTransactionStrategyFactory();
    mockPegStorage = MockPegOrderStorage();

    when(() => mockPegStorage.getAllPegOrders())
        .thenAnswer((_) async => <PegOrderDbModel>[]);

    builder = ConfirmedTransactionUiModelsBuilder(
      confirmationService: mockConfirmationService,
      strategyFactory: mockStrategyFactory,
      pegStorage: mockPegStorage,
    );
  });

  group('ConfirmedTransactionBuilder - build', () {
    test('includes confirmed transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'confirmed_tx',
        type: GdkTransactionTypeEnum.incoming,
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('excludes pending transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'pending_tx',
        type: GdkTransactionTypeEnum.incoming,
        blockHeight: 800000,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => true);

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });

    test('skips invalid transaction types', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'invalid_tx',
        type: GdkTransactionTypeEnum.mixed,
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

    test('processes incoming transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        type: GdkTransactionTypeEnum.incoming,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('processes outgoing transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        type: GdkTransactionTypeEnum.outgoing,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('processes swap transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        type: GdkTransactionTypeEnum.swap,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('processes redeposit transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        type: GdkTransactionTypeEnum.redeposit,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
    });

    test('skips transactions where strategy returns null', () async {
      final networkTxn = _createMockNetworkTransaction(
        type: GdkTransactionTypeEnum.incoming,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any())).thenReturn(null);

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, isEmpty);
    });

    test('processes valid types and skips invalid types in mixed batch',
        () async {
      final networkTxns = [
        _createMockNetworkTransaction(
          txhash: 'valid_1',
          type: GdkTransactionTypeEnum.incoming,
        ),
        _createMockNetworkTransaction(
          txhash: 'invalid_1',
          type: GdkTransactionTypeEnum.mixed,
        ),
        _createMockNetworkTransaction(
          txhash: 'valid_2',
          type: GdkTransactionTypeEnum.outgoing,
        ),
        _createMockNetworkTransaction(
          txhash: 'invalid_2',
          type: GdkTransactionTypeEnum.unknown,
        ),
        _createMockNetworkTransaction(
          txhash: 'valid_3',
          type: GdkTransactionTypeEnum.swap,
        ),
      ];

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: networkTxns,
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      // Should only process the 3 valid transactions (incoming, outgoing, swap)
      expect(result, hasLength(3));
    });
  });

  group('ConfirmedTransactionBuilder - LBTC Fee Flag', () {
    test('applies fee flag to LBTC outgoing with other assets', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'fee_tx',
        type: GdkTransactionTypeEnum.outgoing,
        satoshi: {
          Asset.lbtc().id: -1000,
          Asset.usdtLiquid().id: -50000000,
        },
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [Asset.lbtc(), Asset.usdtLiquid()],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
      result.first.map(
        normal: (model) {
          expect(model.feeForAsset, isNotNull);
          expect(model.feeForAsset!.id, Asset.usdtLiquid().id);
        },
        pending: (_) => fail('Should be normal'),
      );
    });

    test('does not apply fee flag to LBTC-only transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'normal_tx',
        type: GdkTransactionTypeEnum.outgoing,
        satoshi: {
          Asset.lbtc().id: -100000000,
        },
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
      result.first.map(
        normal: (model) => expect(model.feeForAsset, isNull),
        pending: (_) => fail('Should be normal'),
      );
    });

    test('does not apply fee flag to non-LBTC assets', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'usdt_tx',
        type: GdkTransactionTypeEnum.outgoing,
        satoshi: {
          Asset.lbtc().id: -1000,
          Asset.usdtLiquid().id: -50000000,
        },
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.usdtLiquid(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
      result.first.map(
        normal: (model) => expect(model.feeForAsset, isNull),
        pending: (_) => fail('Should be normal'),
      );
    });

    test('does not apply fee flag to incoming transactions', () async {
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'incoming_tx',
        type: GdkTransactionTypeEnum.incoming,
        satoshi: {
          Asset.lbtc().id: 100000000,
          Asset.usdtLiquid().id: 50000000,
        },
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
      result.first.map(
        normal: (model) => expect(model.feeForAsset, isNull),
        pending: (_) => fail('Should be normal'),
      );
    });

    test('handles null satoshi map gracefully', () async {
      const networkTxn = GdkTransaction(
        txhash: 'no_satoshi_tx',
        type: GdkTransactionTypeEnum.outgoing,
        satoshi: null,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(1));
      result.first.map(
        normal: (model) => expect(model.feeForAsset, isNull),
        pending: (_) => fail('Should be normal'),
      );
    });
  });

  group('ConfirmedTransactionBuilder - Integration', () {
    test('processes multiple transactions correctly', () async {
      final networkTxns = [
        _createMockNetworkTransaction(
          txhash: 'tx_1',
          type: GdkTransactionTypeEnum.incoming,
        ),
        _createMockNetworkTransaction(
          txhash: 'tx_2',
          type: GdkTransactionTypeEnum.outgoing,
        ),
        _createMockNetworkTransaction(
          txhash: 'tx_3',
          type: GdkTransactionTypeEnum.incoming,
        ),
      ];

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: networkTxns,
        localDbTxns: [],
        availableAssets: [],
      );

      final result = await builder.build(args);

      expect(result, hasLength(3));
    });

    test('matches db transactions with network transactions', () async {
      final dbTxn = _createMockDbTransaction(txhash: 'matching_tx');
      final networkTxn = _createMockNetworkTransaction(
        txhash: 'matching_tx',
        type: GdkTransactionTypeEnum.incoming,
      );

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [dbTxn],
        availableAssets: [],
      );

      await builder.build(args);

      // Verify strategy was created with both db and network transaction
      verify(() => mockStrategyFactory.create(
            dbTransaction: dbTxn,
            networkTransaction: networkTxn,
            asset: args.asset,
          )).called(1);
    });
  });

  group('ConfirmedTransactionBuilder - Direct Peg-In Matching', () {
    test('matches direct peg-in by receiveAddress for L-BTC transactions',
        () async {
      const receiveAddress = 'lq1abc123';
      const networkTxn = GdkTransaction(
        txhash: 'lbtc_tx_hash',
        type: GdkTransactionTypeEnum.incoming,
        blockHeight: 800000,
        outputs: [
          GdkTransactionInOut(
            address: receiveAddress,
            isRelevant: true,
          ),
        ],
      );

      const pegOrder = PegOrderDbModel(
        orderId: 'peg_order_123',
        isPegIn: true,
        txhash: 'btc_deposit_hash', // Different from L-BTC tx hash!
        receiveAddress: receiveAddress, // Matches the output address
        amount: 100000,
        statusJson: '{"order_id":"peg_order_123","peg_in":true}',
      );

      when(() => mockPegStorage.getAllPegOrders())
          .thenAnswer((_) async => [pegOrder]);

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      await builder.build(args);

      // Verify the strategy was called with a dbTransaction created from peg order
      verify(() => mockStrategyFactory.create(
            dbTransaction: any(
              named: 'dbTransaction',
              that: isNotNull,
            ),
            networkTransaction: networkTxn,
            asset: args.asset,
          )).called(1);
    });

    test('does not match peg order when receiveAddress does not match',
        () async {
      const networkTxn = GdkTransaction(
        txhash: 'lbtc_tx_hash',
        type: GdkTransactionTypeEnum.incoming,
        blockHeight: 800000,
        outputs: [
          GdkTransactionInOut(
            address: 'different_address',
            isRelevant: true,
          ),
        ],
      );

      const pegOrder = PegOrderDbModel(
        orderId: 'peg_order_123',
        isPegIn: true,
        txhash: 'btc_deposit_hash',
        receiveAddress: 'lq1abc123', // Different from output address!
        amount: 100000,
        statusJson: '{"order_id":"peg_order_123","peg_in":true}',
      );

      when(() => mockPegStorage.getAllPegOrders())
          .thenAnswer((_) async => [pegOrder]);

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      await builder.build(args);

      // Verify the strategy was called with null dbTransaction
      verify(() => mockStrategyFactory.create(
            dbTransaction: null,
            networkTransaction: networkTxn,
            asset: args.asset,
          )).called(1);
    });

    test('matches peg order by txhash for BTC transactions', () async {
      const txhash = 'matching_btc_tx_hash';
      const networkTxn = GdkTransaction(
        txhash: txhash,
        type: GdkTransactionTypeEnum.incoming,
        blockHeight: 800000,
      );

      const pegOrder = PegOrderDbModel(
        orderId: 'peg_order_123',
        isPegIn: true,
        txhash: txhash, // Same as network tx hash
        receiveAddress: 'lbtc_address',
        amount: 100000,
        statusJson: '{"order_id":"peg_order_123","peg_in":true}',
      );

      when(() => mockPegStorage.getAllPegOrders())
          .thenAnswer((_) async => [pegOrder]);

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.btc(),
        networkTxns: [networkTxn],
        localDbTxns: [],
        availableAssets: [],
      );

      await builder.build(args);

      // Verify the strategy was called with a dbTransaction
      verify(() => mockStrategyFactory.create(
            dbTransaction: any(
              named: 'dbTransaction',
              that: isNotNull,
            ),
            networkTransaction: networkTxn,
            asset: args.asset,
          )).called(1);
    });

    test('prefers local db transaction over peg storage', () async {
      const txhash = 'known_tx_hash';
      final dbTxn = TransactionDbModel(
        txhash: txhash,
        assetId: Asset.lbtc().id,
      );
      const networkTxn = GdkTransaction(
        txhash: txhash,
        type: GdkTransactionTypeEnum.incoming,
        blockHeight: 800000,
      );

      // Peg storage should not be called when local db has the transaction
      when(() => mockPegStorage.getAllPegOrders()).thenAnswer((_) async => []);

      when(() => mockConfirmationService.isTransactionPending(
            asset: any(named: 'asset'),
            transaction: any(named: 'transaction'),
            dbTransaction: any(named: 'dbTransaction'),
          )).thenAnswer((_) async => false);

      final mockStrategy = MockTransactionTypeStrategy();
      when(() => mockStrategyFactory.create(
            dbTransaction: any(named: 'dbTransaction'),
            networkTransaction: any(named: 'networkTransaction'),
            asset: any(named: 'asset'),
          )).thenReturn(mockStrategy);
      when(() => mockStrategy.createConfirmedListItems(any()))
          .thenReturn(_createMockNormalUiModel());

      final args = TransactionBuilderArgs(
        asset: Asset.lbtc(),
        networkTxns: [networkTxn],
        localDbTxns: [dbTxn],
        availableAssets: [],
      );

      await builder.build(args);

      // Verify the strategy was called with the local db transaction
      verify(() => mockStrategyFactory.create(
            dbTransaction: dbTxn,
            networkTransaction: networkTxn,
            asset: args.asset,
          )).called(1);
    });
  });
}

GdkTransaction _createMockNetworkTransaction({
  String? txhash,
  GdkTransactionTypeEnum? type,
  int? blockHeight,
  Map<String, int>? satoshi,
}) {
  return GdkTransaction(
    txhash: txhash ?? 'mock_tx',
    blockHeight: blockHeight,
    type: type ?? GdkTransactionTypeEnum.incoming,
    satoshi: satoshi ?? {},
  );
}

TransactionDbModel _createMockDbTransaction({
  String? txhash,
}) {
  return TransactionDbModel(
    txhash: txhash ?? 'mock_db_tx',
    assetId: Asset.btc().id,
  );
}

TransactionUiModel _createMockNormalUiModel() {
  return TransactionUiModel.normal(
    createdAt: DateTime.now(),
    cryptoAmount: '0.01 BTC',
    asset: Asset.btc(),
    transaction: _createMockNetworkTransaction(),
    otherAsset: null,
  );
}

TransactionStrategyArgs _createMockStrategyArgs() {
  return TransactionStrategyArgs(
    asset: Asset.btc(),
    availableAssets: [],
  );
}
