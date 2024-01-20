import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

final blockExplorerProvider =
    Provider.autoDispose<BlockExplorerProvider>((ref) {
  final prefs = ref.watch(prefsProvider);
  return BlockExplorerProvider(ref, prefs);
});

class BlockExplorerProvider extends ChangeNotifier {
  final ProviderRef ref;
  final UserPreferencesNotifier prefs;

  BlockExplorerProvider(this.ref, this.prefs);

  List<BlockExplorer> get availableBlockExplorer => [
        const BlockExplorer(
          name: "blockstream.info",
          btcUrl: 'https://blockstream.info/tx/',
          liquidUrl: 'https://blockstream.info/liquid/tx/',
        ),
        const BlockExplorer(
          name: "mempool.space",
          btcUrl: 'https://mempool.space/tx/',
          liquidUrl: 'https://liquid.network/tx/',
        ),
      ];

  BlockExplorer get currentBlockExplorer => availableBlockExplorer.firstWhere(
        (e) => e.name.toLowerCase() == prefs.blockExplorer?.toLowerCase(),
        orElse: () => availableBlockExplorer.first,
      );

  Future<void> setBlockExplorer(BlockExplorer explorer) async {
    prefs.setBlockExplorer(explorer.name);
    notifyListeners();
  }
}
