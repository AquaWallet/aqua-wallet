import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

/// Maintains a local cache of recently spent UTXOs.
/// THIS IS NOT A COMPLETE LIST OF SPENT UTXOS, just recently spent ones.
///
/// Necessary for lowball to prevent double-spending. Lowball txs don't go into the mempool, so GDK
/// doesn't see them until confirmed. This is an issue when a user sends a second tx quickly after the first,
/// since GDK will likely try to double-spend the utxos from the first tx.
///
/// State is stored as a map where the key is the asset ID  and the value is a
/// list of GdkUnspentOutputs for that asset.
class RecentlySpentUtxosNotifier
    extends StateNotifier<Map<String, List<GdkUnspentOutputs>>?> {
  RecentlySpentUtxosNotifier() : super(null);

  void updateRecentlySpentUtxos(Map<String, List<GdkUnspentOutputs>>? utxos) {
    state = utxos;
  }

  void clearRecentlySpentUtxos() {
    state = null;
  }

  void addUtxos(Map<String, List<GdkUnspentOutputs>> newUtxos) {
    if (state == null) {
      state = newUtxos;
    } else {
      final updatedState = Map<String, List<GdkUnspentOutputs>>.from(state!);
      newUtxos.forEach((key, value) {
        if (updatedState.containsKey(key)) {
          updatedState[key]!.addAll(value);
        } else {
          updatedState[key] = value;
        }
      });
      state = updatedState;
    }

    logger.d(
        '[UsedUtxosNotifier] Updated recently spent utxos: ${state?['6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d']?.length}');
  }

  List<GdkUnspentOutputs>? getRecentlySpentUtxosForAsset(String assetId) {
    return state?[assetId];
  }
}

final recentlySpentUtxosProvider = StateNotifierProvider<
    RecentlySpentUtxosNotifier, Map<String, List<GdkUnspentOutputs>>?>((ref) {
  return RecentlySpentUtxosNotifier();
});

final recentlySpentUtxosForAssetProvider =
    Provider.family<List<GdkUnspentOutputs>?, String>((ref, assetId) {
  return ref
      .read(recentlySpentUtxosProvider.notifier)
      .getRecentlySpentUtxosForAsset(assetId);
});
