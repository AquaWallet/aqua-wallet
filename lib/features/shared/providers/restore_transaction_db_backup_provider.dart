import 'dart:async';

import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:permission_handler/permission_handler.dart';

final restoreTransactionDatabaseBackupProvider =
    AutoDisposeAsyncNotifierProvider<_Notifier, TransactionDatabaseImportState>(
        _Notifier.new);

// NOTE: Lacks initial state updates for testing on experimental features screen
final experimentalRestoreTransactionsProvider =
    AutoDisposeAsyncNotifierProvider<_ExperimentalNotifier,
        TransactionDatabaseImportState>(_ExperimentalNotifier.new);

class _Notifier
    extends AutoDisposeAsyncNotifier<TransactionDatabaseImportState> {
  @override
  FutureOr<TransactionDatabaseImportState> build() async {
    final isEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.dbExportEnabled));
    if (!isEnabled) {
      logger.d('[Restore] Skipping import flow, feature flag is disabled');
      return const TransactionDatabaseImportState.idle();
    }

    // Allow the app settle down before prompting
    await Future.delayed(const Duration(seconds: 5));
    final shouldPrompt = !ref.read(prefsProvider).isTxnDatabaseRestoreReminded;
    logger.d('[Restore] Should prompt: $shouldPrompt');
    if (shouldPrompt) {
      final allowed = await Permission.manageExternalStorage.isGranted;
      logger.d('[Restore] Permission granted: $allowed');
      if (!allowed) {
        return const TransactionDatabaseImportState.permissionRequired();
      }
      final exists = await ref.read(dataTransferProvider).isExportFileExist();
      logger.d('[Restore] Backup file exists: $exists');
      if (exists) {
        return const TransactionDatabaseImportState.backupFound();
      }
    }
    return const TransactionDatabaseImportState.idle();
  }

  Future<void> requestPermission() async {
    state = await AsyncValue.guard(() async {
      final permissionGranted =
          await Permission.manageExternalStorage.request().isGranted;
      logger.d('[Restore] Permission granted: $permissionGranted');
      if (permissionGranted) {
        final exists = await ref.read(dataTransferProvider).isExportFileExist();
        logger.d('[Restore] Backup file exists: $exists');
        return exists
            ? const TransactionDatabaseImportState.backupFound()
            : const TransactionDatabaseImportState.noBackupFound();
      } else {
        ref.read(prefsProvider).disableTxnDatabaseRestoreReminder();
        return const TransactionDatabaseImportState.permissionNotGranted();
      }
    });
  }

  Future<void> restore() async {
    state = await AsyncValue.guard(() async {
      final result = await ref.read(dataTransferProvider).import();
      final count = result.entries.expand((e) => e.value).length;
      logger.d('[Restore] Imported $count items');
      ref.read(prefsProvider).disableTxnDatabaseRestoreReminder();
      return const TransactionDatabaseImportState.restoreSuccess();
    });
  }
}

class _ExperimentalNotifier extends _Notifier {
  @override
  FutureOr<TransactionDatabaseImportState> build() async {
    return const TransactionDatabaseImportState.idle();
  }

  Future<void> checkForStatus() async {
    state = await AsyncValue.guard(() async {
      final allowed = await Permission.manageExternalStorage.isGranted;
      logger.d('[Restore][Exp] Permission granted: $allowed');
      if (!allowed) {
        return const TransactionDatabaseImportState.permissionRequired();
      }
      final exists = await ref.read(dataTransferProvider).isExportFileExist();
      logger.d('[Restore][Exp] Backup file exists: $exists');
      return exists
          ? const TransactionDatabaseImportState.backupFound()
          : const TransactionDatabaseImportState.noBackupFound();
    });
  }
}
