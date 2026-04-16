import 'dart:convert';
import 'dart:io';

import 'package:aqua/data/models/database/transaction_model.dart';
import 'package:aqua/features/bip329/bip329_label_model.dart';
import 'package:aqua/features/bip329/bip329_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBip329Labels', () {
    test('should parse valid tx labels from fixture', () async {
      final fixtureFile = File('test/fixtures/bip329/valid_tx_labels.json');
      final content = await fixtureFile.readAsString();

      final labels = parseBip329Labels(content);

      expect(labels.length, 2);
      expect(labels[0].type, BIP329Type.tx);
      expect(labels[0].ref, 'txhash1');
      expect(labels[0].label, 'Note 1');
      expect(labels[1].type, BIP329Type.tx);
      expect(labels[1].ref, 'txhash2');
      expect(labels[1].label, 'Note 2');
    });

    test('should filter out non-tx types', () async {
      final fixtureFile = File('test/fixtures/bip329/mixed_types.json');
      final content = await fixtureFile.readAsString();

      final labels = parseBip329Labels(content);

      expect(labels.length, 1);
      expect(labels[0].type, BIP329Type.tx);
      expect(labels[0].ref, 'txhash1');
      expect(labels[0].label, 'Tx Note');
    });

    test('should return empty list when no tx labels found', () async {
      final fixtureFile = File('test/fixtures/bip329/only_non_tx.json');
      final content = await fixtureFile.readAsString();

      final labels = parseBip329Labels(content);

      expect(labels.isEmpty, true);
    });

    test('should filter out null or empty label values', () async {
      final fixtureFile = File('test/fixtures/bip329/mixed_validity.json');
      final content = await fixtureFile.readAsString();

      final labels = parseBip329Labels(content);

      expect(labels.length, 1);
      expect(labels[0].ref, 'txhash1');
      expect(labels[0].label, 'Valid Note');
    });

    test('should return empty list for empty content', () {
      final labels = parseBip329Labels('');
      expect(labels.isEmpty, true);
    });

    test('should handle multi-wallet fixture', () async {
      final fixtureFile = File('test/fixtures/bip329/multiwallet_import.json');
      final content = await fixtureFile.readAsString();

      final labels = parseBip329Labels(content);

      expect(labels.length, 2);
      expect(labels.any((l) => l.ref == 'current_tx'), true);
      expect(labels.any((l) => l.ref == 'other_tx'), true);
    });

    test('should handle unknown txhash fixture', () async {
      final fixtureFile = File('test/fixtures/bip329/unknown_txhash.json');
      final content = await fixtureFile.readAsString();

      final labels = parseBip329Labels(content);

      expect(labels.length, 2);
      expect(labels.any((l) => l.ref == 'known_tx'), true);
      expect(labels.any((l) => l.ref == 'unknown_tx'), true);
    });

    test('should throw FormatException for invalid JSON', () {
      const invalidJson =
          '{"type":"tx","ref":"tx1","label":"Note"}\ninvalid json';

      expect(() => parseBip329Labels(invalidJson), throwsFormatException);
    });
  });

  group('exportBip329Labels', () {
    test('should export transactions with notes to BIP329 format', () {
      final transactions = [
        const TransactionDbModel(
          txhash: 'txhash1',
          note: 'Note 1',
          assetId: 'btc',
        ),
        const TransactionDbModel(
          txhash: 'txhash2',
          note: 'Note 2',
          assetId: 'btc',
        ),
      ];

      final result = exportBip329Labels(transactions);

      expect(result.isNotEmpty, true);

      final lines = result.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, 2);

      final json1 = jsonDecode(lines[0]);
      expect(json1['type'], 'tx');
      expect(json1['ref'], 'txhash1');
      expect(json1['label'], 'Note 1');

      final json2 = jsonDecode(lines[1]);
      expect(json2['type'], 'tx');
      expect(json2['ref'], 'txhash2');
      expect(json2['label'], 'Note 2');
    });

    test('should filter out transactions without notes', () {
      final transactions = [
        const TransactionDbModel(
          txhash: 'txhash1',
          note: 'Has Note',
          assetId: 'btc',
        ),
        const TransactionDbModel(
          txhash: 'txhash2',
          assetId: 'btc',
        ),
        const TransactionDbModel(
          txhash: 'txhash3',
          note: '',
          assetId: 'btc',
        ),
      ];

      final result = exportBip329Labels(transactions);

      final lines = result.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, 1);

      final json = jsonDecode(lines[0]);
      expect(json['ref'], 'txhash1');
      expect(json['label'], 'Has Note');
    });

    test('should return empty string when no transactions have notes', () {
      final transactions = [
        const TransactionDbModel(txhash: 'txhash1', assetId: 'btc'),
        const TransactionDbModel(txhash: 'txhash2', note: '', assetId: 'btc'),
      ];

      final result = exportBip329Labels(transactions);

      expect(result.isEmpty, true);
    });

    test('should handle empty transaction list', () {
      final result = exportBip329Labels([]);
      expect(result.isEmpty, true);
    });

    test('should maintain order of transactions', () {
      final transactions = [
        const TransactionDbModel(txhash: 'tx1', note: 'First', assetId: 'btc'),
        const TransactionDbModel(txhash: 'tx2', note: 'Second', assetId: 'btc'),
        const TransactionDbModel(txhash: 'tx3', note: 'Third', assetId: 'btc'),
      ];

      final result = exportBip329Labels(transactions);
      final lines = result.split('\n').where((l) => l.isNotEmpty).toList();

      expect(lines.length, 3);
      expect(jsonDecode(lines[0])['ref'], 'tx1');
      expect(jsonDecode(lines[1])['ref'], 'tx2');
      expect(jsonDecode(lines[2])['ref'], 'tx3');
    });
  });
}
