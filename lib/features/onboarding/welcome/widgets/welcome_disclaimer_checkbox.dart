import 'package:aqua/features/onboarding/welcome/widgets/welcome_disclaimer_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WelcomeDisclaimerCheckbox extends HookConsumerWidget {
  const WelcomeDisclaimerCheckbox({
    super.key,
    required this.onDisclaimerAccepted,
  });

  final ValueNotifier onDisclaimerAccepted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState(false);

    selected.addListener(() {
      onDisclaimerAccepted.value = selected.value;
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //ANCHOR - Checkbox
        Transform.scale(
          scale: 1.4,
          alignment: Alignment.centerRight,
          origin: Offset(-8.w, 0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 0.toDouble()),
                  blurRadius: 10,
                  spreadRadius: 0,
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                )
              ],
            ),
            child: Checkbox(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: Theme.of(context).colorScheme.surface,
                width: 2.w,
              ),
              fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).colorScheme.primary;
                }
                return Theme.of(context).colorScheme.surface;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
              value: selected.value,
              onChanged: (value) => selected.value = value!,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
              children: [
                TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Navigator.of(context)
                        .pushNamed(WelcomeDisclaimerScreen.routeName),
                  text: 'understand the risks',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const TextSpan(
                  text: ' of using the beta version',
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
