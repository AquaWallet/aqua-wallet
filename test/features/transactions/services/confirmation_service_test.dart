import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/services/confirmation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

void main() {
  late ConfirmationService confirmationService;
  late MockAquaProvider mockAquaProvider;
  late MockPegStorageProvider mockPegStorage;

  setUpAll(() {
    registerFallbackValue(Asset.btc());
  });

  setUp(() {
    mockAquaProvider = MockAquaProvider();
    mockPegStorage = MockPegStorageProvider();

    confirmationService = ConfirmationService(
      mockAquaProvider,
      mockPegStorage,
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
        test('checks peg status for peg transactions', () async {
          when(() => mockAquaProvider.getConfirmationCount(
                asset: any(named: 'asset'),
                transactionBlockHeight: any(named: 'transactionBlockHeight'),
              )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

          when(() => mockPegStorage.getOrderById('peg_123')).thenAnswer(
              (_) async => null); // Simplified: just checking delegation

          final dbTxn = TransactionDbModel(
            txhash: 'peg_tx',
            assetId: Asset.btc().id,
            type: TransactionDbModelType.sideswapPegIn,
            serviceOrderId: 'peg_123',
          );

          final transaction = _createMockTransaction(blockHeight: 800000);

          await confirmationService.isTransactionPending(
            transaction: transaction,
            asset: Asset.btc(),
            dbTransaction: dbTxn,
          );

          // Verify peg storage was consulted
          verify(() => mockPegStorage.getOrderById('peg_123')).called(1);
        });

        test('non-peg transactions skip peg status logic', () async {
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
          // Should not try to fetch peg order for non-peg transactions
          verifyNever(() => mockPegStorage.getOrderById(any()));
        });

        test('handles null serviceOrderId for peg transactions', () async {
          when(() => mockAquaProvider.getConfirmationCount(
                asset: any(named: 'asset'),
                transactionBlockHeight: any(named: 'transactionBlockHeight'),
              )).thenAnswer((_) => Stream.value(onchainConfirmationBlockCount));

          final dbTxn = TransactionDbModel(
            txhash: 'peg_tx',
            assetId: Asset.btc().id,
            type: TransactionDbModelType.sideswapPegIn,
            serviceOrderId: null, // Missing order ID
          );

          final transaction = _createMockTransaction(blockHeight: 800000);

          final result = await confirmationService.isTransactionPending(
            transaction: transaction,
            asset: Asset.btc(),
            dbTransaction: dbTxn,
          );

          expect(result, isFalse); // Falls back to confirmation check
          verifyNever(() => mockPegStorage.getOrderById(any()));
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
