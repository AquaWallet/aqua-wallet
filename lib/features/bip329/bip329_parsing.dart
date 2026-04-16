import 'dart:convert';

import 'package:aqua/data/models/database/transaction_model.dart';
import 'package:aqua/features/bip329/bip329_label_model.dart';

/// Parses BIP329 JSON content and returns transaction labels only
///
/// Each line should be a separate JSON object in BIP329 format.
/// Only labels with type 'tx' and non-null, non-empty labels are returned.
List<Bip329Label> parseBip329Labels(String content) {
  if (content.isEmpty) {
    return [];
  }

  return content
      .split('\n')
      .where((line) => line.isNotEmpty)
      .map((line) => Bip329Label.fromJson(jsonDecode(line)))
      .where((label) =>
          label.type == BIP329Type.tx &&
          label.label != null &&
          label.label!.isNotEmpty)
      .toList();
}

/// Exports transactions with notes to BIP329 format
///
/// Returns a multi-line JSON string where each line is a BIP329 label.
/// Only transactions with non-null, non-empty notes are included.
String exportBip329Labels(List<TransactionDbModel> transactions) {
  final labels = transactions
      .where((t) => t.note != null && t.note!.isNotEmpty)
      .map((t) => Bip329Label(
            type: BIP329Type.tx,
            ref: t.txhash,
            label: t.note!,
          ));

  return labels.map((l) => jsonEncode(l.toJson())).join('\n');
}
