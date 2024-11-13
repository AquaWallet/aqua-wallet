import 'package:aqua/features/wallet/providers/wallet_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua/data/models/gdk_models.dart';

void main() {
  group('WalletUtils', () {
    test('filterRecentlySpentUtxos should filter out recently spent UTXOs', () {
      final utxos = {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash1', ptIdx: 0),
          const GdkUnspentOutputs(txhash: 'hash2', ptIdx: 1),
          const GdkUnspentOutputs(txhash: 'hash3', ptIdx: 0),
        ],
        'asset2': [
          const GdkUnspentOutputs(txhash: 'hash4', ptIdx: 0),
          const GdkUnspentOutputs(txhash: 'hash5', ptIdx: 1),
        ],
      };

      final spentUtxos = {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash1', ptIdx: 0),
          const GdkUnspentOutputs(txhash: 'hash3', ptIdx: 0),
        ],
        'asset2': [
          const GdkUnspentOutputs(txhash: 'hash5', ptIdx: 1),
        ],
      };

      final result = WalletUtils.filterRecentlySpentUtxos(utxos, spentUtxos);

      expect(result, {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash2', ptIdx: 1),
        ],
        'asset2': [
          const GdkUnspentOutputs(txhash: 'hash4', ptIdx: 0),
        ],
      });
    });

    test('should return all UTXOs when no spent UTXOs are provided', () {
      final utxos = {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash1', ptIdx: 0),
          const GdkUnspentOutputs(txhash: 'hash2', ptIdx: 1),
        ],
        'asset2': [
          const GdkUnspentOutputs(txhash: 'hash3', ptIdx: 0),
        ],
      };

      final spentUtxos = <String, List<GdkUnspentOutputs>>{};

      final result = WalletUtils.filterRecentlySpentUtxos(utxos, spentUtxos);

      expect(result, utxos);
    });

    test('should handle case when all UTXOs of an asset are spent', () {
      final utxos = {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash1', ptIdx: 0),
          const GdkUnspentOutputs(txhash: 'hash2', ptIdx: 1),
        ],
        'asset2': [
          const GdkUnspentOutputs(txhash: 'hash3', ptIdx: 0),
        ],
      };

      final spentUtxos = {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash1', ptIdx: 0),
          const GdkUnspentOutputs(txhash: 'hash2', ptIdx: 1),
        ],
      };

      final result = WalletUtils.filterRecentlySpentUtxos(utxos, spentUtxos);

      expect(result, {
        'asset2': [
          const GdkUnspentOutputs(txhash: 'hash3', ptIdx: 0),
        ],
      });
    });

    test(
        'should handle case when there are spent UTXOs for assets not in the original UTXO list',
        () {
      final utxos = {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash1', ptIdx: 0),
          const GdkUnspentOutputs(txhash: 'hash2', ptIdx: 1),
        ],
      };

      final spentUtxos = {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash1', ptIdx: 0),
        ],
        'asset2': [
          const GdkUnspentOutputs(txhash: 'hash3', ptIdx: 0),
        ],
      };

      final result = WalletUtils.filterRecentlySpentUtxos(utxos, spentUtxos);

      expect(result, {
        'asset1': [
          const GdkUnspentOutputs(txhash: 'hash2', ptIdx: 1),
        ],
      });
    });
  });
}
