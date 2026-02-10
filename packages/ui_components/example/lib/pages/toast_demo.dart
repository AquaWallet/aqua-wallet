import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/providers/providers.dart';
import 'package:ui_components_playground/shared/shared.dart';

const _lorem = 'lorem ipsum dolor sit amet consectetur adipiscing elit sed do';

class ToastDemoPage extends HookConsumerWidget {
  const ToastDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final showToast1 = useState(true);
    final showToast2 = useState(true);
    final showToast3 = useState(true);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              children: [
                AquaToast(
                  title: 'Example',
                  description: _lorem,
                  variant: AquaToastVariant.normal,
                  aquaColors: theme.colors,
                  onClose: () {
                    debugPrint('Close pressed');
                  },
                ),
                const SizedBox(height: 5),
                AquaToast(
                  title: 'Example',
                  description: _lorem,
                  variant: AquaToastVariant.error,
                  aquaColors: theme.colors,
                ),
                const SizedBox(height: 5),
                AquaToast(
                  title: 'Example',
                  description: _lorem,
                  variant: AquaToastVariant.normal,
                  aquaColors: theme.colors,
                  actions: [
                    AquaToastAction(
                      title: 'Action 1',
                      onPressed: () {
                        debugPrint('Action pressed');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                AquaToast(
                    title: 'Example',
                    description: _lorem,
                    variant: AquaToastVariant.normal,
                    aquaColors: theme.colors,
                    actions: [
                      AquaToastAction(
                        title: 'Action 1',
                        onPressed: () {
                          debugPrint('Action pressed');
                        },
                      ),
                      AquaToastAction(
                        title: 'Action 2',
                        onPressed: () {
                          debugPrint('Action pressed');
                        },
                      ),
                    ]),
                const SizedBox(height: 5),
                AquaToast(
                    title: 'Example',
                    description: _lorem,
                    variant: AquaToastVariant.warning,
                    aquaColors: theme.colors,
                    actions: [
                      AquaToastAction(
                        title: 'Action 1',
                        onPressed: () {
                          debugPrint('Action pressed');
                        },
                      ),
                      AquaToastAction(
                        title: 'Action 2',
                        onPressed: () {
                          debugPrint('Action pressed');
                        },
                      ),
                      AquaToastAction(
                        title: 'Action 3',
                        onPressed: () {
                          debugPrint('Action pressed');
                        },
                      ),
                    ]),
                const SizedBox(height: 5),
                if (showToast1.value)
                  AquaToast.timed(
                    title: 'Auto Dismiss',
                    description:
                        'This toast will dismiss automatically in 5 seconds',
                    variant: AquaToastVariant.normal,
                    aquaColors: theme.colors,
                    duration: const Duration(seconds: 5),
                    onDismiss: () {
                      debugPrint('Toast dismissed automatically');
                      showToast1.value = false;
                    },
                  )
                else
                  AquaButton.primary(
                    text: 'Show Auto Dismiss Toast',
                    onPressed: () => showToast1.value = true,
                  ),
                const SizedBox(height: 5),
                if (showToast2.value)
                  AquaToast.timed(
                    title: 'Auto Dismiss Warning',
                    description: 'This warning toast will dismiss in 3 seconds',
                    variant: AquaToastVariant.warning,
                    aquaColors: theme.colors,
                    duration: const Duration(seconds: 3),
                    onDismiss: () {
                      debugPrint('Warning toast dismissed');
                      showToast2.value = false;
                    },
                    onClose: () {
                      debugPrint('Close pressed');
                      showToast2.value = false;
                    },
                  )
                else
                  AquaButton.primary(
                    text: 'Show Auto Dismiss Warning',
                    onPressed: () => showToast2.value = true,
                  ),
                const SizedBox(height: 5),
                if (showToast3.value)
                  AquaToast.timed(
                    title: 'Example',
                    description: _lorem,
                    variant: AquaToastVariant.error,
                    aquaColors: theme.colors,
                    duration: const Duration(seconds: 5),
                    onDismiss: () {
                      debugPrint('Toast dismissed automatically');
                      showToast3.value = false;
                    },
                  )
                else
                  AquaButton.primary(
                    text: 'Show Auto Dismiss Error',
                    onPressed: () => showToast3.value = true,
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
