import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class ExplorerSettings extends StatelessWidget {
  const ExplorerSettings({
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
            title: 'Blockstream',
            titleColor: aquaColors.textPrimary,
            subtitleTrailing: 'Blockstream.info',
            subtitleColor: aquaColors.textSecondary,
            iconTrailing: AquaRadio<bool>.small(
              value: true,
              groupValue: true,
              colors: context.aquaColors,
            ),
            onTap: () {
              debugPrint('');
            },
          ),
          AquaListItem(
            colors: aquaColors,

            ///TODO: theme emojis
            // iconLeading: AquaIcon.dark(),
            title: 'mempool',
            titleColor: aquaColors.textPrimary,
            subtitleTrailing: 'mempool.space',
            subtitleColor: aquaColors.textSecondary,
            iconTrailing: AquaRadio<bool>.small(
              value: false,
              groupValue: true,
              colors: context.aquaColors,
            ),
            onTap: () {
              debugPrint('Light theme selected');
            },
          ),
        ],
      ),
    );
  }
}
