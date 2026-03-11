import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class WalletRestoreHeader extends StatelessWidget {
  const WalletRestoreHeader({
    super.key,
    required this.error,
  });

  final bool error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error) ...{
          AquaText.body1SemiBold(
            text: context.loc.restoreInputError,
            color: context.aquaColors.accentDanger,
          )
        } else ...{
          AquaText.body1SemiBold(
            text: context.loc.enterSeedWords,
            color: context.aquaColors.textPrimary,
          )
        },
      ],
    );
  }
}
