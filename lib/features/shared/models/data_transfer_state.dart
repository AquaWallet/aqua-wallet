import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_transfer_state.freezed.dart';

@freezed
class TransactionDatabaseExportState with _$TransactionDatabaseExportState {
  const factory TransactionDatabaseExportState.idle() = TxnDbExportStateIdle;
  const factory TransactionDatabaseExportState.confirmationRequired() =
      TxnDbExportStateConfirmationRequired;
  const factory TransactionDatabaseExportState.permissionRequired() =
      TxnDbExportStatePermissionRequired;
  const factory TransactionDatabaseExportState.permissionNotGranted() =
      TxnDbExportStatePermissionNotGranted;
  const factory TransactionDatabaseExportState.exportSuccess({
    required String path,
  }) = TxnDbExportStateSuccess;
}

@freezed
class TransactionDatabaseImportState with _$TransactionDatabaseImportState {
  const factory TransactionDatabaseImportState.idle() = TxnDbImportStateIdle;
  const factory TransactionDatabaseImportState.backupFound() =
      TxnDbImportStateBackupFound;
  const factory TransactionDatabaseImportState.noBackupFound() =
      TxnDbImportStateNoBackupFound;
  const factory TransactionDatabaseImportState.permissionRequired() =
      TxnDbImportStatePermissionRequired;
  const factory TransactionDatabaseImportState.permissionNotGranted() =
      TxnDbImportStatePermissionNotGranted;
  const factory TransactionDatabaseImportState.restoreSuccess() =
      TxnDbImportStateSuccess;
}
