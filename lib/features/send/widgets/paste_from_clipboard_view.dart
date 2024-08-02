import 'package:aqua/common/widgets/middle_ellipsis_text.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

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
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.sendAssetScreenClipboardTitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    MiddleEllipsisText(
                      text: text,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
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
        SizedBox(width: 14.w),
      ],
    );
  }
}
