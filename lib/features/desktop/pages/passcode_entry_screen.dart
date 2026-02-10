import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/widgets/pascode_input_paint_widget.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pinput/pinput.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

class PasscodeEntryScreen extends HookConsumerWidget {
  const PasscodeEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final loc = context.loc;

    final otp = useState('');
    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();

    final defaultPinTheme = useMemoized(
        () => PinTheme(
              width: 16,
              height: 16,
              textStyle: const TextStyle(
                fontSize: 18,
                fontFamily: UiFontFamily.inter,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.3),
                shape: BoxShape.circle,
              ),
            ),
        [context.colors.jan3InputFieldBackgroundColor]);

    final focusedPinTheme = useMemoized(
        () => defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: Colors.white,
              ),
            ),
        [defaultPinTheme, context.colorScheme.primary]);

    return Container(
      decoration: BoxDecoration(
        gradient: AquaColors.gradient,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 64,
      ),
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: onboardingContentWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AquaUiAssets.svgs.aquaLogo.svg(
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(height: 24),
                      const AquaText.h4SemiBold(
                          text: 'Enter Your Passcode', color: Colors.white),
                      const SizedBox(height: 16),
                      const AquaText.body1(
                        text:
                            'If you forget it, you\'ll need to restore your wallet using your seed phrase.',
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Pinput(
                        length: 6,
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
                          ///TODO: verify passcode
                          Navigator.pop(context);
                        },
                        separatorBuilder: (index) => const SizedBox(width: 16),
                        crossAxisAlignment: CrossAxisAlignment.center,
                        showCursor: false,
                        obscureText: true,
                        obscuringWidget: const PasscodeInputPaintWidget(),
                        autofocus: true,
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      // Handle forgot passcode tap
                    },
                    child: const AquaText.body1SemiBold(
                      text: 'Forgot Your Passcode?',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          ///TODDO: remove this close when done
          const Align(
            alignment: Alignment(.9, -1),
            child: CloseButton(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
