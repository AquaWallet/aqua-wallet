import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

const _lorem = 'lorem ipsum dolor sit amet consectetur adipiscing elit sed do';

class TopAppbarDemoPage extends HookConsumerWidget {
  const TopAppbarDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

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
                AquaHeader(
                  showNotifications: true,
                  colors: theme.colors,
                ),
                const SizedBox(height: 40),
                AquaHeader(
                  showNotifications: true,
                  walletName: 'Wallet 1',
                  walletBalance: '\$222,475.48',
                  colors: theme.colors,
                ),
                const SizedBox(height: 40),
                AquaTopAppBar(
                  title: 'Wallet',
                  colors: theme.colors,
                ),
                // AquaTopAppBar(title: 'Wallet'),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Stack(
              children: [
                Column(
                  children: [
                    for (var i = 0; i < 10; i++) ...{
                      const AquaText.body1SemiBold(text: _lorem),
                      const SizedBox(height: 10),
                    },
                  ],
                ),
                Column(
                  children: [
                    AquaHeader(
                      showNotifications: true,
                      colors: theme.colors,
                    ),
                    const SizedBox(height: 40),
                    AquaHeader(
                      showNotifications: true,
                      walletName: 'Wallet 1',
                      walletBalance: '\$222,475.48',
                      colors: theme.colors,
                    ),
                    const SizedBox(height: 40),
                    AquaTopAppBar(
                      title: 'Wallet',
                      colors: theme.colors,
                    ),
                    // AquaTopAppBar(title: 'Wallet'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
