import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/components/top_app_bar/top_app_bar.dart';

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

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: context.loc.blockExplorerSettingsTitle,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          items: availableExplorers
              .mapIndexed((index, item) => SettingsItem.create(item,
                  name: item.name,
                  index: index,
                  length: availableExplorers.length))
              .toList(),
          itemBuilder: (_, item) {
            final explorer = item.object as BlockExplorer;
            return SettingsListSelectionItem<BlockExplorer>(
              title: item.name,
              onPressed: () =>
                  ref.read(blockExplorerProvider).setBlockExplorer(explorer),
              isRadioButton: true,
              radioValue: explorer,
              radioGroupValue: current,
            );
          },
        ),
      ),
    );
  }
}
