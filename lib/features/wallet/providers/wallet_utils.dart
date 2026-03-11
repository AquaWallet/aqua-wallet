import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/utils/regex.dart';

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

  /// Converts a receive-only descriptor to include both receive and change paths.
  ///
  /// Transforms the child derivation path after the xpub:
  /// - `/0/*` → `/<0;1>/*`
  /// - Strips the checksum (e.g., `#0dsvq5mw`) since it becomes invalid after modification.
  ///
  /// Note: Does not modify the key origin path inside brackets, as LWK doesn't
  /// support multi-path syntax there.
  ///
  /// Example:
  /// Input:  `ct(slip77(...),elsh(wpkh([8f681564/49'/1776'/0']xpub.../0/*)))#checksum`
  /// Output: `ct(slip77(...),elsh(wpkh([8f681564/49'/1776'/0']xpub.../<0;1>/*)))`
  static String addChangePathToDescriptor(String descriptor) {
    // Strip the checksum (everything after #) since it becomes invalid after modification
    final withoutChecksum =
        descriptor.replaceAll(AquaRegex.descriptorChecksum, '');
    // Only modify the child derivation path after xpub, not the key origin path
    return withoutChecksum.replaceAll(
        AquaRegex.receiveOnlyDerivationPath, "/<0;1>/*");
  }
}
