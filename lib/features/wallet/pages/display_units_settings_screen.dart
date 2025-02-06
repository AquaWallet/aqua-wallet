import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/providers.dart';
import 'package:aqua/utils/utils.dart';

class DisplayUnitsSettingsScreen extends HookConsumerWidget {
  static const routeName = '/displayUnitSettingsScreen';
  const DisplayUnitsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayUnits =
        ref.watch(displayUnitsProvider.select((p) => p.supportedDisplayUnits));
    final currentDisplayUnit =
        ref.watch(displayUnitsProvider.select((p) => p.currentDisplayUnit));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.displayUnits,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          label: currentDisplayUnit.value,
          items: displayUnits
              .mapIndexed((index, item) => SettingsItem.create(item,
                  name: item.value, index: index, length: displayUnits.length))
              .toList(),
          itemBuilder: (context, item) {
            return SettingsListSelectionItem(
              content: Text(item.name),
              position: item.position,
              onPressed: () => ref
                  .read(displayUnitsProvider)
                  .setCurrentDisplayUnit(item.name),
            );
          },
        ),
      ),
    );
  }
}
