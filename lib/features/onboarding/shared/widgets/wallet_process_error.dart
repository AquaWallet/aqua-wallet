import 'package:aqua/features/shared/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WalletProcessError extends ConsumerWidget {
  const WalletProcessError({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomAlertDialog(
      title: AppLocalizations.of(context)!.unknownErrorTitle,
      subtitle: AppLocalizations.of(context)!.unknownErrorSubtitle,
      controlWidgets: [
        Expanded(
          child: ElevatedButton(
            child: Text(AppLocalizations.of(context)!.unknownErrorButton),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
