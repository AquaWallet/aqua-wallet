import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components_playground/models/models.dart';
import 'package:ui_components_playground/providers/providers.dart';
import 'package:ui_components_playground/shared/shared.dart';

class AquaAppBar extends HookConsumerWidget implements PreferredSizeWidget {
  const AquaAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return Container(
      height: 120,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(prefsProvider.notifier).switchTheme(switch (theme) {
                    AppTheme.light => AppTheme.dark,
                    AppTheme.dark => AppTheme.deepOcean,
                    AppTheme.deepOcean => AppTheme.light,
                  });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: context.colorScheme.surfaceContainerHighest,
            ),
            label: Text(theme.name),
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
