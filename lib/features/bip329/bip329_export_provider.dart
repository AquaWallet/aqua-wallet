import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/data/models/database/transaction_model.dart';
import 'package:aqua/features/bip329/bip329_label_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

part 'bip329_export_provider.g.dart';

@riverpod
class Bip329ExportNotifier extends _$Bip329ExportNotifier {
  @override
  Future<bool> build() async {
    state = const AsyncLoading();

    final transactions =
        ref.watch(transactionStorageProvider).asData?.value ?? [];
    final transactionsWithNotes =
        transactions.where((t) => t.note != null && t.note!.isNotEmpty);

    state = AsyncData(transactionsWithNotes.isNotEmpty);
    return transactionsWithNotes.isNotEmpty;
  }

  Future<void> exportNotes() async {
    try {
      // Get transactions
      final transactions = await ref.read(transactionStorageProvider.future);

      // Export using BIP329 service
      final filePath = await _exportNotes(transactions);

      // Share the file
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Exports transaction notes in BIP329 format to a JSON file
/// Returns the path to the exported file
Future<String> _exportNotes(List<TransactionDbModel> transactions) async {
  // Filter transactions to only include those with notes
  final transactionsWithNotes =
      transactions.where((t) => t.note != null && t.note!.isNotEmpty);

  // Convert to BIP329 format
  final labels = transactionsWithNotes
      .map((t) => Bip329Label(
            type: BIP329Type.tx,
            ref: t.txhash,
            label: t.note!,
          ))
      .toList();

  if (labels.isEmpty) {
    throw NoLabelsForExportError();
  }

  final exportData =
      labels.map((label) => jsonEncode(label.toJson())).join('\n');

  // Get documents directory
  final directory = await getApplicationDocumentsDirectory();
  final fileName =
      'aqua_tx_notes_${DateTime.now().millisecondsSinceEpoch}.json';
  final file = File('${directory.path}/$fileName');

  // Write to file with pretty printing
  await file.writeAsString(
    exportData,
  );

  return file.path;
}

/// --------------------------------------------------------------------------------------------
/// Exceptions
/// --------------------------------------------------------------------------------------------
class NoLabelsForExportError implements Exception {}
