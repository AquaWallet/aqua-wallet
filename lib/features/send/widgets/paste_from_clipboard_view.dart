import 'package:coin_cz/common/widgets/colored_text.dart';
import 'package:coin_cz/common/widgets/middle_ellipsis_text.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:google_fonts/google_fonts.dart';

class PasteFromClipboardView extends HookConsumerWidget {
  const PasteFromClipboardView({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onPressed,
            child: BoxShadowCard(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.sendAssetScreenClipboardTitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colors.onBackground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    MiddleEllipsisText(
                      text: text,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colors.onBackground,
                        height: 1.38,
                        letterSpacing: -0.5,
                      ),
                      startLength: 40,
                      endLength: 40,
                      ellipsisLength: 3,
                      colorType: ColoredTextEnum.coloredIntegers,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14.0),
      ],
    );
  }
}
