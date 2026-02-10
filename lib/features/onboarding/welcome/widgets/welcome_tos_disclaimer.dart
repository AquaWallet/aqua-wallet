import 'package:aqua/common/providers/launch_url_provider.dart';
import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class WelcomeToSDisclaimer extends HookConsumerWidget {
  final Color? textColor;
  final bool canLaunch;
  const WelcomeToSDisclaimer({
    super.key,
    this.textColor,
    this.canLaunch = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchUrlNotifier = ref.watch(launchUrlProvider.notifier);

    final openToTermsUrl = useCallback(() async {
      await launchUrlNotifier.launchUrl(constants.aquaTermsOfServiceUrl);
    }, []);

    final openToPrivacyUrl = useCallback(() async {
      await launchUrlNotifier.launchUrl(constants.aquaPrivacyUrl);
    }, []);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AquaText.body2SemiBold(
          text: context.loc.welcomeScreenToSDescription,
          color: textColor ?? AquaPrimitiveColors.palatinateBlue750,
          textAlign: TextAlign.center,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GestureDetector(
              onTap: canLaunch ? openToTermsUrl : null,
              child: AquaText.body2SemiBold(
                text: context.loc.welcomeScreenToSDescriptionBold,
                color: textColor ?? AquaPrimitiveColors.palatinateBlue750,
                underline: true,
              ),
            ),
            const SizedBox(width: 4),
            AquaText.body2SemiBold(
              text: context.loc.and,
              color: textColor ?? AquaPrimitiveColors.palatinateBlue750,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: canLaunch ? openToPrivacyUrl : null,
              child: AquaText.body2SemiBold(
                text: '${context.loc.privacyPolicy}.',
                color: textColor ?? AquaPrimitiveColors.palatinateBlue750,
                underline: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
