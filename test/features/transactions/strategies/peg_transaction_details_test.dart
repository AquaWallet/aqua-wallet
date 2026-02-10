import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'transaction_details_test_helper.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Asset.btc());
    registerFallbackValue(Asset.lbtc());
    registerFallbackValue(PegOrderDbModel(
      orderId: '',
      isPegIn: true,
      amount: 0,
      statusJson: '{}',
      createdAt: DateTime.now(),
    ));
  });

  group('PegTransactionUiModelCreator - List Item Methods', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;
    late PegTransactionUiModelCreator strategy;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
      container = setup.createContainer();
      strategy = container.read(pegTransactionUiModelsProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('getCryptoAmountForPending', () {
      // Bug test: Peg-in on BTC page should show NEGATIVE amount (outgoing)
      // QA Report Screen 3: Shows "+0.00020042" but should show "-0.00020195"
      // Updated requirement: Never show '+', only '-' for negative amounts
      test('peg-in sending side should return NEGATIVE amount (no + sign)',
          () async {
        const inputAmount = 20042; // ghostTxnAmount
        const txFee = 153;
        const totalSent = inputAmount + txFee; // 20195

        final dbTxn = createMockDbTransaction(
          txhash: 'btc_peg_tx',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.sideswapPegIn,
          isGhost: true,
          ghostTxnAmount: inputAmount,
          ghostTxnCreatedAt: DateTime.now(),
          serviceOrderId: 'peg_order_123',
        );

        final networkTxn = createMockNetworkTransaction(
          txhash: 'btc_peg_tx',
          type: GdkTransactionTypeEnum.outgoing,
          blockHeight: 800000,
          satoshi: {Asset.btc().id: -totalSent},
          fee: txFee,
        );

        final args = TransactionStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc(), Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final cryptoAmount = strategy.getCryptoAmountForPending(args);

        expect(cryptoAmount, isNotNull);
        // Should show negative amount (with '-' prefix)
        expect(
          cryptoAmount!.startsWith('-'),
          isTrue,
          reason:
              'Peg-in on BTC page (sending side) should show negative amount. '
              'Got: $cryptoAmount',
        );
        // Should NEVER show '+' sign
        expect(
          cryptoAmount.contains('+'),
          isFalse,
          reason: 'Should never show + sign. Got: $cryptoAmount',
        );
      });

      // Bug test: Should use network tx amount (includes fee) not ghostTxnAmount
      test('should use network tx amount when available (includes fee)',
          () async {
        const inputAmount = 20042;
        const txFee = 153;
        const totalSent = inputAmount + txFee;

        int? capturedAmount;
        when(() => setup.mockFormatService.signedFormatAssetAmount(
              amount: any(named: 'amount'),
              asset: any(named: 'asset'),
              removeTrailingZeros: any(named: 'removeTrailingZeros'),
              decimalPlacesOverride: any(named: 'decimalPlacesOverride'),
            )).thenAnswer((invocation) {
          capturedAmount = invocation.namedArguments[#amount] as int;
          // Updated: no '+' sign for positive, only '-' for negative
          final sign = capturedAmount! < 0 ? '-' : '';
          return '$sign${(capturedAmount!.abs() / 100000000).toStringAsFixed(8)}';
        });

        final dbTxn = createMockDbTransaction(
          txhash: 'btc_peg_tx_2',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.sideswapPegIn,
          isGhost: true,
          ghostTxnAmount: inputAmount,
          ghostTxnCreatedAt: DateTime.now(),
          serviceOrderId: 'peg_order_456',
        );

        final networkTxn = createMockNetworkTransaction(
          txhash: 'btc_peg_tx_2',
          type: GdkTransactionTypeEnum.outgoing,
          blockHeight: 800000,
          satoshi: {Asset.btc().id: -totalSent},
          fee: txFee,
        );

        final args = TransactionStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc(), Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        strategy.getCryptoAmountForPending(args);

        expect(
          capturedAmount?.abs(),
          equals(totalSent),
          reason: 'Should use total sent amount ($totalSent) including tx fee, '
              'not just input amount ($inputAmount). Got: ${capturedAmount?.abs()}',
        );
      });

      // Bug test: Peg-out on LBTC page should show NEGATIVE amount
      test('peg-out sending side should return NEGATIVE amount (no + sign)',
          () async {
        const inputAmount = 50000;
        const txFee = 252;
        const totalSent = inputAmount + txFee;

        final dbTxn = createMockDbTransaction(
          txhash: 'lbtc_peg_tx',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.sideswapPegOut,
          isGhost: true,
          ghostTxnAmount: inputAmount,
          ghostTxnCreatedAt: DateTime.now(),
          serviceOrderId: 'peg_out_order_789',
        );

        final networkTxn = createMockNetworkTransaction(
          txhash: 'lbtc_peg_tx',
          type: GdkTransactionTypeEnum.outgoing,
          blockHeight: 100000,
          satoshi: {Asset.lbtc().id: -totalSent},
          fee: txFee,
        );

        final args = TransactionStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.btc(), Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final cryptoAmount = strategy.getCryptoAmountForPending(args);

        expect(cryptoAmount, isNotNull);
        // Should show negative amount (with '-' prefix)
        expect(
          cryptoAmount!.startsWith('-'),
          isTrue,
          reason:
              'Peg-out on LBTC page (sending side) should show negative amount. '
              'Got: $cryptoAmount',
        );
        // Should NEVER show '+' sign
        expect(
          cryptoAmount.contains('+'),
          isFalse,
          reason: 'Should never show + sign. Got: $cryptoAmount',
        );
      });
    });
  });

  group('PegTransactionUiModelCreator - Details Methods', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;
    late PegTransactionUiModelCreator strategy;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
      container = setup.createContainer();

      strategy = container.read(pegTransactionUiModelsProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('createPendingDetails', () {
      test('creates pending peg-in details (BTC -> LBTC)', () async {
        final dbTxn = createMockDbTransaction(
          txhash: 'pending_peg_in',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.sideswapPegIn,
          isGhost: true,
          ghostTxnAmount: -100000000,
          ghostTxnCreatedAt: DateTime.now(),
          serviceOrderId: 'peg_order_123',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be peg'),
          receive: (_) => fail('Should be peg'),
          swap: (_) => fail('Should be peg'),
          peg: (details) {
            expect(details.transactionId, 'pending_peg_in');
            expect(details.isPending, true);
            expect(details.deliverAsset.id, Asset.btc().id);
            expect(details.receiveAsset.id, Asset.lbtc().id);
            expect(details.orderId, 'peg_order_123');
          },
          redeposit: (_) => fail('Should be peg'),
        );
      });

      test('returns null when not a peg transaction', () async {
        final dbTxn = createMockDbTransaction(
          type: TransactionDbModelType.aquaSend,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNull);
      });

      // Bug test: Pending peg should show approximate receive amount with "~" prefix
      // QA Report Screen 4 & 6: We can't know exact value, so show approximate with "~"
      test(
          'pending peg-in should show approximate receive amount with ~ prefix',
          () async {
        const sendAmount = 20195;

        final sendTxn = createMockNetworkTransaction(
          txhash: 'btc_send_hash',
          satoshi: {Asset.btc().id: -sendAmount},
          fee: 153,
          blockHeight: 800000,
        );

        // No receive transaction yet - still pending on Sideswap
        setup.mockPegSwapMatcher.mockLookupPegSides(
          sendTxn: sendTxn,
          receiveTxn: null, // No receive tx yet
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'btc_send_hash',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.sideswapPegIn,
          isGhost: true,
          ghostTxnAmount: 20042,
          ghostTxnCreatedAt: DateTime.now(),
          serviceOrderId: 'peg_order_pending',
          receiveAddress: 'lq1_receive_addr',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc(), Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: sendTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be peg'),
          receive: (_) => fail('Should be peg'),
          swap: (_) => fail('Should be peg'),
          peg: (details) {
            // Receive amount should have "~" prefix to indicate approximate
            expect(
              details.receiveAmount.startsWith('~'),
              isTrue,
              reason:
                  'Pending peg should show approximate receive amount with ~ prefix. '
                  'Got: ${details.receiveAmount}',
            );
          },
          redeposit: (_) => fail('Should be peg'),
        );
      });

      // Bug test: Pending peg should show approximate fees with "~" prefix
      test(
          'pending peg-in should show approximate fees with ~ prefix when receive tx does not exist',
          () async {
        const sendAmount = 20195;

        final sendTxn = createMockNetworkTransaction(
          txhash: 'btc_send_hash_2',
          satoshi: {Asset.btc().id: -sendAmount},
          fee: 153,
          blockHeight: 800000,
        );

        setup.mockPegSwapMatcher.mockLookupPegSides(
          sendTxn: sendTxn,
          receiveTxn: null,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'btc_send_hash_2',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.sideswapPegIn,
          isGhost: true,
          ghostTxnAmount: 20042,
          ghostTxnCreatedAt: DateTime.now(),
          serviceOrderId: 'peg_order_pending_2',
          receiveAddress: 'lq1_receive_addr_2',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [Asset.btc(), Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: sendTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be peg'),
          receive: (_) => fail('Should be peg'),
          swap: (_) => fail('Should be peg'),
          peg: (details) {
            // Fees should have "~" prefix to indicate approximate
            expect(
              details.feeAmount.startsWith('~'),
              isTrue,
              reason: 'Pending peg should show approximate fees with ~ prefix. '
                  'Got: ${details.feeAmount}',
            );
          },
          redeposit: (_) => fail('Should be peg'),
        );
      });

      // Bug test: Peg-out pending should show approximate BTC receive with "~" prefix
      test(
          'pending peg-out should show approximate BTC receive amount with ~ prefix',
          () async {
        const sendAmount = 50252;

        final sendTxn = createMockNetworkTransaction(
          txhash: 'lbtc_send_hash',
          satoshi: {Asset.lbtc().id: -sendAmount},
          fee: 252,
          blockHeight: 100000,
        );

        setup.mockPegSwapMatcher.mockLookupPegSides(
          sendTxn: sendTxn,
          receiveTxn: null,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'lbtc_send_hash',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.sideswapPegOut,
          isGhost: true,
          ghostTxnAmount: 50000,
          ghostTxnCreatedAt: DateTime.now(),
          serviceOrderId: 'peg_out_pending',
          receiveAddress: 'bc1q_receive_addr',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.btc(), Asset.lbtc()],
          dbTransaction: dbTxn,
          networkTransaction: sendTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be peg'),
          receive: (_) => fail('Should be peg'),
          swap: (_) => fail('Should be peg'),
          peg: (details) {
            // Receive amount should have "~" prefix to indicate approximate
            expect(
              details.receiveAmount.startsWith('~'),
              isTrue,
              reason:
                  'Pending peg-out should show approximate BTC receive with ~ prefix. '
                  'Got: ${details.receiveAmount}',
            );
          },
          redeposit: (_) => fail('Should be peg'),
        );
      });
    });

    group('createConfirmedDetails', () {
      test('creates confirmed peg-in details with confirmation count',
          () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_peg_in',
          blockHeight: 100,
          satoshi: {Asset.btc().id: -100000000},
          fee: 2000,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'confirmed_peg_in',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.sideswapPegIn,
          feeAssetId: Asset.btc().id,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be peg'),
          receive: (_) => fail('Should be peg'),
          swap: (_) => fail('Should be peg'),
          peg: (details) {
            expect(details.transactionId, 'confirmed_peg_in');
            expect(details.confirmationCount, 2);
            expect(details.deliverAsset.id, Asset.btc().id);
            expect(details.receiveAsset.id, Asset.lbtc().id);
            verify(() => setup.mockConfirmationService
                .getConfirmationCount(any(), 100)).called(1);
          },
          redeposit: (_) => fail('Should be peg'),
        );
      });

      test('calculates total fee correctly: totalFee = sendTxFee + providerFee',
          () async {
        const sendAmount = 100000; // 0.001 BTC sent
        const sendTxFee = 500; // tx fee
        const receiveAmount = 98000; // received after provider fee
        // providerFee = (sendAmount - sendTxFee) - receiveAmount
        //             = 99500 - 98000 = 1500
        // totalFee = sendAmount - receiveAmount = 100000 - 98000 = 2000
        // Also: totalFee = sendTxFee + providerFee = 500 + 1500 = 2000

        final sendTxn = createMockNetworkTransaction(
          txhash: 'send_btc',
          satoshi: {Asset.btc().id: -sendAmount},
          fee: sendTxFee,
        );

        final receiveTxn = createMockNetworkTransaction(
          txhash: 'receive_lbtc',
          satoshi: {Asset.lbtc().id: receiveAmount},
          outputs: [const GdkTransactionInOut(address: 'lbtc_receive_addr')],
        );

        setup.mockPegSwapMatcher.mockLookupPegSides(
          sendTxn: sendTxn,
          receiveTxn: receiveTxn,
        );

        final dbTxn = createMockDbTransaction(
          txhash: 'send_btc',
          assetId: Asset.btc().id,
          type: TransactionDbModelType.sideswapPegIn,
          receiveAddress: 'lbtc_receive_addr',
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [],
          dbTransaction: dbTxn,
          networkTransaction: sendTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be peg'),
          receive: (_) => fail('Should be peg'),
          swap: (_) => fail('Should be peg'),
          peg: (details) {
            // Expected fee = grossSendAmount - receiveAmountSats = 100000 - 98000 = 2000
            expect(details.feeAmount, '0.00002');
          },
          redeposit: (_) => fail('Should be peg'),
        );
      });

      test('returns null when not a peg transaction', () async {
        final networkTxn = createMockNetworkTransaction();
        final dbTxn = createMockDbTransaction(
          type: TransactionDbModelType.aquaSend,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.btc(),
          availableAssets: [],
          dbTransaction: dbTxn,
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNull);
      });
    });
  });
}
