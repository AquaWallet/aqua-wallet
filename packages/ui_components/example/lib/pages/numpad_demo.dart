import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class NumpadDemoPage extends HookConsumerWidget {
  const NumpadDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(40),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 343),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaNumpad(
                  colors: theme.colors,
                  onKeyPressed: (key) {
                    debugPrint(key.toString());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 343),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaNumpad(
                  enabled: false,
                  colors: theme.colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
