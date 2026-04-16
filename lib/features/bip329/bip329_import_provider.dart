import 'dart:io';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/bip329/bip329_parsing.dart';
import 'package:aqua/features/shared/providers/current_wallet_provider.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bip329_import_provider.g.dart';

/// Provider for FilePicker - can be overridden in tests
final filePickerProvider = Provider<FilePicker?>((ref) => FilePicker.platform);

@riverpod
class Bip329ImportNotifier extends _$Bip329ImportNotifier {
  @override
  Future<void> build() async {}

  Future<int> importNotes({FilePicker? filePicker}) async {
    int importedCount = 0;
    try {
      final picker = filePicker ?? ref.read(filePickerProvider);
      if (picker == null) {
        throw Exception('FilePicker not available');
      }
      FilePickerResult? result = await picker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final fileContent = await file.readAsString();
        final labels = parseBip329Labels(fileContent);

        if (labels.isEmpty) {
          throw NoLabelsForImportError();
        }

        final storage = await ref.read(storageProvider.future);
        final walletId = await ref.read(currentWalletIdOrThrowProvider.future);

        for (final label in labels) {
          // Check if transaction exists in DB
          final existingTxn = await storage.transactionDbModels
              .filter()
              .walletIdEqualTo(walletId)
              .txhashEqualTo(label.ref)
              .findFirst();

          if (existingTxn != null) {
            // In DB - just update note
            await ref
                .read(transactionStorageProvider.notifier)
                .updateTransactionNote(
                  txHash: label.ref,
                  note: label.label!,
                );
            importedCount++;
            continue;
          }

          // Not in DB - check network transactions
          final networkTxn = await _findNetworkTransaction(label.ref);
          if (networkTxn != null) {
            // Found in network - create minimal record then add note
            await ref
                .read(transactionStorageProvider.notifier)
                .findOrCreateTransaction(txHash: label.ref);
            await ref
                .read(transactionStorageProvider.notifier)
                .updateTransactionNote(
                  txHash: label.ref,
                  note: label.label!,
                );
            importedCount++;
            continue;
          }

          // Not found anywhere - skip this label
        }
      } else {
        // User canceled the picker
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
    return importedCount;
  }

  /// Searches for a transaction by hash in both Liquid and Bitcoin networks
  Future<GdkTransaction?> _findNetworkTransaction(String txHash) async {
    // Check Liquid first
    final liquidTxs = await ref.read(liquidProvider).getTransactions() ?? [];
    final liquidMatch = liquidTxs.firstWhereOrNull((t) => t.txhash == txHash);
    if (liquidMatch != null) return liquidMatch;

    // Check Bitcoin
    final btcTxs = await ref.read(bitcoinProvider).getTransactions() ?? [];
    return btcTxs.firstWhereOrNull((t) => t.txhash == txHash);
  }
}

/// --------------------------------------------------------------------------------------------
/// Exceptions
/// --------------------------------------------------------------------------------------------
class NoLabelsForImportError implements Exception {}
