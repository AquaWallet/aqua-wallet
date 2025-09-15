import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebitCardTermsCheckbox extends HookWidget {
  const DebitCardTermsCheckbox({
    super.key,
    required this.onTermsAccepted,
  });

  final ValueNotifier onTermsAccepted;

  @override
  Widget build(BuildContext context) {
    final selected = useState(false);

    final openToTermsUrl = useCallback(() async {
      //TODO: Open Terms of Service URL
    }, []);

    selected.addListener(() {
      onTermsAccepted.value = selected.value;
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Checkbox
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 6),
          child: Checkbox(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashRadius: 0,
            side: BorderSide(
              color: context.colorScheme.surface,
              width: 2,
            ),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return context.colorScheme.primary;
              }
              return null;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            value: selected.value,
            onChanged: (value) => selected.value = value!,
          ),
        ),
        const SizedBox(width: 12),
        //ANCHOR - Terms of Service Description
        Expanded(
          child: Text.rich(
            style: TextStyle(
              color: context.colors.onBackground,
              fontSize: 14,
              fontFamily: UiFontFamily.inter,
              fontWeight: FontWeight.w700,
            ),
            TextSpan(
              children: [
                TextSpan(
                  text: context.loc.debitCardOnboardingToSDescriptionNormal,
                ),
                //ANCHOR - T&C Link
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = openToTermsUrl,
                  text: context.loc.debitCardOnboardingToSDescriptionBold,
                  style: TextStyle(
                    color: context.colorScheme.primary,
                    fontSize: 14,
                    fontFamily: UiFontFamily.inter,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
