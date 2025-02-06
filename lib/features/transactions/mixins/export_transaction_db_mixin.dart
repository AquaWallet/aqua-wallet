import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

final _logger = CustomLogger(FeatureFlag.export);

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
            height: 440.0,
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
            height: 380.0,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.exportTxnHistorySheetTitle,
            message: context.loc.exportPermissionRequired,
            confirmButtonLabel: context.loc.requestPermission,
            cancelButtonLabel:
                context.loc.exportTxnHistoryPermissionDeniedSheetCancelButton,
            onConfirm: ref
                .read(exportTransactionDatabaseProvider.notifier)
                .requestPermission,
          ),
          permissionNotGranted: () => showGenericAlertSheet(
            context: context,
            height: 380.0,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.permissionDenied,
            message: context.loc.exportTxnHistoryPermissionDeniedSheetMessage,
            confirmButtonLabel: context.loc.requestPermission,
            cancelButtonLabel:
                context.loc.exportTxnHistoryPermissionDeniedSheetCancelButton,
            onConfirm: ref
                .read(exportTransactionDatabaseProvider.notifier)
                .requestPermission,
          ),
          exportSuccess: (path) => showGenericAlertSheet(
            context: context,
            height: 320.0,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.exportTxnHistorySuccessSheetTitle,
            message: context.loc.exportTxnHistorySuccessSheetMessage,
            confirmButtonLabel: context.loc.continueLabel,
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
          _logger.error('Error restoring txn backup', error, stackTrace);
          showGenericAlertSheet(
            context: context,
            height: 320.0,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.failure,
            title: context.loc.exportTxnHistoryErrorSheetTitle,
            message: error is ExceptionLocalized
                ? error.toLocalizedString(context)
                : context.loc.exportTxnHistoryErrorSheetMessage,
            confirmButtonLabel: context.loc.okay,
          );
        },
      ),
    );
  }
}
