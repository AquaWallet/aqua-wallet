import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/pin/models/pin_state.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class PinScreenWidget extends ConsumerWidget {
  const PinScreenWidget({
    super.key,
    required this.pinState,
    required this.description,
    this.isPasscodeSetup = true,
  });

  final PinState pinState;
  final String description;
  final bool isPasscodeSetup;
  static const keyboardKeysLength = 12;
  static const keyboardNumberKeysLength = 9;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinAuthState = ref.read(pinAuthProvider).asData?.value;
    final remainingTime = pinAuthState == PinAuthState.locked
        ? ref.watch(pinLockTimerProvider)
        : null;

    final mainTitle = pinState.isError
        ? (context.loc.pinScreenInvalidPinMessage)
        : description;

    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                //ANCHOR - Aqua Logo
                AquaIcon.aquaLogo(
                  size: 40,
                  color: AquaPrimitiveColors.palatinateBlue750,
                ),
                // const SizedBox(height: 64),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AquaText.h4SemiBold(
                        textAlign: TextAlign.center,
                        text: mainTitle,
                        color: AquaPrimitiveColors.palatinateBlue750
                            .withOpacity(
                                pinAuthState == PinAuthState.locked ? 0.6 : 1),
                      ),
                      const SizedBox(height: 16),
                      if (isPasscodeSetup) ...[
                        AquaText.body1(
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            text: context.loc.pinScreenWarningSubtitle,
                            color: AquaPrimitiveColors.palatinateBlue750
                                .withOpacity(0.8)),
                      ],
                      const SizedBox(height: 15),
                      if (pinAuthState == PinAuthState.locked) ...[
                        AquaTooltip(
                          message: remainingTime != null
                              ? context.loc.pinScreenLockedCountdownMessage(
                                  remainingTime)
                              : context.loc.pinScreenLockedMessage,
                          colors: context.aquaColors,
                        ),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          6,
                          (index) => Container(
                            width: 16.5,
                            height: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: index < pinState.pin.length
                                ? CustomPaint(
                                    painter: RaindropPainter(
                                      color: AquaPrimitiveColors
                                          .palatinateBlue750
                                          .withOpacity(
                                        pinAuthState == PinAuthState.locked
                                            ? 0.3
                                            : 1,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 16.5,
                                    height: 16.5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AquaPrimitiveColors
                                          .palatinateBlue750
                                          .withOpacity(
                                        pinAuthState == PinAuthState.locked
                                            ? 0.15
                                            : 0.3,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  ignoring: pinAuthState == PinAuthState.locked,
                  child: Opacity(
                    opacity: pinAuthState == PinAuthState.locked ? 0.3 : 1,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: keyboardKeysLength,
                      itemBuilder: (context, index) {
                        if (index == keyboardNumberKeysLength) {
                          if (isPasscodeSetup == false) {
                            return const SizedBox.shrink();
                          }

                          return GestureDetector(
                              onTap: () => context.pop(),
                              child: Center(
                                  child: AquaText.body1Medium(
                                text: context.loc.cancel,
                                color: Colors.white,
                              )));
                        }
                        if (index == 10) {
                          return NumberButton(
                            label: '0',
                            onTap: () =>
                                ref.read(pinProvider.notifier).addDigit('0'),
                          );
                        }
                        if (index == 11) {
                          return IconButton(
                            color: Colors.white,
                            onPressed: () =>
                                ref.read(pinProvider.notifier).removeDigit(),
                            icon: AquaIcon.remove(
                              color: Colors.white,
                            ),
                          );
                        }
                        return NumberButton(
                          label: '${index + 1}',
                          onTap: () => ref
                              .read(pinProvider.notifier)
                              .addDigit('${index + 1}'),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const NumberButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: AquaText.h3(
            text: label,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

enum CheckAction { pull, callback }

class CheckPinScreenArguments {
  final CheckAction onSuccessAction;
  final Function? onSuccessCallback;
  final String? description;
  final bool canCancel;

  CheckPinScreenArguments({
    this.canCancel = false,
    this.onSuccessAction = CheckAction.callback,
    this.onSuccessCallback,
    this.description,
  });
}

class CheckPinScreen extends HookConsumerWidget {
  static const routeName = '/checkPin';
  final CheckPinScreenArguments arguments;

  const CheckPinScreen({super.key, required this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinProvider);

    useEffect(() {
      Future.microtask(() async {
        if (pinState.failedAttempts == 0) {
          final (failedAttempts, _) = await ref
              .read(secureStorageProvider)
              .get(StorageKeys.pinFailedAttempts);
          if (failedAttempts != null) {
            final number = int.parse(failedAttempts);
            ref.read(pinProvider.notifier).setFailedAttempts(number);
          }
        }
      });

      return null;
    }, []);

    useEffect(() {
      Future.microtask(() async {
        if (pinState.pin.length == PinNotifier.pinLength) {
          final isValid = await ref.read(pinProvider.notifier).validatePin();
          if (isValid) {
            if (arguments.onSuccessAction == CheckAction.pull) {
              if (context.mounted) {
                return context.pop(true);
              }
            }

            if (arguments.onSuccessCallback != null) {
              arguments.onSuccessCallback!();
            }
          }
        }
      });

      return null;
    }, [pinState.pin]);

    return PopScope(
        canPop: arguments.canCancel,
        child: PinScreenWidget(
          pinState: pinState,
          description:
              arguments.description ?? context.loc.pinScreenDisabledDescription,
          isPasscodeSetup: arguments.canCancel,
        ));
  }
}

class SetupPinScreen extends HookConsumerWidget {
  const SetupPinScreen({super.key});

  static const routeName = '/setupPin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinProvider);
    final setupPin = useState('');
    final failed = useState(false);

    useEffect(() {
      Future.microtask(() {
        if (pinState.pin.length == PinNotifier.pinLength) {
          failed.value = false;
          if (setupPin.value.isEmpty) {
            setupPin.value = pinState.pin;
            return ref.read(pinProvider.notifier).clear();
          }

          if (setupPin.value != pinState.pin) {
            ref.read(pinProvider.notifier).clear();
            setupPin.value = '';
            failed.value = true;
            return;
          }

          ref.read(pinAuthProvider.notifier).setPin(setupPin.value);
          AquaTooltip.show(
            context,
            message: context.loc.pinScreenSuccessTitle,
            colors: context.aquaColors,
          );
          context.pop();
        }
      });

      return null;
    }, [pinState.pin]);

    return PinScreenWidget(
      pinState: pinState,
      description: failed.value
          ? context.loc.pinScreenSetupMismatchError
          : setupPin.value.length == 6
              ? context.loc.pinScreenSetupVerifyDescription
              : context.loc.pinScreenSetupDescription,
    );
  }
}

class RaindropPainter extends CustomPainter {
  final Color color;

  const RaindropPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Raindrop shape: pointy top, circular bottom
    final centerX = size.width / 2;
    final radius = size.width;

    // Start from the top point
    path.moveTo(centerX, 0);

    // Left curve down to the circle
    path.quadraticBezierTo(
      centerX - radius * 0.4,
      size.height * 0.25,
      centerX - radius * 0.5,
      size.height * 0.6,
    );

    // Bottom circle
    path.arcToPoint(
      Offset(centerX + radius * 0.5, size.height * 0.5),
      radius: Radius.circular(radius * 0.3),
      clockwise: false,
    );

    // Right curve back up to the top point
    path.quadraticBezierTo(
      centerX + radius * 0.4,
      size.height * 0.25,
      centerX,
      0,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RaindropPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
