import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/config/colors/aqua_colors.dart';
import 'package:coin_cz/features/account/account.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/gen/fonts.gen.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pinput/pinput.dart';

class Jan3OtpVerificationScreen extends HookConsumerWidget {
  const Jan3OtpVerificationScreen({super.key, required this.email});

  static const routeName = '/otp';
  static const otpDigitCount = 6;

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otp = useState('');
    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();
    final isDark =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final profileState = ref.watch(jan3AuthProvider);

    final isOtpValid = useMemoized(() {
      return otp.value.length == otpDigitCount;
    }, [otp.value]);

    final defaultPinTheme = useMemoized(
        () => PinTheme(
              width: 52,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 18,
                fontFamily: UiFontFamily.inter,
              ),
              decoration: BoxDecoration(
                color: context.colors.jan3InputFieldBackgroundColor,
                border: Border.all(
                  color: AquaColors.dimMarble,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        [context.colors.jan3InputFieldBackgroundColor]);

    final focusedPinTheme = useMemoized(
        () => defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(
                  color: context.colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
        [defaultPinTheme, context.colorScheme.primary]);

    return Scaffold(
      appBar: AquaAppBar(
        backgroundColor: Colors.transparent,
        titleWidget: isDark
            ? UiAssets.svgs.dark.jan3Logo.svg()
            : UiAssets.svgs.light.jan3Logo.svg(),
        showActionButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            //ANCHOR - Title
            Text(
              context.loc.otpScreenTitle,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: UiFontFamily.inter,
              ),
            ),
            const SizedBox(height: 12),
            //ANCHOR - Description
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.43,
                  letterSpacing: 0.2,
                  color: AquaColors.dimMarble,
                  fontFamily: UiFontFamily.inter,
                ),
                children: [
                  TextSpan(
                    text: '${context.loc.otpScreenDescription} ',
                  ),
                  TextSpan(
                    text: email,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.onBackground,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const TextSpan(
                    text: '.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            //ANCHOR - Change email button
            _TappableTextSpan(
              description: context.loc.otpScreenNotYourEmail,
              tappableText: context.loc.otpScreenChangeEmail,
              onTap: () {
                ref.invalidate(jan3AuthProvider);
                context.pop();
              },
            ),
            const SizedBox(height: 16),
            // ANCHOR - Pinput OTP input
            Pinput(
              length: otpDigitCount,
              controller: pinController,
              focusNode: pinFocusNode,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              keyboardType: TextInputType.number,
              isCursorAnimationEnabled: false,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              onChanged: (value) {
                otp.value = value;
              },
              onCompleted: (value) {
                if (profileState.isLoading) {
                  return;
                }
                ref.read(jan3AuthProvider.notifier).verifyOtp(
                      email: email,
                      otp: otp.value,
                    );
              },
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
            // ANCHOR - OTP form errors
            if (!profileState.isLoading && profileState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AquaColors.portlandOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profileState.error is ExceptionLocalized
                          ? (profileState.error as ExceptionLocalized)
                              .toLocalizedString(context)
                          : profileState.error.toString(),
                      style: const TextStyle(
                        color: AquaColors.portlandOrange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // ANCHOR - Resend OTP
            _TappableTextSpan(
              description: context.loc.otpScreenResendCode,
              tappableText: context.loc.otpScreenResendButton,
              onTap: () => ref.read(jan3AuthProvider.notifier).sendOtp(
                    email,
                    ref.read(languageProvider(context)
                        .select((p) => p.currentLanguage)),
                  ),
            ),
            const Spacer(),
            // ANCHOR - Verify OTP button
            AquaElevatedButton(
              onPressed: (profileState.isLoading || !isOtpValid)
                  ? null
                  : () => ref.read(jan3AuthProvider.notifier).verifyOtp(
                        email: email,
                        otp: otp.value,
                      ),
              child: profileState.isLoading
                  ? const CircularProgressIndicator()
                  : Text(context.loc.otpScreenVerifyButton),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TappableTextSpan extends StatelessWidget {
  const _TappableTextSpan({
    required this.description,
    required this.tappableText,
    required this.onTap,
  });

  final String description;
  final String tappableText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$description ',
            style: const TextStyle(
              fontSize: 14,
              height: 1.43,
              letterSpacing: 0.1,
              color: AquaColors.dimMarble,
              fontWeight: FontWeight.w500,
              fontFamily: UiFontFamily.inter,
            ),
          ),
          TextSpan(
            text: tappableText,
            recognizer: TapGestureRecognizer()..onTap = onTap,
            style: const TextStyle(
              fontSize: 14,
              height: 1.43,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w500,
              fontFamily: UiFontFamily.inter,
              color: AquaColors.vividSkyBlue,
              decorationColor: AquaColors.vividSkyBlue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
