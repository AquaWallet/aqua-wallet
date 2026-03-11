import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/settings/shared/shared.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class ThemeSettings extends HookConsumerWidget {
  const ThemeSettings({
    required this.loc,
    required this.aquaColors,
    required this.currentTheme,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final String currentTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlineContainer(
      aquaColors: aquaColors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaListItem(
            colors: aquaColors,
            iconLeading: const AquaText.h4(text: '🌗'),
            title: loc.themesSettingsScreenItemSystem,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaRadio<bool>.small(
              value: ThemeMode.system.name == currentTheme,
              groupValue: true,
              colors: context.aquaColors,
            ),
            onTap: () async =>
                ref.read(prefsProvider).setTheme(AppTheme.system),
          ),
          AquaListItem(
            colors: aquaColors,
            iconLeading: const AquaText.h4(text: '🌞'),
            title: loc.themesSettingsScreenItemLight,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaRadio<bool>.small(
              value: ThemeMode.light.name == currentTheme,
              groupValue: true,
              colors: context.aquaColors,
            ),
            onTap: () async => ref.read(prefsProvider).setTheme(AppTheme.light),
          ),
          AquaListItem(
            colors: aquaColors,

            ///TODO: theme emojis
            iconLeading: const AquaText.h4(text: '🌚'),
            title: loc.themesSettingsScreenItemDark,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaRadio<bool>.small(
              value: ThemeMode.dark.name == currentTheme,
              groupValue: true,
              colors: context.aquaColors,
            ),
            onTap: () async => ref.read(prefsProvider).setTheme(AppTheme.dark),
          ),
        ],
      ),
    );
  }
}
