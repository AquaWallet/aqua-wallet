import 'dart:convert';

import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:pointycastle/api.dart';

const _kExportFileNamePrefix = 'aqua-export-';

final dataTransferProvider =
    Provider<DataTransferService>(_DataTransferService.new);

class AquaDataTransferFileNotFoundError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.exportTxnErrorFileNotFound;
}

class AquaDataTransferInvalidImportKeyError extends ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.exportTxnErrorInvalidImportKey;
}

abstract class DataTransferService {
  static const String keyTransactions = 'transactions';
  static const String keySideshiftOrders = 'sideshiftOrders';
  static const String keyBoltzSwaps = 'boltzSwaps';

  Future<bool> isExportFileExist();
  Future<String> export();
  Future<Map<String, dynamic>> import();
}

class _DataTransferService implements DataTransferService {
  const _DataTransferService(this.ref);

  final Ref ref;

  @override
  Future<String> export() async {
    // Serialize transactions to JSON
    final transactions = await ref.read(transactionStorageProvider.future);
    final sideshiftOrders = await ref.read(sideshiftStorageProvider.future);
    final boltzSwaps = await ref.read(boltzStorageProvider.future);
    final map = {
      DataTransferService.keyTransactions:
          transactions.map((e) => e.toJson()).toList(),
      DataTransferService.keySideshiftOrders:
          sideshiftOrders.map((e) => e.toJson()).toList(),
      DataTransferService.keyBoltzSwaps:
          boltzSwaps.map((e) => e.toJson()).toList(),
    };
    final jsonString = jsonEncode(map);

    // Encrypt the JSON string
    final encrypter = await ref.read(encryptionProvider.future);
    final encrypted = encrypter.encrypt(jsonString);

    // Write the encrypted data to a file
    final date = DateTime.now().toIso8601String().split('T').first;
    final fileName = '$_kExportFileNamePrefix$date';
    return ref
        .read(fileSystemProvider)
        .writeToDocuments(encrypted, fileName: fileName);
  }

  @override
  Future<Map<String, dynamic>> import() async {
    try {
      final filename = await ref
          .read(fileSystemProvider)
          .findFileInDocuments(query: _kExportFileNamePrefix);

      if (filename == null) {
        throw Exception('Export file not found');
      }

      final encrypted = await ref
          .read(fileSystemProvider)
          .readFromDocuments(filePath: filename);

      final encrypter = await ref.read(encryptionProvider.future);
      final decrypted = encrypter.decrypt(encrypted);

      final map = jsonDecode(decrypted) as Map<String, dynamic>;

      final transactionItems = map[DataTransferService.keyTransactions] as List;
      transactionItems
          .cast<Map<String, dynamic>>()
          .map(TransactionDbModel.fromJson)
          .forEach(ref.read(transactionStorageProvider.notifier).save);

      final sideshiftItems =
          map[DataTransferService.keySideshiftOrders] as List;
      sideshiftItems
          .cast<Map<String, dynamic>>()
          .map(SideshiftOrderDbModel.fromJson)
          .forEach(ref.read(sideshiftStorageProvider.notifier).save);

      final boltzItems = map[DataTransferService.keyBoltzSwaps] as List;
      boltzItems
          .cast<Map<String, dynamic>>()
          .map(BoltzSwapDbModel.fromJson)
          .forEach(ref.read(boltzStorageProvider.notifier).save);

      return map;
    } on ArgumentError catch (e) {
      logger.e(
        '[DataTransfer] Failed to decrypt: ${e.message}. '
        'Likely caused by an invalid import key',
        e,
        StackTrace.current,
      );
      throw AquaDataTransferInvalidImportKeyError();
    } on InvalidCipherTextException catch (e) {
      logger.e(
        '[DataTransfer] Failed to decrypt: ${e.message}. '
        'Likely caused by an invalid import key or corrupted data',
        e,
        StackTrace.current,
      );
      throw AquaDataTransferInvalidImportKeyError();
    } catch (e) {
      logger.e('[DataTransfer] Failed to decrypt: $e', e, StackTrace.current);
      rethrow;
    }
  }

  @override
  Future<bool> isExportFileExist() async {
    final filename = await ref
        .read(fileSystemProvider)
        .findFileInDocuments(query: _kExportFileNamePrefix);
    return filename != null;
  }
}
