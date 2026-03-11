import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/transactions/providers/strategies/peg_transaction_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getPegExplorerInfo', () {
    final btc = Asset.btc();
    final lbtc = Asset.lbtc();

    GdkTransaction createTxn(String txhash) => GdkTransaction(txhash: txhash);

    group('Peg-in (BTC → LBTC)', () {
      final deliverAsset = btc;
      final receiveAsset = lbtc;

      group('completed - both txns exist', () {
        test('viewing from BTC returns sendTxn with BTC explorer', () {
          final sendTxn = createTxn('btc_send_hash');
          final receiveTxn = createTxn('lbtc_receive_hash');

          final result = getPegExplorerInfo(
            viewingAsset: btc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: receiveTxn,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'btc_send_hash');
          expect(result.explorerAsset.id, btc.id);
        });

        test('viewing from LBTC returns receiveTxn with LBTC explorer', () {
          final sendTxn = createTxn('btc_send_hash');
          final receiveTxn = createTxn('lbtc_receive_hash');

          final result = getPegExplorerInfo(
            viewingAsset: lbtc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: receiveTxn,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'lbtc_receive_hash');
          expect(result.explorerAsset.id, lbtc.id);
        });
      });

      group('pending - only sendTxn exists', () {
        test('viewing from BTC returns sendTxn with BTC explorer', () {
          final sendTxn = createTxn('btc_send_hash');

          final result = getPegExplorerInfo(
            viewingAsset: btc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: null,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'btc_send_hash');
          expect(result.explorerAsset.id, btc.id);
        });

        test('viewing from LBTC falls back to sendTxn with BTC explorer', () {
          final sendTxn = createTxn('btc_send_hash');

          final result = getPegExplorerInfo(
            viewingAsset: lbtc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: null,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'btc_send_hash');
          expect(result.explorerAsset.id, btc.id);
        });
      });
    });

    group('Peg-out (LBTC → BTC)', () {
      final deliverAsset = lbtc;
      final receiveAsset = btc;

      group('completed - both txns exist', () {
        test('viewing from LBTC returns sendTxn with LBTC explorer', () {
          final sendTxn = createTxn('lbtc_send_hash');
          final receiveTxn = createTxn('btc_receive_hash');

          final result = getPegExplorerInfo(
            viewingAsset: lbtc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: receiveTxn,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'lbtc_send_hash');
          expect(result.explorerAsset.id, lbtc.id);
        });

        test('viewing from BTC returns receiveTxn with BTC explorer', () {
          final sendTxn = createTxn('lbtc_send_hash');
          final receiveTxn = createTxn('btc_receive_hash');

          final result = getPegExplorerInfo(
            viewingAsset: btc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: receiveTxn,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'btc_receive_hash');
          expect(result.explorerAsset.id, btc.id);
        });
      });

      group('pending - only sendTxn exists', () {
        test('viewing from LBTC returns sendTxn with LBTC explorer', () {
          final sendTxn = createTxn('lbtc_send_hash');

          final result = getPegExplorerInfo(
            viewingAsset: lbtc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: null,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'lbtc_send_hash');
          expect(result.explorerAsset.id, lbtc.id);
        });

        test('viewing from BTC falls back to sendTxn with LBTC explorer', () {
          final sendTxn = createTxn('lbtc_send_hash');

          final result = getPegExplorerInfo(
            viewingAsset: btc,
            deliverAsset: deliverAsset,
            receiveAsset: receiveAsset,
            sendTxn: sendTxn,
            receiveTxn: null,
            fallbackTxHash: 'fallback',
          );

          expect(result.transactionId, 'lbtc_send_hash');
          expect(result.explorerAsset.id, lbtc.id);
        });
      });
    });

    group('edge cases', () {
      test('only receiveTxn exists - returns receiveTxn with receiveAsset', () {
        final receiveTxn = createTxn('receive_hash');

        final result = getPegExplorerInfo(
          viewingAsset: Asset.btc(),
          deliverAsset: Asset.btc(),
          receiveAsset: Asset.lbtc(),
          sendTxn: null,
          receiveTxn: receiveTxn,
          fallbackTxHash: 'fallback',
        );

        expect(result.transactionId, 'receive_hash');
        expect(result.explorerAsset.id, Asset.lbtc().id);
      });

      test('no txns exist - returns fallback with deliverAsset', () {
        final result = getPegExplorerInfo(
          viewingAsset: Asset.lbtc(),
          deliverAsset: Asset.btc(),
          receiveAsset: Asset.lbtc(),
          sendTxn: null,
          receiveTxn: null,
          fallbackTxHash: 'fallback_hash',
        );

        expect(result.transactionId, 'fallback_hash');
        expect(result.explorerAsset.id, Asset.btc().id);
      });

      test('txn with null txhash is treated as missing', () {
        const sendTxn = GdkTransaction(txhash: null);
        final receiveTxn = createTxn('receive_hash');

        final result = getPegExplorerInfo(
          viewingAsset: Asset.btc(),
          deliverAsset: Asset.btc(),
          receiveAsset: Asset.lbtc(),
          sendTxn: sendTxn,
          receiveTxn: receiveTxn,
          fallbackTxHash: 'fallback',
        );

        expect(result.transactionId, 'receive_hash');
        expect(result.explorerAsset.id, Asset.lbtc().id);
      });
    });
  });
}
