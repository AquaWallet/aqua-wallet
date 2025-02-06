import 'package:aqua/common/widgets/middle_ellipsis_text.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/config/config.dart';

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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colors.onBackground,
                            fontWeight: FontWeight.w700,
                          ),
                      startLength: 40,
                      endLength: 40,
                      ellipsisLength: 3,
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
