import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class SecuritySettings extends StatelessWidget {
  const SecuritySettings({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return OutlineContainer(
      aquaColors: aquaColors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaListItem(
            colors: aquaColors,
            title: loc.settingsScreenItemPin,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaToggle(
              value: true,
              onChanged: (value) {},
            ),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) => const Dialog.fullscreen(
                  child: PasscodeEntryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
