import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class BlockExplorerSettingsScreen extends HookConsumerWidget {
  static const routeName = '/blockExplorerSettingsScreen';

  const BlockExplorerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableExplorers = useMemoized(
      () => BlockExplorer.availableBlockExplorers,
    );
    final current =
        ref.watch(blockExplorerProvider.select((p) => p.currentBlockExplorer));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.blockExplorerSettingsTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          label: current.name,
          items: availableExplorers
              .mapIndexed((index, item) => SettingsItem.create(item,
                  name: item.name,
                  index: index,
                  length: availableExplorers.length))
              .toList(),
          itemBuilder: (_, item) {
            final explorer = item.object as BlockExplorer;
            return SettingsListSelectionItem(
              content: Text(item.name),
              position: item.position,
              onPressed: () =>
                  ref.read(blockExplorerProvider).setBlockExplorer(explorer),
            );
          },
        ),
      ),
    );
  }
}
