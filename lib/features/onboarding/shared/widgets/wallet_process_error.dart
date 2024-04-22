import 'package:aqua/features/shared/widgets/custom_alert_dialog.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WalletProcessError extends ConsumerWidget {
  const WalletProcessError({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomAlertDialog(
      title: context.loc.unknownErrorTitle,
      subtitle: context.loc.unknownErrorSubtitle,
      controlWidgets: [
        Expanded(
          child: ElevatedButton(
            child: Text(context.loc.unknownErrorButton),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
