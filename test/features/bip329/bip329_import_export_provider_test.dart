import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/bip329/bip329_export_provider.dart';
import 'package:aqua/features/bip329/bip329_import_provider.dart';
import 'package:aqua/features/transactions/exceptions/transaction_exceptions.dart';
import 'package:aqua/features/transactions/providers/transactions_storage_provider.dart';
import 'package:aqua/features/shared/providers/current_wallet_provider.dart';

import '../../helpers/isar_test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FileType.any);
    registerFallbackValue(PlatformFile(path: 'test', name: 'test', size: 0));
  });

  group('BIP329 Import Provider Integration', () {
    late Isar isar;
    late ProviderContainer container;
    late MockFilePicker mockFilePicker;
    late MockStorage mockStorage;
    late Directory tempDir;

    const testWalletId = 'test_wallet_123';

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bip329_import_test_');
      isar = await Isar.open(
        [TransactionDbModelSchema],
        directory: tempDir.path,
        name: 'test',
      );

      mockFilePicker = MockFilePicker();
      mockStorage = MockStorage();

      when(() => mockStorage.get(StorageKeys.currentWalletId))
          .thenAnswer((_) async => (testWalletId, null));

      container = ProviderContainer(
        overrides: [
          storageProvider.overrideWith((ref) async => isar),
          secureStorageProvider.overrideWithValue(mockStorage),
          filePickerProvider.overrideWithValue(mockFilePicker),
          liquidProvider.overrideWithValue(MockLiquidProvider()),
          bitcoinProvider.overrideWithValue(MockBitcoinProvider()),
          currentWalletIdOrThrowProvider
              .overrideWith((ref) async => testWalletId),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await isar.close();
      await tempDir.delete(recursive: true);
    });

    test('should import tx labels successfully', () async {
      // Arrange: Pre-populate database with transactions
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'txhash1', walletId: testWalletId),
        );
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'txhash2', walletId: testWalletId),
        );
      });

      // Arrange: Mock file picker with fixture file
      when(() => mockFilePicker.pickFiles(
            allowMultiple: any(named: 'allowMultiple'),
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
          )).thenAnswer((_) async => FilePickerResult([
            PlatformFile(
              path: 'test/fixtures/bip329/valid_tx_labels.json',
              name: 'valid_tx_labels.json',
              size: 100,
            ),
          ]));

      // Act
      final notifier = container.read(bip329ImportNotifierProvider.notifier);
      await notifier.importNotes();

      // Assert: Verify notes were imported
      final tx1 = await isar.transactionDbModels
          .filter()
          .txhashEqualTo('txhash1')
          .findFirst();
      final tx2 = await isar.transactionDbModels
          .filter()
          .txhashEqualTo('txhash2')
          .findFirst();

      expect(tx1?.note, 'Note 1');
      expect(tx2?.note, 'Note 2');
    });

    test('should skip labels for transactions not found in DB or network',
        () async {
      // Arrange: Pre-populate database with only one transaction
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'txhash1', walletId: testWalletId),
        );
      });

      // Arrange: Mock file picker with fixture file (has txhash1 and txhash2)
      when(() => mockFilePicker.pickFiles(
            allowMultiple: any(named: 'allowMultiple'),
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
          )).thenAnswer((_) async => FilePickerResult([
            PlatformFile(
              path: 'test/fixtures/bip329/valid_tx_labels.json',
              name: 'valid_tx_labels.json',
              size: 100,
            ),
          ]));

      // Act
      final notifier = container.read(bip329ImportNotifierProvider.notifier);
      await notifier.importNotes();

      // Assert: Verify only existing transaction got the note
      // txhash1 exists in DB -> note imported
      // txhash2 not in DB and network providers return empty -> skipped
      final tx1 = await isar.transactionDbModels
          .filter()
          .txhashEqualTo('txhash1')
          .findFirst();
      final tx2 = await isar.transactionDbModels
          .filter()
          .txhashEqualTo('txhash2')
          .findFirst();

      expect(tx1?.note, 'Note 1');
      expect(tx2, isNull); // txhash2 skipped - not found in DB or network
    });
  });

  group('BIP329 Export Provider Integration', () {
    late Isar isar;
    late ProviderContainer container;
    late MockStorage mockStorage;
    late Directory tempDir;

    const testWalletId = 'test_wallet_123';

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bip329_export_test_');
      isar = await Isar.open(
        [TransactionDbModelSchema],
        directory: tempDir.path,
        name: 'test',
      );

      mockStorage = MockStorage();

      when(() => mockStorage.get(StorageKeys.currentWalletId))
          .thenAnswer((_) async => (testWalletId, null));

      container = ProviderContainer(
        overrides: [
          storageProvider.overrideWith((ref) async => isar),
          secureStorageProvider.overrideWithValue(mockStorage),
          currentWalletIdOrThrowProvider
              .overrideWith((ref) async => testWalletId),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await isar.close();
      await tempDir.delete(recursive: true);
    });

    test('should build with true when transactions have notes', () async {
      // Arrange: Create transactions with notes
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'txhash1', walletId: testWalletId)
              .copyWith(note: 'Note 1'),
        );
      });

      // Re-read to trigger provider rebuild
      container.invalidate(transactionStorageProvider);

      // Act
      final hasNotes =
          await container.read(bip329ExportNotifierProvider.future);

      // Assert
      expect(hasNotes, true);
    });

    test('should build with false when no transactions have notes', () async {
      // Arrange: Create transactions without notes
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'txhash1', walletId: testWalletId),
        );
        await isar.transactionDbModels.put(
          createTransaction(txhash: 'txhash2', walletId: testWalletId)
              .copyWith(note: ''),
        );
      });

      // Re-read to trigger provider rebuild
      container.invalidate(transactionStorageProvider);

      // Act
      final hasNotes =
          await container.read(bip329ExportNotifierProvider.future);

      // Assert
      expect(hasNotes, false);
    });

    test('updateTransactionNote should throw when transaction not found',
        () async {
      // Act & Assert
      final notifier = container.read(transactionStorageProvider.notifier);
      expect(
        () => notifier.updateTransactionNote(
          txHash: 'nonexistent_txhash',
          note: 'Test note',
        ),
        throwsA(isA<TransactionNotFoundException>()),
      );
    });
  });
}

// Mock classes
class MockFilePicker extends Mock implements FilePicker {}

class MockStorage extends Mock implements IStorage {}

class MockBitcoinProvider extends Mock implements BitcoinProvider {
  @override
  Future<List<GdkTransaction>?> getTransactions({
    bool requiresRefresh = false,
    int first = 0,
    GdkGetTransactionsDetails? details,
  }) async =>
      [];
}

class MockLiquidProvider extends Mock implements LiquidProvider {
  @override
  Future<List<GdkTransaction>?> getTransactions({
    bool requiresRefresh = false,
    int first = 0,
    GdkGetTransactionsDetails? details,
  }) async =>
      [];
}
