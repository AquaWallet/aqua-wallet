import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final asset = Asset.btc();
  final args = SendAssetArguments.fromAsset(asset);
  final inputState = SendAssetInputState(
    asset: asset,
    amount: 10000,
    amountFieldText: '10000',
  );
  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(inputState);
    registerFallbackValue(const GdkNewTransactionReply());
    registerFallbackValue(NetworkType.bitcoin);
  });

  group('BTC fee estimation transaction', () {
    test('should set state to created transaction', () async {
      const mockTxnHash = '0x123';
      const mockTxn = SendAssetOnchainTx.gdkTx(
        GdkNewTransactionReply(txhash: mockTxnHash),
      );
      final input = SendAssetInputState(
        asset: asset,
        amount: 10000,
        amountFieldText: '10000',
      );
      final provider = sendAssetTxnProvider(args);
      final mockSendGdkTransactor = MockSendGdkTransactor();
      final container = ProviderContainer(overrides: [
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: input),
        ),
        sendTransactionExecutorProvider(args).overrideWith(
          (_) => mockSendGdkTransactor,
        ),
      ]);
      mockSendGdkTransactor.mockCreateTransaction(mockTxn);

      await container.read(provider.notifier).createFeeEstimateTransaction();

      final state = await container.read(provider.future);
      expect(
        state,
        isA<SendAssetTransactionCreated>().having(
          (s) => s.tx,
          'transaction',
          isA<GdkTx>().having(
            (tx) => tx.gdkTx.txhash,
            'txhash',
            mockTxnHash,
          ),
        ),
      );
      verify(
        () => mockSendGdkTransactor.createTransaction(
          sendInput: input,
        ),
      ).called(1);
    });
  });

  group('BTC transaction execution', () {
    test('should execute transaction with correct parameters', () async {
      const mockTxnHash = '0x123';
      const mockFee = 1000;
      const mockFeeRate = 2;
      const mockAmount = 10000;
      const mockTxnReply = GdkNewTransactionReply(
        fee: mockFee,
        feeRate: mockFeeRate,
        txhash: mockTxnHash,
        transaction: mockTxnHash,
      );
      const mockTxn = SendAssetOnchainTx.gdkTx(mockTxnReply);
      final input = SendAssetInputState(
        asset: asset,
        amount: mockAmount,
        amountFieldText: mockAmount.toString(),
      );
      final mockFeatureFlagsProvider = MockFeatureFlagsProvider();
      final mockTransactionStorageProvider = MockTransactionStorageProvider();

      final provider = sendAssetTxnProvider(args);
      final mockSendGdkTransactor = MockSendGdkTransactor();
      final container = ProviderContainer(overrides: [
        sendAssetInputStateProvider.overrideWith(
          () => MockSendAssetInputStateNotifier(input: input),
        ),
        sendTransactionExecutorProvider(args).overrideWith(
          (_) => mockSendGdkTransactor,
        ),
        featureFlagsProvider.overrideWith((_) => mockFeatureFlagsProvider),
        transactionStorageProvider
            .overrideWith(() => mockTransactionStorageProvider),
      ]);
      mockSendGdkTransactor.mockCreateTransaction(mockTxn);
      mockSendGdkTransactor.mockSignTransaction(mockTxnReply);
      mockSendGdkTransactor.mockBroadcastTransaction(mockTxnHash);
      mockFeatureFlagsProvider.mockFakeBroadcastsEnabled(false);

      await container.read(provider.notifier).executeGdkSendTransaction();

      final state = await container.read(provider.future);
      expect(
        state,
        isA<SendAssetTransactionComplete>()
            .having((s) => s.args.txId, 'txId', mockTxnHash)
            .having((s) => s.args.createdAt, 'createdAt', isA<int>())
            .having((s) => s.args.network, 'network', NetworkType.bitcoin),
      );
      verify(
        () => mockSendGdkTransactor.createTransaction(
          sendInput: input,
        ),
      ).called(1);
    });
  });
}
