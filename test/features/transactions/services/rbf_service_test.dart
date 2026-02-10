import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/services/rbf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

void main() {
  late RbfService rbfService;
  late MockBitcoinProvider mockBitcoinProvider;
  late MockLiquidProvider mockLiquidProvider;

  setUp(() {
    mockBitcoinProvider = MockBitcoinProvider();
    mockLiquidProvider = MockLiquidProvider();

    rbfService = RbfService(
      bitcoinProvider: mockBitcoinProvider,
      liquidProvider: mockLiquidProvider,
    );
  });

  group('RbfService', () {
    group('isRbfAllowed', () {
      test('returns false when transaction not found in network', () async {
        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => []);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'nonexistent_tx',
        );

        expect(result, isFalse);
      });

      test('returns true when BTC transaction can be RBF\'d', () async {
        final mockTxn = createMockNetworkTransaction(
          txhash: 'btc_tx',
          canRbf: true,
        );

        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => [mockTxn]);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'btc_tx',
        );

        expect(result, isTrue);
        verify(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .called(1);
      });

      test('returns false when BTC transaction cannot be RBF\'d', () async {
        final mockTxn = createMockNetworkTransaction(
          txhash: 'btc_tx',
          canRbf: false,
        );

        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => [mockTxn]);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'btc_tx',
        );

        expect(result, isFalse);
      });

      test('returns true when Liquid transaction can be RBF\'d', () async {
        final mockTxn = createMockNetworkTransaction(
          txhash: 'lbtc_tx',
          canRbf: true,
        );

        when(() => mockLiquidProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => [mockTxn]);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.lbtc(),
          txHash: 'lbtc_tx',
        );

        expect(result, isTrue);
        verify(() => mockLiquidProvider.getTransactions(requiresRefresh: true))
            .called(1);
      });

      test('returns false when transaction not found in network', () async {
        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => []);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'nonexistent_tx',
        );

        expect(result, isFalse);
      });

      test('returns false when transaction has null canRbf', () async {
        final mockTxn = createMockNetworkTransaction(
          txhash: 'btc_tx',
          canRbf: null,
        );

        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => [mockTxn]);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'btc_tx',
        );

        expect(result, isFalse);
      });

      test('uses correct provider for BTC asset', () async {
        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => []);

        await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'btc_tx',
        );

        verify(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .called(1);
        verifyNever(() => mockLiquidProvider.getTransactions(
            requiresRefresh: any(named: 'requiresRefresh')));
      });

      test('uses correct provider for Liquid assets', () async {
        when(() => mockLiquidProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => []);

        await rbfService.isRbfAllowed(
          asset: Asset.lbtc(),
          txHash: 'lbtc_tx',
        );

        verify(() => mockLiquidProvider.getTransactions(requiresRefresh: true))
            .called(1);
        verifyNever(() => mockBitcoinProvider.getTransactions(
            requiresRefresh: any(named: 'requiresRefresh')));
      });

      test('uses correct provider for USDt (Liquid)', () async {
        when(() => mockLiquidProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => []);

        await rbfService.isRbfAllowed(
          asset: Asset.usdtLiquid(),
          txHash: 'usdt_tx',
        );

        verify(() => mockLiquidProvider.getTransactions(requiresRefresh: true))
            .called(1);
        verifyNever(() => mockBitcoinProvider.getTransactions(
            requiresRefresh: any(named: 'requiresRefresh')));
      });

      test('handles getTransactions returning null', () async {
        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => null);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'btc_tx',
        );

        expect(result, isFalse);
      });

      test('finds transaction among multiple transactions', () async {
        final mockTxns = [
          createMockNetworkTransaction(txhash: 'tx1', canRbf: false),
          createMockNetworkTransaction(txhash: 'tx2', canRbf: true),
          createMockNetworkTransaction(txhash: 'tx3', canRbf: false),
        ];

        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => mockTxns);

        final result = await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'tx2',
        );

        expect(result, isTrue);
      });

      test('requiresRefresh is always true', () async {
        when(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .thenAnswer((_) async => []);

        await rbfService.isRbfAllowed(
          asset: Asset.btc(),
          txHash: 'tx',
        );

        // Verify that requiresRefresh = true was passed
        verify(() => mockBitcoinProvider.getTransactions(requiresRefresh: true))
            .called(1);
      });
    });
  });
}

GdkTransaction createMockNetworkTransaction({
  String? txhash,
  bool? canRbf,
}) {
  return GdkTransaction(
    txhash: txhash ?? 'mock_tx',
    canRbf: canRbf,
    type: GdkTransactionTypeEnum.incoming,
    satoshi: {},
  );
}
