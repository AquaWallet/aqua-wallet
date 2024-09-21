import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

mixin RestoreTransactionMixin<T extends Widget> on HookConsumerWidget {
  void listenToRestoreTransactionHistoryEvents(
    BuildContext context,
    WidgetRef ref, {
    bool useExperimentalProvider = false,
  }) {
    final provider = useExperimentalProvider
        ? experimentalRestoreTransactionsProvider
        : restoreTransactionDatabaseBackupProvider;
    ref.listen(
      provider,
      (_, value) => value.whenOrNull(
        data: (data) => data.whenOrNull(
          permissionRequired: () => showGenericAlertSheet(
            context: context,
            height: 400.h,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistorySheetTitle,
            message: context.loc.checkTxnHistoryBackupSheetMessage,
            confirmButtonLabel: context.loc.importTxnHistorySheetConfirmButton,
            cancelButtonLabel: context.loc.importTxnHistorySheetCancelButton,
            onConfirm: ref.read(provider.notifier).requestPermission,
          ),
          backupFound: () => showGenericAlertSheet(
            context: context,
            height: 380.h,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistorySheetTitle,
            message: context.loc.importTxnHistorySheetMessage,
            confirmButtonLabel: context.loc.importTxnHistorySheetRestoreButton,
            cancelButtonLabel: context.loc.importTxnHistorySheetCancelButton,
            onConfirm: ref.read(provider.notifier).restore,
          ),
          noBackupFound: () => showGenericAlertSheet(
            context: context,
            height: 320.h,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistoryNotFoundSheetTitle,
            message: context.loc.importTxnHistoryNotFoundSheetMessage,
            confirmButtonLabel: context.loc.okay,
          ),
          permissionNotGranted: () => showGenericAlertSheet(
            context: context,
            height: 380.h,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistoryPermissionDeniedSheetTitle,
            message: context.loc.importTxnHistoryPermissionDeniedSheetMessage,
            confirmButtonLabel:
                context.loc.importTxnHistoryPermissionDeniedSheetConfirmButton,
            cancelButtonLabel:
                context.loc.importTxnHistoryPermissionDeniedSheetCancelButton,
            onConfirm: ref.read(provider.notifier).requestPermission,
          ),
          restoreSuccess: () => showGenericAlertSheet(
            context: context,
            height: 320.h,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistorySuccessSheetTitle,
            message: context.loc.importTxnHistorySuccessSheetMessage,
            confirmButtonLabel:
                context.loc.importTxnHistorySuccessSheetConfirmButton,
          ),
        ),
        error: (error, stackTrace) {
          logger.e('[Restore] Error restoring txn backup', error, stackTrace);
          showGenericAlertSheet(
            context: context,
            height: 320.h,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.failure,
            title: context.loc.importTxnHistoryErrorSheetTitle,
            message: error is ErrorLocalized
                ? error.toLocalizedString(context)
                : context.loc.importTxnHistoryErrorSheetMessage,
            confirmButtonLabel: context.loc.okay,
          );
        },
      ),
    );
  }
}
