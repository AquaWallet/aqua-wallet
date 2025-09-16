import 'package:coin_cz/common/providers/launch_url_provider.dart';
import 'package:coin_cz/config/constants/constants.dart' as constants;
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/gen/fonts.gen.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/gestures.dart';

class Jan3Terms extends HookConsumerWidget {
  const Jan3Terms({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Terms of Service Description
        Expanded(
          child: Text.rich(
            textAlign: TextAlign.center,
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
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => ref
                        .read(launchUrlProvider.notifier)
                        .launchUrl(constants.jan3TermsOfServiceUrl),
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
