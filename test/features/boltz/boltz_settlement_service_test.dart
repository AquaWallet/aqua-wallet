import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/transactions/providers/transactions_storage_provider.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers.dart';
import '../../mocks/mocks.dart';

void main() {
  const swapId = 'swap-id';
  const refundTxId = 'refund-tx-id';
  const receiveAddress = 'lq1refundaddress';
  const liquidFeeRate = 0.1;

  setUpAll(() {
    registerFallbackValue(TxFee.absolute(BigInt.zero));
  });

  late MockLbtcLnSwap swap;
  late MockLiquidProvider liquid;
  late MockElectrsClient electrs;
  late MockFeeEstimateClient feeEstimate;
  late MockBoltzStorageProvider boltzStorage;
  late MockTransactionStorageProvider transactionStorage;

  BoltzSwapSettlementService buildService() {
    final container = createContainer(overrides: [
      liquidProvider.overrideWith((_) => liquid),
      electrsProvider.overrideWith((_) => electrs),
      feeEstimateProvider.overrideWith((_) => feeEstimate),
      boltzStorageProvider.overrideWith(() => boltzStorage),
      transactionStorageProvider.overrideWith(() => transactionStorage),
    ]);
    final subscription =
        container.listen(boltzSwapSettlementServiceProvider, (_, __) {});
    addTearDown(subscription.close);
    return subscription.read();
  }

  void failCoopRefund() {
    when(() => swap.refund(
          outAddress: any(named: 'outAddress'),
          minerFee: any(named: 'minerFee'),
          tryCooperate: true,
        )).thenThrow(Exception('boltz is uncooperative'));
  }

  setUp(() {
    swap = MockLbtcLnSwap();
    liquid = MockLiquidProvider();
    electrs = MockElectrsClient();
    feeEstimate = MockFeeEstimateClient();
    boltzStorage = MockBoltzStorageProvider(swaps: []);
    transactionStorage = MockTransactionStorageProvider(transactions: []);

    when(() => swap.id).thenReturn(swapId);
    when(() => swap.refund(
          outAddress: any(named: 'outAddress'),
          minerFee: any(named: 'minerFee'),
          tryCooperate: any(named: 'tryCooperate'),
        )).thenAnswer((_) async => 'signed-refund-hex');

    liquid.mockGetReceiveAddress(address: receiveAddress);
    electrs.mockBroadcast(txId: refundTxId);
    feeEstimate.mockGetLiquidFeeRate(liquidFeeRate);

    when(() => boltzStorage.updateRefundTxId(
          boltzId: any(named: 'boltzId'),
          txId: any(named: 'txId'),
        )).thenAnswer((_) async {});
    when(() => transactionStorage.saveBoltzRefundTxn(
          boltzSwap: swap,
          txId: any(named: 'txId'),
        )).thenAnswer((_) async {});
  });

  group('BoltzSwapSettlementService.refund', () {
    test('sizes the fee by rate instead of a fixed absolute amount', () async {
      final service = buildService();

      await service.refund(swap);

      final minerFee = verify(() => swap.refund(
            outAddress: receiveAddress,
            minerFee: captureAny(named: 'minerFee'),
            tryCooperate: true,
          )).captured.single;
      expect(minerFee, const TxFee.relative(liquidFeeRate));
    });

    test(
        'non-coop retry uses the same fee rate so boltz-rust can size the '
        'larger script path tx', () async {
      failCoopRefund();
      final service = buildService();

      await expectLater(service.refund(swap), completion(refundTxId));

      final minerFee = verify(() => swap.refund(
            outAddress: receiveAddress,
            minerFee: captureAny(named: 'minerFee'),
            tryCooperate: false,
          )).captured.single;
      expect(minerFee, const TxFee.relative(liquidFeeRate));
    });

    test('a storage failure after broadcast does not broadcast a second refund',
        () async {
      when(() => boltzStorage.updateRefundTxId(
            boltzId: any(named: 'boltzId'),
            txId: any(named: 'txId'),
          )).thenThrow(Exception('isar write failed'));
      final service = buildService();

      await expectLater(service.refund(swap), completion(refundTxId));

      verify(() => electrs.broadcast(any(), NetworkType.liquid)).called(1);
      verifyNever(() => swap.refund(
            outAddress: any(named: 'outAddress'),
            minerFee: any(named: 'minerFee'),
            tryCooperate: false,
          ));
    });
  });
}
