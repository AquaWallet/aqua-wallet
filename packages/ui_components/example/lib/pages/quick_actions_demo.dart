import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class QuickActionsDemoPage extends HookConsumerWidget {
  const QuickActionsDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AquaQuickActionItem(
                label: 'Receive',
                foregroundColor: theme.colors.textPrimary,
                onTap: () {},
              ),
              const SizedBox(width: 52),
              AquaQuickActionItem.icon(
                label: 'Receive',
                foregroundColor: theme.colors.textPrimary,
                onTap: () {},
                icon: AquaIcon.arrowDownLeft(
                  color: theme.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              AquaQuickActionItem(
                label: 'Receive',
                foregroundColor: theme.colors.accentBrand,
                onTap: () {},
              ),
              const SizedBox(width: 52),
              AquaQuickActionItem.icon(
                label: 'Receive',
                foregroundColor: theme.colors.accentBrand,
                onTap: () {},
                icon: AquaIcon.arrowDownLeft(
                  color: theme.colors.accentBrand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            constraints: const BoxConstraints(maxWidth: 375),
            child: AquaQuickActionsGroup(
              items: [
                AquaQuickActionItem.icon(
                  label: 'Receive',
                  icon: AquaIcon.arrowDownLeft(
                    color: theme.colors.textPrimary,
                  ),
                  onTap: () {},
                ),
                AquaQuickActionItem.icon(
                  label: 'Send',
                  icon: AquaIcon.arrowUpRight(
                    color: theme.colors.textPrimary,
                  ),
                  onTap: () {},
                ),
                AquaQuickActionItem.icon(
                  label: 'Send',
                  icon: AquaIcon.scan(
                    color: theme.colors.textPrimary,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
