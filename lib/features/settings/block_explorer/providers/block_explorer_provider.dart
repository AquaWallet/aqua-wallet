import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

final blockExplorerProvider =
    Provider.autoDispose<BlockExplorerNotifier>((ref) {
  final prefs = ref.watch(prefsProvider);
  return BlockExplorerNotifier(prefs);
});

class BlockExplorerNotifier extends ChangeNotifier {
  final UserPreferencesNotifier prefs;

  BlockExplorerNotifier(this.prefs);

  BlockExplorer get currentBlockExplorer {
    return BlockExplorer.availableBlockExplorers.firstWhere(
      (e) => e.name.toLowerCase() == prefs.blockExplorer?.toLowerCase(),
      orElse: () => BlockExplorer.availableBlockExplorers.first,
    );
  }

  Future<void> setBlockExplorer(BlockExplorer explorer) async {
    prefs.setBlockExplorer(explorer.name);
    notifyListeners();
  }
}
