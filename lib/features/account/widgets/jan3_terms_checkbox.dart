import 'package:coin_cz/config/constants/constants.dart' as constants;
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/gen/fonts.gen.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Jan3TermsCheckbox extends HookWidget {
  const Jan3TermsCheckbox({
    super.key,
    required this.onTermsAccepted,
  });

  final ValueNotifier<bool> onTermsAccepted;

  @override
  Widget build(BuildContext context) {
    final selected = useState(false);

    // TODO: Move to a shared provider to launch URLs
    final openToTermsUrl = useCallback(() async {
      if (await canLaunchUrlString(constants.jan3TermsOfServiceUrl)) {
        await launchUrlString(constants.jan3TermsOfServiceUrl);
      }
    }, []);

    selected.addListener(() {
      onTermsAccepted.value = selected.value;
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox
        Container(
          width: 20,
          height: 20,
          child: Checkbox(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashRadius: 0,
            side: BorderSide(
              color: context.colors.debitCardTransactionSubtitleColor,
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
        // Terms of Service Description
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
                  text: context.loc.jan3TermsCheckboxAgree,
                ),
                // Terms and Conditions Link
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = openToTermsUrl,
                  text: context.loc.jan3TermsCheckboxTerms,
                  style: TextStyle(
                    color: context.colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: context.colorScheme.primary,
                  ),
                ),
                const TextSpan(
                  text: '.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
