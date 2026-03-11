import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

enum AutoLockOption {
  always(0),
  tenMinutes(10),
  thirtyMinutes(30),
  fortyFiveMinutes(45),
  sixtyMinutes(60);

  const AutoLockOption(this.value);

  final int value;
}

class AutoLockSettingsScreen extends HookConsumerWidget {
  const AutoLockSettingsScreen({super.key});

  static const routeName = '/settings/auto-lock';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAutoLock =
        ref.watch(prefsProvider.select((p) => p.autoLockAfter));

    final autoLockItems = [
      SettingsItem.create(
        AutoLockOption.always,
        name: _getAutoLockLabel(context, AutoLockOption.always),
        index: 0,
        length: 5,
      ),
      SettingsItem.create(
        AutoLockOption.tenMinutes,
        name: _getAutoLockLabel(context, AutoLockOption.tenMinutes),
        index: 1,
        length: 5,
      ),
      SettingsItem.create(
        AutoLockOption.thirtyMinutes,
        name: _getAutoLockLabel(context, AutoLockOption.thirtyMinutes),
        index: 2,
        length: 5,
      ),
      SettingsItem.create(
        AutoLockOption.fortyFiveMinutes,
        name: _getAutoLockLabel(context, AutoLockOption.fortyFiveMinutes),
        index: 3,
        length: 5,
      ),
      SettingsItem.create(
        AutoLockOption.sixtyMinutes,
        name: _getAutoLockLabel(context, AutoLockOption.sixtyMinutes),
        index: 4,
        length: 5,
      ),
    ];

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.autoLockSettingsScreenTitle,
        backgroundColor: context.colors.appBarBackgroundColor,
        showActionButton: false,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          label: _getAutoLockLabel(context, currentAutoLock),
          items: autoLockItems,
          itemBuilder: (context, item) {
            final autoLockAfter = item.object as AutoLockOption;

            return SettingsListSelectionItem(
              content: Text(item.name),
              onPressed: () {
                ref.read(prefsProvider).setAutoLockAfter(autoLockAfter);
              },
            );
          },
        ),
      ),
    );
  }

  String _getAutoLockLabel(BuildContext context, AutoLockOption duration) {
    if (duration == AutoLockOption.always) {
      return context.loc.autoLockSettingsOptionAlways.toUpperCase();
    }

    return context.loc
        .autoLockSettingsOptionMinutes(duration.value)
        .toUpperCase();
  }
}
