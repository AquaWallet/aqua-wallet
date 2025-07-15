import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/pin/models/pin_state.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/pin/pin_success_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/utils/utils.dart';

class PinScreenWidget extends ConsumerWidget {
  const PinScreenWidget(
      {super.key,
      required this.pinState,
      required this.description,
      this.canCancel = true});

  final PinState pinState;
  final String description;
  final bool canCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinAuthState = ref.read(pinAuthProvider).asData?.value;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppStyle.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                //ANCHOR - Aqua Logo
                UiAssets.svgs.dark.aquaLogo.svg(
                  width: 321.0,
                ),
                const SizedBox(height: 90),
                if (pinAuthState != PinAuthState.locked) ...[
                  Text(
                    textAlign: TextAlign.center,
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
                const SizedBox(height: 15),
                if (pinAuthState == PinAuthState.locked) ...[
                  Text(
                    textAlign: TextAlign.center,
                    context.loc.pinScreenLockedMessage,
                    style: const TextStyle(
                      color: AquaColors.warningOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (index) => Container(
                        width: 16.5,
                        height: 16.5,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < pinState.pin.length
                              ? Colors.white
                              : AquaColors.aquaBlue,
                        ),
                      ),
                    ),
                  ),
                  if (pinState.isError) ...[
                    const SizedBox(height: 50),
                    Text(
                      pinState.errorMessage ??
                          context.loc.pinScreenInvalidPinMessage,
                      style: const TextStyle(
                        color: AquaColors.warningOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const Spacer(),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index == 9) {
                        if (canCancel == false) {
                          return const SizedBox.shrink();
                        }

                        return GestureDetector(
                            onTap: () => context.pop(),
                            child: Center(
                                child: Text(
                              context.loc.cancel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
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
                          icon: const Icon(Icons.backspace_outlined),
                        );
                      }
                      return NumberButton(
                        label: '${index + 1}',
                        onTap: () => ref
                            .read(pinProvider.notifier)
                            .addDigit('${index + 1}'),
                      );
                    },
                  )
                ],
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
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
            ),
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

  CheckPinScreenArguments(
      {this.canCancel = false,
      this.onSuccessAction = CheckAction.callback,
      this.onSuccessCallback,
      this.description});
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

    return PinScreenWidget(
      pinState: pinState,
      description: arguments.description ?? context.loc.pinScreenDescription,
      canCancel: arguments.canCancel,
    );
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
          context.replace(PinSuccessScreen.routeName);
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
