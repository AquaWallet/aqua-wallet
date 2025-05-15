import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class NotificationItemDemoPage extends HookConsumerWidget {
  const NotificationItemDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 343),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AquaNotificationItem(
              colors: theme.colors,
              icon: AquaIcon.arrowDownLeft(
                size: 18,
                color: theme.colors.textSecondary,
              ),
              title: 'Notification Title',
              subtitle: 'Notification copy goes here',
              timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
              onTap: () => debugPrint('Notification tapped'),
            ),
            const SizedBox(height: 20),
            AquaNotificationItem(
              isRead: true,
              colors: theme.colors,
              icon: AquaIcon.arrowDownLeft(
                size: 18,
                color: theme.colors.textSecondary,
              ),
              title: 'Notification Title',
              subtitle: 'Notification copy goes here',
              timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
              onTap: () => debugPrint('Notification tapped'),
            ),
          ],
        ),
      ),
    );
  }
}
