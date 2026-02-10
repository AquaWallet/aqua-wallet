import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class NoDataPlaceholder extends StatelessWidget {
  const NoDataPlaceholder({
    super.key,
    required this.title,
    required this.aquaColors,
    this.subtitle = '',
  });

  final String title;
  final String subtitle;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AquaRingedIcon(
              icon: AquaIcon.pending(
                color: aquaColors.textTertiary,
              ),
              colors: aquaColors,
              variant: AquaRingedIconVariant.normal,
            ),
            const SizedBox(
              height: 24.0,
            ),
            AquaText.h4Medium(
              text: title,
            ),
            if (subtitle.isNotEmpty)
              AquaText.body1(
                text: subtitle,
              ),
          ],
        ),
      ),
    );
  }
}
