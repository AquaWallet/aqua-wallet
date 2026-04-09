import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/services/confirmation_service.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ConfirmationService confirmationService;
  late MockAquaProvider mockAquaProvider;
  late MockPegStorageProvider mockPegStorage;
  late MockPegSwapMatcher mockPegSwapMatcher;

  setUpAll(() {
    registerFallbackValue(Asset.btc());
    registerFallbackValue(const TransactionDbModel(
      txhash: '',
      assetId: '',
      type: TransactionDbModelType.aquaSend,
    ));
  });

  setUp(() {
    mockAquaProvider = MockAquaProvider();
    mockPegStorage = MockPegStorageProvider();
    mockPegSwapMatcher = MockPegSwapMatcher();

    confirmationService = ConfirmationService(
      aquaProvider: mockAquaProvider,
      pegStorage: mockPegStorage,
      pegSwapMatcher: mockPegSwapMatcher,
      getNetworkTransactions: (_) async => [],
    );
  });

  group('ConfirmationService', () {
    group('getConfirmationCount', () {
      test('returns confirmation count from aqua provider', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(5));

        final result = await confirmationService.getConfirmationCount(
          Asset.btc(),
          800000,
        );

        expect(result, equals(5));
        verify(() => mockAquaProvider.getConfirmationCount(
              asset: Asset.btc(),
              transactionBlockHeight: 800000,
            )).called(1);
      });

      test('returns 0 for unconfirmed transactions (blockHeight 0)', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: 0,
            )).thenAnswer((_) => Stream.value(0));

        final result = await confirmationService.getConfirmationCount(
          Asset.btc(),
          0,
        );

        expect(result, equals(0));
      });

      test('works for Liquid assets', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(2));

        final result = await confirmationService.getConfirmationCount(
          Asset.lbtc(),
          1000000,
        );

        expect(result, equals(2));
        verify(() => mockAquaProvider.getConfirmationCount(
              asset: Asset.lbtc(),
              transactionBlockHeight: 1000000,
            )).called(1);
      });
    });

    group('getRequiredConfirmationCount', () {
      test('returns correct threshold for BTC', () {
        final result = confirmationService.getRequiredConfirmationCount(
          Asset.btc(),
        );

        expect(result, equals(onchainConfirmationBlockCount));
      });

      test('returns correct threshold for Liquid assets', () {
        final lbtcResult = confirmationService.getRequiredConfirmationCount(
          Asset.lbtc(),
        );
        final usdtResult = confirmationService.getRequiredConfirmationCount(
          Asset.usdtLiquid(),
        );

        expect(lbtcResult, equals(liquidConfirmationBlockCount));
        expect(usdtResult, equals(liquidConfirmationBlockCount));
      });

      test('BTC and Liquid thresholds are currently the same', () {
        final btcThreshold = confirmationService.getRequiredConfirmationCount(
          Asset.btc(),
        );
        final liquidThreshold =
            confirmationService.getRequiredConfirmationCount(
          Asset.lbtc(),
        );

        expect(btcThreshold, equals(liquidThreshold));
        expect(btcThreshold, equals(1));
      });
    });

    group('isTransactionPending', () {
      test('returns true for unconfirmed transactions', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: 0,
            )).thenAnswer((_) => Stream.value(0));

        final transaction = _createMockTransaction(blockHeight: null);

        final result = await confirmationService.isTransactionPending(
          transaction: transaction,
          asset: Asset.btc(),
        );

        expect(result, isTrue);
      });

      test('returns false when confirmations meet threshold', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

        final transaction = _createMockTransaction(blockHeight: 800000);

        final result = await confirmationService.isTransactionPending(
          transaction: transaction,
          asset: Asset.btc(),
        );

        expect(result, isFalse);
      });

      test('returns false when confirmations exceed threshold', () async {
        when(() => mockAquaProvider.getConfirmationCount(
                  asset: any(named: 'asset'),
                  transactionBlockHeight: any(named: 'transactionBlockHeight'),
                ))
            .thenAnswer(
                (_) => Stream.value(onchainConfirmationBlockCount + 10));

        final transaction = _createMockTransaction(blockHeight: 800000);

        final result = await confirmationService.isTransactionPending(
          transaction: transaction,
          asset: Asset.btc(),
        );

        expect(result, isFalse);
      });

      test('uses correct threshold for Liquid', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(liquidConfirmationBlockCount));

        final transaction = _createMockTransaction(blockHeight: 1000000);

        final result = await confirmationService.isTransactionPending(
          transaction: transaction,
          asset: Asset.lbtc(),
        );

        expect(result, isFalse);
      });

      group('peg transactions', () {
        test('uses peg logic when dbTransaction is a peg', () async {
          when(() => mockAquaProvider.getConfirmationCount(
                asset: any(named: 'asset'),
                transactionBlockHeight: any(named: 'transactionBlockHeight'),
              )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

          final dbTxn = TransactionDbModel(
            txhash: 'peg_tx',
            assetId: Asset.btc().id,
            type: TransactionDbModelType.sideswapPegIn,
            serviceOrderId: 'peg_123',
          );

          final sendTxn = _createMockTransaction(blockHeight: 800000);
          final receiveTxn = _createMockTransaction(blockHeight: 1000000);
          mockPegSwapMatcher.mockLookupPegSides(
            sendTxn: sendTxn,
            receiveTxn: receiveTxn,
          );

          final transaction = _createMockTransaction(blockHeight: 800000);

          final result = await confirmationService.isTransactionPending(
            transaction: transaction,
            asset: Asset.btc(),
            dbTransaction: dbTxn,
          );

          expect(result, isFalse);
          verify(() => mockPegSwapMatcher.lookupPegSides(
                pegOrder: any(named: 'pegOrder'),
                sendNetworkTxns: any(named: 'sendNetworkTxns'),
                receiveNetworkTxns: any(named: 'receiveNetworkTxns'),
              )).called(1);
        });

        test('non-peg transactions skip peg logic', () async {
          when(() => mockAquaProvider.getConfirmationCount(
                asset: any(named: 'asset'),
                transactionBlockHeight: any(named: 'transactionBlockHeight'),
              )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

          final dbTxn = TransactionDbModel(
            txhash: 'normal_tx',
            assetId: Asset.btc().id,
            type: TransactionDbModelType.aquaSend,
          );

          final transaction = _createMockTransaction(blockHeight: 800000);

          final result = await confirmationService.isTransactionPending(
            transaction: transaction,
            asset: Asset.btc(),
            dbTransaction: dbTxn,
          );

          expect(result, isFalse);
          verifyNever(() => mockPegSwapMatcher.lookupPegSides(
                pegOrder: any(named: 'pegOrder'),
                sendNetworkTxns: any(named: 'sendNetworkTxns'),
                receiveNetworkTxns: any(named: 'receiveNetworkTxns'),
              ));
        });

        test(
            'returns false when send transaction is not found and network is empty',
            () async {
          when(() => mockAquaProvider.getConfirmationCount(
                asset: any(named: 'asset'),
                transactionBlockHeight: any(named: 'transactionBlockHeight'),
              )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

          final dbTxn = TransactionDbModel(
            txhash: 'peg_tx',
            assetId: Asset.btc().id,
            type: TransactionDbModelType.sideswapPegIn,
          );

          mockPegSwapMatcher.mockLookupPegSides(
            sendTxn: null,
            receiveTxn: null,
          );

          final transaction = _createMockTransaction(blockHeight: 800000);

          final result = await confirmationService.isTransactionPending(
            transaction: transaction,
            asset: Asset.btc(),
            dbTransaction: dbTxn,
          );

          expect(result, isFalse);
        });
      });

      test('handles null dbTransaction', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

        final transaction = _createMockTransaction(blockHeight: 800000);

        final result = await confirmationService.isTransactionPending(
          transaction: transaction,
          asset: Asset.btc(),
          dbTransaction: null,
        );

        expect(result, isFalse);
      });

      test('handles null blockHeight', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: 0,
            )).thenAnswer((_) => Stream.value(0));

        final transaction = _createMockTransaction(blockHeight: null);

        final result = await confirmationService.isTransactionPending(
          transaction: transaction,
          asset: Asset.btc(),
        );

        expect(result, isTrue); // No block height = pending
      });
    });

    group('isGhostTransactionPending', () {
      test('returns false when ghost is older than last network txn', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(0));

        final now = DateTime.now();
        final ghostTxn = TransactionDbModel(
          txhash: 'ghost_old',
          assetId: Asset.btc().id,
          isGhost: true,
          ghostTxnCreatedAt: now.subtract(const Duration(hours: 2)),
        );
        final networkTxn = _createMockTransaction(blockHeight: 700000);
        final lastNetworkTxn = GdkTransaction(
          txhash: 'last_net',
          blockHeight: 700000,
          type: GdkTransactionTypeEnum.incoming,
          satoshi: {},
          createdAtTs:
              now.subtract(const Duration(hours: 1)).microsecondsSinceEpoch,
        );

        final result = await confirmationService.isGhostTransactionPending(
          ghostTxn: ghostTxn,
          asset: Asset.btc(),
          networkTxns: [networkTxn, lastNetworkTxn],
        );

        expect(result, isFalse);
      });

      test('returns true when ghost is newer than last network txn', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(0));

        final now = DateTime.now();
        final ghostTxn = TransactionDbModel(
          txhash: 'ghost_new',
          assetId: Asset.btc().id,
          isGhost: true,
          ghostTxnCreatedAt: now,
        );
        final lastNetworkTxn = GdkTransaction(
          txhash: 'last_net',
          blockHeight: 700000,
          type: GdkTransactionTypeEnum.incoming,
          satoshi: {},
          createdAtTs:
              now.subtract(const Duration(hours: 1)).microsecondsSinceEpoch,
        );

        final result = await confirmationService.isGhostTransactionPending(
          ghostTxn: ghostTxn,
          asset: Asset.btc(),
          networkTxns: [lastNetworkTxn],
        );

        expect(result, isTrue);
      });

      test('returns true when networkTxns is empty', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: 0,
            )).thenAnswer((_) => Stream.value(0));

        final ghostTxn = TransactionDbModel(
          txhash: 'ghost',
          assetId: Asset.btc().id,
          isGhost: true,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final result = await confirmationService.isGhostTransactionPending(
          ghostTxn: ghostTxn,
          asset: Asset.btc(),
          networkTxns: [],
        );

        expect(result, isTrue);
      });

      test('returns false when ghost has null ghostTxnCreatedAt', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: any(named: 'transactionBlockHeight'),
            )).thenAnswer((_) => Stream.value(0));

        final ghostTxn = TransactionDbModel(
          txhash: 'ghost_null_date',
          assetId: Asset.btc().id,
          isGhost: true,
          ghostTxnCreatedAt: null,
        );
        final lastNetworkTxn = GdkTransaction(
          txhash: 'last_net',
          blockHeight: 700000,
          type: GdkTransactionTypeEnum.incoming,
          satoshi: {},
          createdAtTs: DateTime.now().microsecondsSinceEpoch,
        );

        final result = await confirmationService.isGhostTransactionPending(
          ghostTxn: ghostTxn,
          asset: Asset.btc(),
          networkTxns: [lastNetworkTxn],
        );

        expect(result, isFalse);
      });

      test('checks confirmations when ghost matches a network txn', () async {
        when(() => mockAquaProvider.getConfirmationCount(
              asset: any(named: 'asset'),
              transactionBlockHeight: 700000,
            )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

        final ghostTxn = TransactionDbModel(
          txhash: 'matching_tx',
          assetId: Asset.btc().id,
          isGhost: true,
          ghostTxnCreatedAt: DateTime.now(),
        );
        const matchingNetworkTxn = GdkTransaction(
          txhash: 'matching_tx',
          blockHeight: 700000,
          type: GdkTransactionTypeEnum.incoming,
          satoshi: {},
        );

        final result = await confirmationService.isGhostTransactionPending(
          ghostTxn: ghostTxn,
          asset: Asset.btc(),
          networkTxns: [matchingNetworkTxn],
        );

        expect(result, isFalse);
      });
    });
  });
}

GdkTransaction _createMockTransaction({int? blockHeight}) {
  return GdkTransaction(
    txhash: 'mock_tx',
    blockHeight: blockHeight,
    type: GdkTransactionTypeEnum.incoming,
    satoshi: {},
  );
}
