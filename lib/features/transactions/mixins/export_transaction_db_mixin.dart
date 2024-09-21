import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

mixin ExportTransactionMixin<T extends Widget> on HookConsumerWidget {
  void listenToExportTransactionHistoryEvents(
    BuildContext context,
    WidgetRef ref, {
    bool removeWallet = false,
  }) {
    ref.listen(
      exportTransactionDatabaseProvider,
      (_, value) => value.whenOrNull(
        data: (data) => data.whenOrNull(
          confirmationRequired: () => showGenericAlertSheet(
            context: context,
            height: 440.h,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.exportTxnHistorySheetTitle,
            message: context.loc.exportTxnHistorySheetMessage,
            confirmButtonLabel: context.loc.exportTxnHistorySheetConfirmButton,
            cancelButtonLabel: context.loc.exportTxnHistorySheetCancelButton,
            onConfirm:
                ref.read(exportTransactionDatabaseProvider.notifier).export,
            onCancel: () {
              if (removeWallet) {
                ref
                    .read(walletRemoveRequestProvider.notifier)
                    .requestWalletRemove();
              }
            },
          ),
          permissionRequired: () => showGenericAlertSheet(
            context: context,
            height: 380.h,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.exportTxnHistorySheetTitle,
            message: context.loc.exportPermissionRequired,
            confirmButtonLabel:
                context.loc.exportTxnHistoryPermissionDeniedSheetConfirmButton,
            cancelButtonLabel:
                context.loc.exportTxnHistoryPermissionDeniedSheetCancelButton,
            onConfirm: ref
                .read(exportTransactionDatabaseProvider.notifier)
                .requestPermission,
          ),
          permissionNotGranted: () => showGenericAlertSheet(
            context: context,
            height: 380.h,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.exportTxnHistoryPermissionDeniedSheetTitle,
            message: context.loc.exportTxnHistoryPermissionDeniedSheetMessage,
            confirmButtonLabel:
                context.loc.exportTxnHistoryPermissionDeniedSheetConfirmButton,
            cancelButtonLabel:
                context.loc.exportTxnHistoryPermissionDeniedSheetCancelButton,
            onConfirm: ref
                .read(exportTransactionDatabaseProvider.notifier)
                .requestPermission,
          ),
          exportSuccess: (path) => showGenericAlertSheet(
            context: context,
            height: 320.h,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.exportTxnHistorySuccessSheetTitle,
            message: context.loc.exportTxnHistorySuccessSheetMessage,
            confirmButtonLabel:
                context.loc.exportTxnHistorySuccessSheetConfirmButton,
            onConfirm: () {
              if (removeWallet) {
                ref
                    .read(walletRemoveRequestProvider.notifier)
                    .requestWalletRemove();
              }
            },
          ),
        ),
        error: (error, stackTrace) {
          logger.e('[Export] Error restoring txn backup', error, stackTrace);
          showGenericAlertSheet(
            context: context,
            height: 320.h,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.failure,
            title: context.loc.exportTxnHistoryErrorSheetTitle,
            message: error is ErrorLocalized
                ? error.toLocalizedString(context)
                : context.loc.exportTxnHistoryErrorSheetMessage,
            confirmButtonLabel: context.loc.okay,
          );
        },
      ),
    );
  }
}
