import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class SeedPhraseDemoPage extends HookConsumerWidget {
  const SeedPhraseDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 343),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AquaSeedInputField(
                      index: 1,
                      colors: theme.colors,
                    ),
                    const SizedBox(height: 20),
                    AquaSeedInputField(
                      index: 1,
                      forceFocus: true,
                      controller: TextEditingController(text: 'word'),
                      colors: theme.colors,
                    ),
                    const SizedBox(height: 20),
                    AquaSeedListItem(
                      index: 1,
                      text: 'solar',
                      colors: theme.colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                constraints: const BoxConstraints(maxWidth: 343),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AquaSeedInputField(
                      index: 1,
                      isValidWord: true,
                      controller: TextEditingController(text: 'word'),
                      colors: theme.colors,
                    ),
                    const SizedBox(height: 20),
                    AquaSeedInputField(
                      index: 1,
                      forceFocus: true,
                      isValidWord: true,
                      controller: TextEditingController(text: 'word'),
                      colors: theme.colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 375),
            child: AquaSeedInputHints(
              hints: const ['table', 'tackle', 'tag', 'tool'],
              onHintSelected: (hint) {
                debugPrint('[Hint] $hint');
              },
              colors: theme.colors,
            ),
          ),
        ],
      ),
    );
  }
}
