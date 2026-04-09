import 'dart:convert';
import 'dart:io';

import 'package:aqua/config/constants/pref_keys.dart';
import 'package:aqua/data/models/database/peg_order_model.dart';
import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/data/models/database/transaction_model.dart';
import 'package:aqua/data/provider/isar_database_provider.dart';
import 'package:aqua/data/provider/isar_export_provider.dart';
import 'package:aqua/data/services/isar_export_service.dart';
import 'package:aqua/features/boltz/models/db_models.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/isar_test_factories.dart';

File _exportFile(Directory dir) => File('${dir.path}/aqua_db_export.json');

ProviderContainer _makeContainer({
  required Isar isar,
  required FeatureFlagsNotifier flags,
  required Directory exportDir,
}) {
  return ProviderContainer(
    overrides: [
      storageProvider.overrideWith((ref) async => isar),
      featureFlagsProvider.overrideWith((_) => flags),
      isarExportServiceProvider.overrideWith((ref) {
        final isarAsync = ref.watch(storageProvider);
        final flagEnabled = ref
            .watch(featureFlagsProvider.select((p) => p.dbJsonExportEnabled));
        return isarAsync.whenOrNull(data: (db) {
          final service = IsarExportService(
            db,
            getExportDir: () async => exportDir,
            debounce: Duration.zero,
          );
          if (flagEnabled) service.start();
          ref.onDispose(service.dispose);
          return service;
        });
      }),
    ],
  );
}

Future<FeatureFlagsNotifier> _makeFlags(
    {bool dbJsonExportEnabled = false}) async {
  SharedPreferences.setMockInitialValues({
    PrefKeys.dbJsonExportEnabled: dbJsonExportEnabled,
  });
  final prefs = await SharedPreferences.getInstance();
  return FeatureFlagsNotifier(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_export_provider_');
    isar = await Isar.open(
      [
        TransactionDbModelSchema,
        SwapOrderDbModelSchema,
        BoltzSwapDbModelSchema,
        PegOrderDbModelSchema,
      ],
      directory: '',
      name: 'provider_test_${DateTime.now().millisecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  test('exportNow() creates file when flag is off', () async {
    final flags = await _makeFlags(dbJsonExportEnabled: false);
    final container =
        _makeContainer(isar: isar, flags: flags, exportDir: tempDir);
    addTearDown(container.dispose);

    await container.read(storageProvider.future);
    final service = container.read(isarExportServiceProvider);
    expect(service, isNotNull);
    await service!.exportNow();

    expect(await _exportFile(tempDir).exists(), isTrue);
    final json = jsonDecode(await _exportFile(tempDir).readAsString())
        as Map<String, dynamic>;
    expect(json['version'], 1);
  });

  test('exportNow() creates file when flag is on', () async {
    final flags = await _makeFlags(dbJsonExportEnabled: true);
    final container =
        _makeContainer(isar: isar, flags: flags, exportDir: tempDir);
    addTearDown(container.dispose);

    await container.read(storageProvider.future);
    final service = container.read(isarExportServiceProvider);
    expect(service, isNotNull);
    await service!.exportNow();

    expect(await _exportFile(tempDir).exists(), isTrue);
  });

  test('watcher does not fire when flag is off', () async {
    final flags = await _makeFlags(dbJsonExportEnabled: false);
    final container =
        _makeContainer(isar: isar, flags: flags, exportDir: tempDir);
    addTearDown(container.dispose);

    await container.read(storageProvider.future);
    container.read(isarExportServiceProvider);

    await isar.writeTxn(() async {
      await isar.transactionDbModels
          .put(createTransaction(txhash: 'tx1', walletId: 'w1'));
    });

    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(await _exportFile(tempDir).exists(), isFalse);
  });

  test('toggling flag on at runtime causes watcher to fire on next write',
      () async {
    final flags = await _makeFlags(dbJsonExportEnabled: false);
    final container =
        _makeContainer(isar: isar, flags: flags, exportDir: tempDir);
    addTearDown(container.dispose);

    await container.read(storageProvider.future);
    container.read(isarExportServiceProvider);

    // Confirm no export fires before toggle
    await isar.writeTxn(() async {
      await isar.transactionDbModels
          .put(createTransaction(txhash: 'before', walletId: 'w1'));
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await _exportFile(tempDir).exists(), isFalse);

    // Toggle flag on — notifyListeners() causes Riverpod to re-evaluate
    flags.toggleFeatureFlag(
      key: PrefKeys.dbJsonExportEnabled,
      currentValue: false,
    );

    // Force re-evaluation so the new service (with start()) is created
    container.read(isarExportServiceProvider);
    await Future<void>.delayed(Duration.zero);

    await isar.writeTxn(() async {
      await isar.transactionDbModels
          .put(createTransaction(txhash: 'after', walletId: 'w1'));
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(await _exportFile(tempDir).exists(), isTrue);
  });
}
