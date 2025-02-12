import 'package:aqua/common/common.dart';
import 'package:aqua/config/colors/aqua_colors.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Jan3OtpVerificationScreen extends HookConsumerWidget {
  const Jan3OtpVerificationScreen({super.key, required this.email});

  static const routeName = '/otp';
  static const otpDigitCount = 6;

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otp = useState('');
    final otpControllers =
        List.generate(otpDigitCount, (_) => useTextEditingController());
    final focusNodes = List.generate(otpDigitCount, (_) => useFocusNode());
    final isDark = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final profileState = ref.watch(jan3AuthProvider);

    final onOtpChanged = useCallback((String value, int index) {
      if (value.length == 1 && index < otpDigitCount - 1) {
        focusNodes[index + 1].requestFocus();
      }
      otp.value = otpControllers.map((c) => c.text).join();
    }, [focusNodes, otpDigitCount]);

    // Handle backspace
    final onKeyEvent = useCallback((KeyEvent event, int index) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.backspace &&
            otpControllers[index].text.isEmpty &&
            index > 0) {
          focusNodes[index - 1].requestFocus();
        }
      }
    }, [focusNodes, otpControllers]);

    final isOtpValid = useMemoized(() {
      return otp.value.length == otpDigitCount;
    }, [otp.value]);

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
                      // height: 1.43,
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
              onTap: () => context.pop(),
            ),
            const SizedBox(height: 16),
            // ANCHOR - OTP input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                otpDigitCount,
                (index) => SizedBox(
                  width: 52,
                  height: 56,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => onKeyEvent(event, index),
                    child: TextField(
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.colors.jan3InputFieldBackgroundColor,
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            width: 1,
                            color: AquaColors.dimMarble,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 1,
                            color: context.colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 1,
                      onChanged: (value) {
                        onOtpChanged(value, index);
                      },
                    ),
                  ),
                ),
              ),
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
              onTap: () => ref.read(jan3AuthProvider.notifier).sendOtp(email),
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
