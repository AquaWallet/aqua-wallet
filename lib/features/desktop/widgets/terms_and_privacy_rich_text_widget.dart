import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/gestures.dart';
import 'package:ui_components/ui_components.dart';

class TermsAndPrivacyRichText extends StatelessWidget {
  const TermsAndPrivacyRichText({
    super.key,
    required this.aquaColors,
    this.onTermsClick,
    this.onPrivacyClick,
  });

  final AquaColors aquaColors;
  final VoidCallback? onTermsClick;
  final VoidCallback? onPrivacyClick;

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AquaTypography.body2Medium.copyWith(
          color: aquaColors.textSecondary,
        ),
        children: [
          const TextSpan(text: 'By continuing, you agree to our\n'),
          TextSpan(
            text: 'Terms',
            style: AquaTypography.body2SemiBold.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: aquaColors.accentBrand,
              color: aquaColors.accentBrand,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = onTermsClick ??
                  () {
                    // Handle tap
                  },
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: AquaTypography.body2SemiBold.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: aquaColors.accentBrand,
              color: aquaColors.accentBrand,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = onTermsClick ??
                  () {
                    // Handle tap
                  },
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
