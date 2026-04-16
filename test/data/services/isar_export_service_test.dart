import 'dart:convert';
import 'dart:io';

import 'package:aqua/data/models/database/peg_order_model.dart';
import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/data/models/database/transaction_model.dart';
import 'package:aqua/data/services/isar_export_service.dart';
import 'package:aqua/features/boltz/models/db_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../helpers/isar_test_factories.dart';

File _exportFile(Directory dir) => File('${dir.path}/aqua_db_export.json');

Future<Map<String, dynamic>> _readExport(Directory dir) async =>
    jsonDecode(await _exportFile(dir).readAsString()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('encodeAndWriteExport', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('encode_write_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('writes file with correct content', () async {
      final path = '${tempDir.path}/test_export.json';
      final data = <String, dynamic>{'version': 1, 'hello': 'world'};

      await encodeAndWriteExport((path: path, data: data));

      final file = File(path);
      expect(await file.exists(), isTrue);
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(decoded['version'], 1);
      expect(decoded['hello'], 'world');
    });

    test('does not leave .tmp file behind', () async {
      final path = '${tempDir.path}/test_export.json';

      await encodeAndWriteExport((path: path, data: <String, dynamic>{'v': 1}));

      final tmp = File('$path.tmp');
      expect(await tmp.exists(), isFalse);
    });

    test('overwrites an existing file', () async {
      final path = '${tempDir.path}/test_export.json';
      await File(path).writeAsString('old content');

      await encodeAndWriteExport((path: path, data: <String, dynamic>{'v': 2}));

      final decoded =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      expect(decoded['v'], 2);
    });
  });

  group('IsarExportService.exportNow()', () {
    late Isar isar;
    late Directory tempDir;
    late IsarExportService service;

    setUp(() async {
      isar = await Isar.open(
        [
          TransactionDbModelSchema,
          SwapOrderDbModelSchema,
          BoltzSwapDbModelSchema,
          PegOrderDbModelSchema,
        ],
        directory: '',
        name: 'test_export_${DateTime.now().millisecondsSinceEpoch}',
      );

      tempDir = await Directory.systemTemp.createTemp('isar_export_test_');

      service = IsarExportService(
        isar,
        getExportDir: () async => tempDir,
      );
    });

    tearDown(() async {
      service.dispose();
      await isar.close(deleteFromDisk: true);
      await tempDir.delete(recursive: true);
    });

    test('creates the export file', () async {
      await service.exportNow();

      expect(await _exportFile(tempDir).exists(), isTrue);
    });

    test('export file is valid JSON', () async {
      await service.exportNow();

      expect(
        () => jsonDecode(_exportFile(tempDir).readAsStringSync()),
        returnsNormally,
      );
    });

    test('export has correct top-level keys', () async {
      await service.exportNow();

      final json = await _readExport(tempDir);
      expect(json, contains('version'));
      expect(json, contains('exportedAt'));
      expect(json, contains('collections'));
    });

    test('version field matches _kExportVersion', () async {
      await service.exportNow();

      final json = await _readExport(tempDir);
      expect(json['version'], equals(1));
    });

    test('exportedAt is a valid UTC ISO-8601 string', () async {
      final before = DateTime.now().toUtc();
      await service.exportNow();
      final after = DateTime.now().toUtc();

      final json = await _readExport(tempDir);
      final parsed = DateTime.parse(json['exportedAt'] as String);
      expect(
          parsed.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(parsed.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('collections object contains all 4 expected keys', () async {
      await service.exportNow();

      final collections =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      expect(collections, contains('transactions'));
      expect(collections, contains('swapOrders'));
      expect(collections, contains('boltzSwaps'));
      expect(collections, contains('pegOrders'));
    });

    test('empty collections export as empty arrays, not null', () async {
      await service.exportNow();

      final collections =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      expect(collections['transactions'], isA<List<dynamic>>());
      expect(collections['swapOrders'], isA<List<dynamic>>());
      expect(collections['boltzSwaps'], isA<List<dynamic>>());
      expect(collections['pegOrders'], isA<List<dynamic>>());
      expect(collections['transactions'] as List<dynamic>, isEmpty);
    });

    test('exported transactions contain written records', () async {
      await isar.writeTxn(() async {
        await isar.transactionDbModels.putAll([
          createTransaction(txhash: 'aaa', walletId: 'w1'),
          createTransaction(txhash: 'bbb', walletId: 'w1'),
        ]);
      });

      await service.exportNow();

      final collections =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      final txns = collections['transactions'] as List<dynamic>;
      expect(txns, hasLength(2));
      final hashes =
          txns.map((t) => (t as Map<String, dynamic>)['txhash']).toSet();
      expect(hashes, containsAll(['aaa', 'bbb']));
    });

    test('records from all collections appear in their respective keys',
        () async {
      await isar.writeTxn(() async {
        await isar.transactionDbModels
            .put(createTransaction(txhash: 'tx1', walletId: 'w1'));
        await isar.swapOrderDbModels
            .put(createSwapOrder(orderId: 'order1', walletId: 'w1'));
        await isar.pegOrderDbModels
            .put(createPegOrder(orderId: 'peg1', walletId: 'w1'));
      });

      await service.exportNow();

      final collections =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      expect(collections['transactions'] as List<dynamic>, hasLength(1));
      expect(collections['swapOrders'] as List<dynamic>, hasLength(1));
      expect(collections['pegOrders'] as List<dynamic>, hasLength(1));
    });

    test('records from multiple wallets are all exported', () async {
      await isar.writeTxn(() async {
        await isar.transactionDbModels.putAll([
          createTransaction(txhash: 'w1tx', walletId: 'wallet_1'),
          createTransaction(txhash: 'w2tx', walletId: 'wallet_2'),
        ]);
      });

      await service.exportNow();

      final collections =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      final txns = collections['transactions'] as List<dynamic>;
      final walletIds =
          txns.map((t) => (t as Map<String, dynamic>)['walletId']).toSet();
      expect(walletIds, containsAll(['wallet_1', 'wallet_2']));
    });

    test('no .tmp file remains after successful export', () async {
      await service.exportNow();

      final tmp = File('${tempDir.path}/aqua_db_export.json.tmp');
      expect(await tmp.exists(), isFalse);
    });

    test('second exportNow() overwrites the first file', () async {
      await isar.writeTxn(() async {
        await isar.transactionDbModels
            .put(createTransaction(txhash: 'first', walletId: 'w1'));
      });
      await service.exportNow();

      await isar.writeTxn(() async {
        await isar.transactionDbModels
            .put(createTransaction(txhash: 'second', walletId: 'w1'));
      });
      await service.exportNow();

      final collections =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      expect(collections['transactions'] as List<dynamic>, hasLength(2));
    });
  });

  group('IsarExportService watcher-triggered export', () {
    late Isar isar;
    late Directory tempDir;
    late IsarExportService service;

    setUp(() async {
      isar = await Isar.open(
        [
          TransactionDbModelSchema,
          SwapOrderDbModelSchema,
          BoltzSwapDbModelSchema,
          PegOrderDbModelSchema,
        ],
        directory: '',
        name: 'test_watcher_${DateTime.now().millisecondsSinceEpoch}',
      );

      tempDir = await Directory.systemTemp.createTemp('isar_watcher_test_');

      service = IsarExportService(
        isar,
        getExportDir: () async => tempDir,
        debounce: Duration.zero,
      );
      service.start();
    });

    tearDown(() async {
      service.dispose();
      await isar.close(deleteFromDisk: true);
      await tempDir.delete(recursive: true);
    });

    test('writing to a collection triggers export automatically', () async {
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'watched', walletId: 'w1'),
        );
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final collections =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      final txns = collections['transactions'] as List<dynamic>;
      expect(txns, hasLength(1));
      expect((txns.first as Map<String, dynamic>)['txhash'], 'watched');

      // Second write re-triggers the watcher and updates the export.
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'watched2', walletId: 'w1'),
        );
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final collections2 =
          (await _readExport(tempDir))['collections'] as Map<String, dynamic>;
      final txns2 = collections2['transactions'] as List<dynamic>;
      expect(txns2, hasLength(2));
      final hashes =
          txns2.map((t) => (t as Map<String, dynamic>)['txhash']).toSet();
      expect(hashes, containsAll(['watched', 'watched2']));
    });
  });
}
