import 'package:aqua/data/models/gdk_models.dart';

class WalletUtils {
  static Map<String, List<GdkUnspentOutputs>> filterRecentlySpentUtxos(
      Map<String, List<GdkUnspentOutputs>> utxos,
      Map<String, List<GdkUnspentOutputs>> spentUtxos) {
    final filteredUtxos = <String, List<GdkUnspentOutputs>>{};
    utxos.forEach((assetId, utxoList) {
      final spentUtxosForAsset = spentUtxos[assetId];
      if (spentUtxosForAsset == null) {
        filteredUtxos[assetId] = utxoList;
        return;
      }

      final filteredUtxoList = utxoList.where((utxo) {
        final isSpent = spentUtxosForAsset.any((spentUtxo) =>
            spentUtxo.txhash == utxo.txhash && spentUtxo.ptIdx == utxo.ptIdx);
        return !isSpent;
      }).toList();

      if (filteredUtxoList.isNotEmpty) {
        filteredUtxos[assetId] = filteredUtxoList;
      }
    });

    return filteredUtxos;
  }
}
