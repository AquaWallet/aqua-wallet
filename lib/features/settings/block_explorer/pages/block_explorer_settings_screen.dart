import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/widgets/aqua_appbar.dart';
import 'package:aqua/utils/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BlockExplorerSettingsScreen extends HookConsumerWidget {
  static const routeName = '/blockExplorerSettingsScreen';

  const BlockExplorerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorers =
        ref.read(blockExplorerProvider.select((p) => p.availableBlockExplorer));
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
          items: explorers
              .mapIndexed((index, item) => SettingsItem.create(item,
                  name: item.name, index: index, length: explorers.length))
              .toList(),
          itemBuilder: (context, item) {
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
