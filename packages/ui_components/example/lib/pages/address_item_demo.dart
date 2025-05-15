import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class AddressItemDemoPage extends HookConsumerWidget {
  const AddressItemDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final onTap = useCallback((String? address) {
      if (address == null) return;
      Clipboard.setData(ClipboardData(text: address));
      AquaTooltip.show(
        context,
        isInfo: true,
        message: 'Copied to clipboard',
        foregroundColor: theme.colors.textInverse,
        backgroundColor: theme.colors.glassInverse,
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 343),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AquaAddressItem(
              address:
                  'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2M pVq',
              copyable: true,
              colors: theme.colors,
              onTap: onTap,
            ),
            const SizedBox(height: 20),
            AquaAddressItem(
              address:
                  'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
              txnCount: 2,
              copyable: true,
              colors: theme.colors,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
