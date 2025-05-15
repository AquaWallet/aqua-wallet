import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/bip329/bip329_label_model.dart';

part 'bip329_import_provider.g.dart';

@riverpod
class Bip329ImportNotifier extends _$Bip329ImportNotifier {
  @override
  Future<void> build() async {}

  Future<void> importNotes() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final fileContent = await file.readAsString();
        final labels = LineSplitter.split(fileContent)
            .map((line) => Bip329Label.fromJson(jsonDecode(line)))
            .where(
                (label) => label.type == BIP329Type.tx && label.label != null);

        if (labels.isEmpty) {
          throw NoLabelsForImportError();
        }

        for (final label in labels) {
          await ref
              .read(transactionStorageProvider.notifier)
              .updateTransactionNote(
                txHash: label.ref,
                note: label.label!,
              );
        }
      } else {
        // User canceled the picker
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// --------------------------------------------------------------------------------------------
/// Exceptions
/// --------------------------------------------------------------------------------------------
class NoLabelsForImportError implements Exception {}
