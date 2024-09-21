import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:permission_handler/permission_handler.dart';

final exportTransactionDatabaseProvider =
    AutoDisposeAsyncNotifierProvider<_Notifier, TransactionDatabaseExportState>(
        _Notifier.new);

class _Notifier
    extends AutoDisposeAsyncNotifier<TransactionDatabaseExportState> {
  @override
  FutureOr<TransactionDatabaseExportState> build() {
    return const TransactionDatabaseExportState.idle();
  }

  void requestConfirmation() {
    state = const AsyncValue.data(
      TransactionDatabaseExportState.confirmationRequired(),
    );
  }

  Future<void> requestPermission() async {
    state = await AsyncValue.guard(() async {
      final permissionGranted =
          await Permission.manageExternalStorage.request().isGranted;
      logger.d('[Export] Permission granted: $permissionGranted');
      if (permissionGranted) {
        final backupPath = await ref.read(dataTransferProvider).export();
        return TransactionDatabaseExportState.exportSuccess(path: backupPath);
      } else {
        return const TransactionDatabaseExportState.permissionNotGranted();
      }
    });
  }

  Future<void> export() async {
    state = await AsyncValue.guard(() async {
      final permissionGranted =
          await Permission.manageExternalStorage.isGranted;
      if (!permissionGranted) {
        return const TransactionDatabaseExportState.permissionRequired();
      }
      final backupPath = await ref.read(dataTransferProvider).export();
      return TransactionDatabaseExportState.exportSuccess(path: backupPath);
    });
  }
}
