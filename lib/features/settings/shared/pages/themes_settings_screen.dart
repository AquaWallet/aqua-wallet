import 'package:aqua/common/utils/utils.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/components/top_app_bar/top_app_bar.dart';

enum AppTheme { light, dark, botev, system }

final mapThemeToIcon = {
  AppTheme.system.name: 'U+1F317', // U+1F317
  AppTheme.light.name: 'U+1F31E', // U+1F31E
  AppTheme.dark.name: 'U+1F31A', // U+1F31A
  // TODO: Uncomment when Botev theme is implemented
  // AppTheme.botev.name: [UiAssets.svgs.light.botev.path, UiAssets.svgs.light.botev.pathDark],
};

class ThemesSettingsScreen extends HookConsumerWidget {
  const ThemesSettingsScreen({super.key});

  static const routeName = '/settings/themes';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(prefsProvider.select((p) => p.theme));

    final themeItems = [
      SettingsItem.create(
        AppTheme.system,
        name: context.loc.themesSettingsScreenItemSystem,
        index: 0,
        length: 3,
      ),
      SettingsItem.create(
        AppTheme.light,
        name: context.loc.themesSettingsScreenItemLight,
        index: 1,
        length: 3,
      ),
      SettingsItem.create(
        AppTheme.dark,
        name: context.loc.themesSettingsScreenItemDark,
        index: 2,
        length: 3,
      ),
      // TODO: Uncomment when Botev theme is implemented
      // SettingsItem.create(
      //   AppTheme.botev,
      //   name: context.loc.themesSettingsScreenItemBotev,
      //   index: 3,
      //   length: 3,
      // ),
    ];

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.themesSettingsScreenTitle,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          items: themeItems,
          itemBuilder: (context, item) {
            final theme = item.object as AppTheme;
            final emoji = mapThemeToIcon[theme.name];

            return SettingsListSelectionItem(
              title: item.name,
              icon: emoji != null
                  ? Text(
                      emoji.toEmoji(),
                    )
                  : null,
              isRadioButton: true,
              radioValue: theme.name,
              radioGroupValue: currentTheme,
              onPressed: () {
                ref.read(prefsProvider).setTheme(theme);
              },
            );
          },
        ),
      ),
    );
  }
}
