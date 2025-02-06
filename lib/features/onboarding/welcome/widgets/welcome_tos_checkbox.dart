import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/onboarding/keys/onboarding_screen_keys.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher_string.dart';

class WelcomeToSCheckbox extends HookConsumerWidget {
  const WelcomeToSCheckbox({
    super.key,
    required this.onTosAccepted,
  });

  final ValueNotifier onTosAccepted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState(false);

    final openToTermsUrl = useCallback(() async {
      if (await canLaunchUrlString(constants.aquaTermsOfServiceUrl)) {
        await launchUrlString(constants.aquaTermsOfServiceUrl);
      }
    }, []);

    final openToPrivacyUrl = useCallback(() async {
      if (await canLaunchUrlString(constants.aquaPrivacyUrl)) {
        await launchUrlString(constants.aquaPrivacyUrl);
      }
    }, []);

    selected.addListener(() {
      onTosAccepted.value = selected.value;
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //ANCHOR - Checkbox
        Container(
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
          child: Transform.scale(
            scale: 1.5,
            child: Checkbox(
              key: OnboardingScreenKeys.welcomeTosCheckbox,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: Theme.of(context).colorScheme.surface,
                width: 2.0,
              ),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primary;
                }
                return Theme.of(context).colorScheme.surface;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100.0),
              ),
              value: selected.value,
              onChanged: (value) => selected.value = value!,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text.rich(
            //ANCHOR - Description
            TextSpan(
              text: context.loc.welcomeScreenToSDescriptionNormal,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: -0.9,
                    height: 1.5,
                  ),
              children: [
                //ANCHOR - Terms of Service link
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = openToTermsUrl,
                  text: context.loc.welcomeScreenToSDescriptionBold,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        letterSpacing: -1.2,
                        height: 1.5,
                      ),
                ),
                TextSpan(
                  text: " & ",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.9,
                        height: 1.5,
                      ),
                ),
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = openToPrivacyUrl,
                  text: context.loc.privacyPolicy,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        letterSpacing: -1.2,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
