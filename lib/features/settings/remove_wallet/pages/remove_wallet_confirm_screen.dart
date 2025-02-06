import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/backup/providers/backup_reminder_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:restart_app/restart_app.dart';

class RemoveWalletConfirmScreen extends HookConsumerWidget {
  static const routeName = '/removeWalletConfirmScreen';

  const RemoveWalletConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final removeWalletState = ref.watch(walletRemoveRequestProvider);

    ref.listen(
      walletRemoveRequestProvider,
      (_, state) => state.maybeWhen(
        success: () async {
          await ref.read(backupReminderProvider).clear();
          Restart.restartApp();
          return null;
        },
        failure: () => context.showErrorSnackbar(
          context.loc.removeWalletScreenRemoveFailed,
        ),
        verificationFailed: () => context.showErrorSnackbar(
          context.loc.verificationFailed,
        ),
        orElse: () => null,
      ),
    );

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
      ),
      body: SafeArea(
        child: removeWalletState.maybeWhen(
          removing: () => const Center(child: CircularProgressIndicator()),
          orElse: () => const _ConfirmationView(),
        ),
      ),
    );
  }
}

class _ConfirmationView extends HookConsumerWidget with ExportTransactionMixin {
  const _ConfirmationView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDatabaseExportEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.dbExportEnabled));

    listenToExportTransactionHistoryEvents(context, ref, removeWallet: true);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          const SizedBox(height: 60.0),
          const Spacer(),
          //ANCHOR - Icon
          SvgPicture.asset(
            Svgs.failure,
            width: 60.0,
            height: 60.0,
          ),
          const SizedBox(height: 20.0),
          //ANCHOR - Title
          Text(
            context.loc.removeWalletScreenTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.0,
                ),
          ),
          const SizedBox(height: 12.0),
          //ANCHOR - Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              context.loc.removeWalletScreenDesc,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colors.onBackground,
                  ),
            ),
          ),
          const Spacer(),
          //ANCHOR - Cancel button
          AquaElevatedButton(
            child: Text(
              context.loc.cancel,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 27.0),
          //ANCHOR - Confirm button
          AquaElevatedButton(
            onPressed: isDatabaseExportEnabled
                ? ref
                    .read(exportTransactionDatabaseProvider.notifier)
                    .requestConfirmation
                : ref
                    .read(walletRemoveRequestProvider.notifier)
                    .requestWalletRemove,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(
              context.loc.removeWalletScreenConfirmButton,
            ),
          ),
          const SizedBox(height: 64.0),
        ],
      ),
    );
  }
}
