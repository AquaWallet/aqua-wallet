import 'dart:io';
import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/data/models/database/transaction_model.dart';
import 'package:aqua/features/bip329/bip329_parsing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

part 'bip329_export_provider.g.dart';

@riverpod
class Bip329ExportNotifier extends _$Bip329ExportNotifier {
  @override
  Future<bool> build() async {
    final transactions = await ref.watch(transactionStorageProvider.future);
    final transactionsWithNotes =
        transactions.where((t) => t.note != null && t.note!.isNotEmpty);

    return transactionsWithNotes.isNotEmpty;
  }

  Future<void> exportNotes({Rect? sharePositionOrigin}) async {
    try {
      // Get transactions
      final transactions = await ref.read(transactionStorageProvider.future);

      // Export using BIP329 service
      final filePath = await _exportNotes(transactions);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Exports transaction notes in BIP329 format to a JSON file
/// Returns the path to the exported file
Future<String> _exportNotes(List<TransactionDbModel> transactions) async {
  // Export to BIP329 format using pure function
  final exportData = exportBip329Labels(transactions);

  if (exportData.isEmpty) {
    throw NoLabelsForExportError();
  }

  // Get documents directory
  final directory = await getApplicationDocumentsDirectory();
  final fileName =
      'aqua_tx_notes_${DateTime.now().millisecondsSinceEpoch}.json';
  final file = File('${directory.path}/$fileName');

  // Write to file
  await file.writeAsString(exportData);

  return file.path;
}

/// --------------------------------------------------------------------------------------------
/// Exceptions
/// --------------------------------------------------------------------------------------------
class NoLabelsForExportError implements Exception {}
