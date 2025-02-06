import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/config/colors/aqua_colors.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
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
      backgroundColor: AquaColors.eerieBlack,
      appBar: AquaAppBar(
        backgroundColor: Colors.transparent,
        titleWidget: UiAssets.svgs.dark.jan3Logo.svg(),
        showActionButton: false,
        iconBackgroundColor: AquaColors.eerieBlack,
        iconForegroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.otpScreenTitle,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style:
                    const TextStyle(fontSize: 16, color: AquaColors.dimMarble),
                children: [
                  TextSpan(
                    text: '${context.loc.otpScreenDescription} ',
                  ),
                  TextSpan(
                    text: email,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  context.loc.otpScreenNotYourEmail,
                  style: const TextStyle(color: AquaColors.dimMarble),
                ),
                const SizedBox(width: 3),
                TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: Text(
                    context.loc.otpScreenChangeEmail,
                    style: const TextStyle(
                      color: AquaColors.aquaGreen,
                      decoration: TextDecoration.underline,
                      decorationColor: AquaColors.aquaGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ANCHOR - OTP input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                otpDigitCount,
                (index) => Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: AquaColors.charlestonGreen,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: AquaColors.dimMarble,
                      width: 1.0,
                    ),
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) => onKeyEvent(event, index),
                    child: TextField(
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AquaColors.charlestonGreen,
                        border: InputBorder.none,
                        counterText: '',
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
            if (profileState.error != null)
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
            // ANCHOR - Resend OTP
            Row(
              children: [
                Text(
                  context.loc.otpScreenResendCode,
                  style: const TextStyle(color: AquaColors.dimMarble),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(jan3AuthProvider.notifier).sendOtp(email);
                  },
                  child: Text(
                    context.loc.otpScreenResendButton,
                    style: const TextStyle(
                      color: AquaColors.aquaGreen,
                      decoration: TextDecoration.underline,
                      decorationColor: AquaColors.aquaGreen,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // ANCHOR - Verify OTP button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (profileState.isLoading || !isOtpValid)
                    ? null
                    : () => ref.read(jan3AuthProvider.notifier).verifyOtp(
                          email: email,
                          otp: otp.value,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (profileState.isLoading || !isOtpValid)
                      ? AquaColors.dimMarble
                      : AquaColors.aquaGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: profileState.isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        context.loc.otpScreenVerifyButton,
                        style: const TextStyle(
                          color: AquaColors.eerieBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
