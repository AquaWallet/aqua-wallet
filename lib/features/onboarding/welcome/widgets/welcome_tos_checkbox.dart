import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/shared/shared.dart';
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
          child: Checkbox(
            key: const Key('welcome-tos-checkbox'),
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
        SizedBox(width: 8.w),
        Expanded(
          child: Text.rich(
            //ANCHOR - Description
            TextSpan(
              text: context.loc.welcomeScreenToSDescriptionNormal,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
              children: [
                //ANCHOR - Terms of Service link
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = openToTermsUrl,
                  text: context.loc.welcomeScreenToSDescriptionBold,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextSpan(
                  text: " & ",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                ),
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = openToPrivacyUrl,
                  text: context.loc.welcomeScreenPrivacyDescriptionBold,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
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
