import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';

final _logger = CustomLogger(FeatureFlag.restore);

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
            height: 400.0,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistorySheetTitle,
            message: context.loc.checkTxnHistoryBackupSheetMessage,
            confirmButtonLabel: context.loc.importTxnHistorySheetConfirmButton,
            cancelButtonLabel: context.loc.later,
            onConfirm: ref.read(provider.notifier).requestPermission,
          ),
          backupFound: () => showGenericAlertSheet(
            context: context,
            height: 380.0,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistorySheetTitle,
            message: context.loc.importTxnHistorySheetMessage,
            confirmButtonLabel: context.loc.importTxnHistorySheetRestoreButton,
            cancelButtonLabel: context.loc.later,
            onConfirm: ref.read(provider.notifier).restore,
          ),
          noBackupFound: () => showGenericAlertSheet(
            context: context,
            height: 320.0,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistoryNotFoundSheetTitle,
            message: context.loc.importTxnHistoryNotFoundSheetMessage,
            confirmButtonLabel: context.loc.okay,
          ),
          permissionNotGranted: () => showGenericAlertSheet(
            context: context,
            height: 380.0,
            isDismissible: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.permissionDenied,
            message: context.loc.importTxnHistoryPermissionDeniedSheetMessage,
            confirmButtonLabel: context.loc.requestPermission,
            cancelButtonLabel: context.loc.later,
            onConfirm: ref.read(provider.notifier).requestPermission,
          ),
          restoreSuccess: () => showGenericAlertSheet(
            context: context,
            height: 320.0,
            isDismissible: false,
            showCancelButton: false,
            svgPath: Svgs.backupWallet,
            title: context.loc.importTxnHistorySuccessSheetTitle,
            message: context.loc.importTxnHistorySuccessSheetMessage,
            confirmButtonLabel: context.loc.continueLabel,
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
            title: context.loc.importTxnHistoryErrorSheetTitle,
            message: error is ExceptionLocalized
                ? error.toLocalizedString(context)
                : context.loc.importTxnHistoryErrorSheetMessage,
            confirmButtonLabel: context.loc.okay,
          );
        },
      ),
    );
  }
}
