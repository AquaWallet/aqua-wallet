import 'package:coin_cz/config/constants/svgs.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppTheme { light, dark, botev, system }

final mapThemeToIcon = {
  AppTheme.light.name: Svgs.sun,
  AppTheme.dark.name: Svgs.darkMode,
  AppTheme.botev.name: [Svgs.botev, Svgs.botevDark],
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
      SettingsItem.create(
        AppTheme.botev,
        name: context.loc.themesSettingsScreenItemBotev,
        index: 3,
        length: 3,
      ),
    ];

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.themesSettingsScreenTitle,
        backgroundColor: context.colors.appBarBackgroundColor,
        showActionButton: false,
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          label: currentTheme.toUpperCase(),
          items: themeItems,
          itemBuilder: (context, item) {
            final theme = item.object as AppTheme;
            final icon = mapThemeToIcon[theme.name];

            return SettingsListSelectionItem(
              content: Text(item.name),
              icon: icon != null
                  ? SvgPicture.asset(
                      icon is String
                          ? icon
                          : theme == AppTheme.light
                              ? (icon as List).firstOrNull
                              : (icon as List).lastOrNull,
                      width: 24,
                      height: 24,
                      colorFilter: icon is String
                          ? ColorFilter.mode(
                              Theme.of(context).colorScheme.onSecondary,
                              BlendMode.srcIn,
                            )
                          : null,
                    )
                  : null,
              position: item.position,
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
