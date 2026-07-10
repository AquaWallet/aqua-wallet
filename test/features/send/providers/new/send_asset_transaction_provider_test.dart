import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';
import 'send_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSendGdkTransactor mockTransactor;
  late MockFeatureFlagsProvider mockFeatureFlags;

  final btcAsset = Asset.btc();
  final btcArgs = SendAssetArguments.fromAsset(btcAsset);

  setUpAll(() {
    registerFallbackValue(btcAsset);
    registerFallbackValue(SendAssetInputState(
      asset: btcAsset,
      amount: 0,
      rate: kBtcUsdExchangeRate,
    ));
    registerFallbackValue(const GdkNewTransactionReply());
    registerFallbackValue(NetworkType.bitcoin);
    registerFallbackValue(const GdkConvertData());
    registerFallbackValue(SendAssetArguments.fromAsset(btcAsset));
  });

  setUp(() {
    mockTransactor = MockSendGdkTransactor();
    mockFeatureFlags = MockFeatureFlagsProvider();
  });

  group('BTC fee estimation transaction', () {
    test('should set state to created transaction', () async {
      const mockTxnHash = '0x123';
      const mockTxn = SendAssetOnchainTx.gdkTx(
        GdkNewTransactionReply(txhash: mockTxnHash),
      );
      final input = SendAssetInputState(
        asset: btcAsset,
        amount: 10000,
        amountFieldText: '10000',
        rate: kBtcUsdExchangeRate,
      );

      mockTransactor.mockCreateTransaction(mockTxn);

      final container = createSendContainer(
        args: btcArgs,
        input: input,
        transactor: mockTransactor,
        featureFlags: mockFeatureFlags,
      );
      final provider = sendAssetTxnProvider(btcArgs);

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
      verify(() => mockTransactor.createTransaction(sendInput: input))
          .called(1);
    });
  });

  group('BTC transaction execution', () {
    test('should execute transaction with correct parameters', () async {
      const mockTxnHash = '0x123';
      const mockTxnReply = GdkNewTransactionReply(
        fee: 1000,
        feeRate: 2,
        txhash: mockTxnHash,
        transaction: mockTxnHash,
      );
      final input = SendAssetInputState(
        asset: btcAsset,
        amount: 10000,
        amountFieldText: '10000',
        rate: kBtcUsdExchangeRate,
      );

      mockTransactor
          .mockCreateTransaction(const SendAssetOnchainTx.gdkTx(mockTxnReply));
      mockTransactor.mockSignTransaction(mockTxnReply);
      mockTransactor.mockBroadcastTransaction(mockTxnHash);
      mockFeatureFlags.mockFakeBroadcastsEnabled(false);

      final container = createSendContainer(
        args: btcArgs,
        input: input,
        transactor: mockTransactor,
        featureFlags: mockFeatureFlags,
      );
      final provider = sendAssetTxnProvider(btcArgs);

      await container.read(provider.notifier).executeGdkSendTransaction();

      final state = await container.read(provider.future);
      expect(
        state,
        isA<SendAssetTransactionComplete>()
            .having((s) => s.args.txId, 'txId', mockTxnHash)
            .having((s) => s.args.createdAt, 'createdAt', isA<int>())
            .having((s) => s.args.network, 'network', NetworkType.bitcoin),
      );
      verify(() => mockTransactor.createTransaction(sendInput: input))
          .called(1);
    });
  });

  group('Lightning submarine swap broadcast', () {
    final lightningAsset = Asset.lightning();
    final lightningArgs = SendAssetArguments.fromAsset(lightningAsset);

    late MockLbtcLnSwap mockSwap;
    late MockBoltzSubmarineSwapNotifier mockBoltzNotifier;

    const mockTxnHash = '0xln123';
    const mockSignedRawTx = '02000000abc123';
    const mockBoltzSwapId = 'boltz-swap-id';
    const mockTxnReply = GdkNewTransactionReply(
      fee: 500,
      feeRate: 1,
      txhash: mockTxnHash,
      transaction: mockSignedRawTx,
    );
    const mockTxn = SendAssetOnchainTx.gdkTx(mockTxnReply);

    setUp(() {
      mockSwap = MockLbtcLnSwap();
      mockBoltzNotifier = MockBoltzSubmarineSwapNotifier(swap: mockSwap);

      when(() => mockSwap.id).thenReturn(mockBoltzSwapId);
      when(() => mockBoltzNotifier.createTxnForSubmarineSwap(
            arguments: any(named: 'arguments'),
            isFeeEstimateTxn: any(named: 'isFeeEstimateTxn'),
          )).thenAnswer((_) async => mockTxn);

      mockTransactor.mockSignTransaction(mockTxnReply);
      mockTransactor.mockBroadcastTransaction(mockTxnHash);
      mockFeatureFlags.mockFakeBroadcastsEnabled(false);
    });

    ProviderContainer createLightningContainer({
      required SendAssetInputState input,
    }) =>
        createSendContainer(
          args: lightningArgs,
          input: input,
          transactor: mockTransactor,
          featureFlags: mockFeatureFlags,
          boltzNotifier: mockBoltzNotifier,
        );

    test('should broadcast to both Boltz and Electrum', () async {
      final input = SendAssetInputState(
        asset: lightningAsset,
        amount: 50000,
        amountFieldText: '50000',
        rate: kBtcUsdExchangeRate,
      );

      when(() => mockSwap.broadcastBoltz(signedHex: any(named: 'signedHex')))
          .thenAnswer((_) async => mockTxnHash);

      final container = createLightningContainer(input: input);
      final provider = sendAssetTxnProvider(lightningArgs);

      await container.read(provider.notifier).executeGdkSendTransaction();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => mockSwap.broadcastBoltz(signedHex: any(named: 'signedHex')),
      ).called(1);
      verify(
        () => mockTransactor.broadcastTransaction(
          rawTx: any(named: 'rawTx'),
          network: any(named: 'network'),
        ),
      ).called(1);
    });

    test('should succeed even if Boltz broadcast fails', () async {
      final input = SendAssetInputState(
        asset: lightningAsset,
        amount: 50000,
        amountFieldText: '50000',
        rate: kBtcUsdExchangeRate,
      );

      when(() => mockSwap.broadcastBoltz(signedHex: any(named: 'signedHex')))
          .thenAnswer((_) async => throw Exception('Boltz API unreachable'));

      final container = createLightningContainer(input: input);
      final provider = sendAssetTxnProvider(lightningArgs);

      await container.read(provider.notifier).executeGdkSendTransaction();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => mockTransactor.broadcastTransaction(
          rawTx: any(named: 'rawTx'),
          network: any(named: 'network'),
        ),
      ).called(1);
      verify(
        () => mockSwap.broadcastBoltz(signedHex: any(named: 'signedHex')),
      ).called(1);
    });
  });
}
