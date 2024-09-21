import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'encryption_provider_test.dart';

const kTestFilePath = 'mock_file_path';
const _kTestEncryptedData = 'encrypted_data';

class MockEncryption extends Mock implements Encryption {}

class MockSecureStorageProvider extends Mock implements IStorage {}

class MockFileSystemProvider extends Mock implements DeviceIO {}

class MockTransactionStorageProvider
    extends AsyncNotifier<List<TransactionDbModel>>
    with Mock
    implements TransactionStorageNotifier {
  @override
  FutureOr<List<TransactionDbModel>> build() async => kMockDbTransactions;
}

class MockSideshiftStorageProvider
    extends AsyncNotifier<List<SideshiftOrderDbModel>>
    with Mock
    implements SideshiftOrderStorageNotifier {
  @override
  FutureOr<List<SideshiftOrderDbModel>> build() async => kMockDbSideshiftOrders;
}

class MockBoltzStorageProvider extends AsyncNotifier<List<BoltzSwapDbModel>>
    with Mock
    implements BoltzSwapStorageNotifier {
  @override
  FutureOr<List<BoltzSwapDbModel>> build() async => kMockDbBoltzSwaps;
}

final originalMap = {
  DataTransferService.keyTransactions:
      kMockDbTransactions.map((e) => e.toJson()).toList(),
  DataTransferService.keySideshiftOrders:
      kMockDbSideshiftOrders.map((e) => e.toJson()).toList(),
  DataTransferService.keyBoltzSwaps:
      kMockDbBoltzSwaps.map((e) => e.toJson()).toList(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockEncryption = MockEncryption();
  final mockSecureStorageProvider = MockSecureStorageProvider();
  final mockIoProvider = MockFileSystemProvider();
  final mockTransactionStorageProvider = MockTransactionStorageProvider();
  final mockSideshiftStorageProvider = MockSideshiftStorageProvider();
  final mockBoltzStorageProvider = MockBoltzStorageProvider();

  setUpAll(() {
    registerFallbackValue(kMockDbTransactions.first);
    registerFallbackValue(kMockDbSideshiftOrders.first);
    registerFallbackValue(kMockDbBoltzSwaps.first);
  });

  group('DataTransferService', () {
    group('with mocked encrpytion', () {
      final container = ProviderContainer(overrides: [
        secureStorageProvider.overrideWithValue(mockSecureStorageProvider),
        transactionStorageProvider
            .overrideWith(() => mockTransactionStorageProvider),
        sideshiftStorageProvider
            .overrideWith(() => mockSideshiftStorageProvider),
        boltzStorageProvider.overrideWith(() => mockBoltzStorageProvider),
        encryptionProvider.overrideWith((_) => mockEncryption),
        fileSystemProvider.overrideWithValue(mockIoProvider),
      ]);

      tearDownAll(() {
        container.dispose();
      });

      test(
        'export method should pass encrypted JSON of txns for file storage',
        () async {
          final map = {
            DataTransferService.keyTransactions:
                kMockDbTransactions.map((e) => e.toJson()).toList(),
            DataTransferService.keySideshiftOrders:
                kMockDbSideshiftOrders.map((e) => e.toJson()).toList(),
            DataTransferService.keyBoltzSwaps:
                kMockDbBoltzSwaps.map((e) => e.toJson()).toList(),
          };
          final jsonString = jsonEncode(map);
          when(() => mockEncryption.encrypt(jsonString))
              .thenReturn(_kTestEncryptedData);

          when(() => mockIoProvider.writeToDocuments(
                any(),
                fileName: any(named: 'fileName'),
              )).thenAnswer((_) => Future.value(kTestFilePath));

          final result = await container.read(dataTransferProvider).export();

          expect(result, equals(kTestFilePath));
          verify(() => mockEncryption.encrypt(jsonString)).called(1);
          verify(() => mockIoProvider.writeToDocuments(
                _kTestEncryptedData,
                fileName: any(named: 'fileName'),
              )).called(1);
        },
      );

      test('import method should read encrypted data from file', () async {
        final testJsonFile = File('assets/raw/test_txn_export.json');
        final testJsonContent = await testJsonFile.readAsString();

        when(() =>
                mockIoProvider.findFileInDocuments(query: any(named: 'query')))
            .thenAnswer((_) => Future.value(kTestFilePath));
        when(() => mockIoProvider.readFromDocuments(filePath: kTestFilePath))
            .thenAnswer((_) => Future.value(_kTestEncryptedData));
        when(() => mockEncryption.decrypt(_kTestEncryptedData))
            .thenReturn(testJsonContent);
        when(() => mockTransactionStorageProvider.save(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockSideshiftStorageProvider.save(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockBoltzStorageProvider.save(any()))
            .thenAnswer((_) => Future.value());

        await container.read(dataTransferProvider).import();

        verify(() => mockIoProvider.readFromDocuments(filePath: kTestFilePath))
            .called(1);
        verify(() => mockEncryption.decrypt(_kTestEncryptedData)).called(1);
      });

      test('imported items should match exported ones', () async {
        // Export mock data
        when(() => mockSecureStorageProvider.get(StorageKeys.mnemonic))
            .thenAnswer((_) async => Future.value((kFakeMnemonic, null)));
        when(() => mockIoProvider.writeToDocuments(
              any(),
              fileName: any(named: 'fileName'),
            )).thenAnswer((_) => Future.value(kTestFilePath));

        final jsonString = jsonEncode(originalMap);
        final encryption = await container.read(encryptionProvider.future);
        final encrypted = encryption.encrypt(jsonString);

        final result = await container.read(dataTransferProvider).export();

        expect(result, equals(kTestFilePath));
        verify(() => mockIoProvider.writeToDocuments(
              encrypted,
              fileName: any(named: 'fileName'),
            )).called(1);

        // Simulate import by reading the encrypted data from file
        when(() =>
                mockIoProvider.findFileInDocuments(query: any(named: 'query')))
            .thenAnswer((_) => Future.value(kTestFilePath));
        when(() => mockIoProvider.readFromDocuments(filePath: kTestFilePath))
            .thenAnswer((_) => Future.value(encrypted));
        when(() => mockTransactionStorageProvider.save(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockSideshiftStorageProvider.save(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockBoltzStorageProvider.save(any()))
            .thenAnswer((_) => Future.value());

        final map = await container.read(dataTransferProvider).import();

        verify(() => mockIoProvider.readFromDocuments(filePath: kTestFilePath))
            .called(1);
        verify(() => mockEncryption.decrypt(encrypted)).called(1);

        // Verify the decrypted imported items match the original exported ones
        final transactionItems =
            map[DataTransferService.keyTransactions] as List;
        transactionItems
            .cast<Map<String, dynamic>>()
            .map(TransactionDbModel.fromJson)
            .forEach((it) => expect(kMockDbTransactions.contains(it), isTrue));

        final sideshiftItems =
            map[DataTransferService.keySideshiftOrders] as List;
        sideshiftItems
            .cast<Map<String, dynamic>>()
            .map(SideshiftOrderDbModel.fromJson)
            .forEach(
                (it) => expect(kMockDbSideshiftOrders.contains(it), isTrue));

        final boltzItems = map[DataTransferService.keyBoltzSwaps] as List;
        boltzItems
            .cast<Map<String, dynamic>>()
            .map(BoltzSwapDbModel.fromJson)
            .forEach((it) => expect(kMockDbBoltzSwaps.contains(it), isTrue));
      });
    });

    group('with real encrpytion', () {
      final mockSecureStorageProvider = MockSecureStorageProvider();
      final mockIoProvider = MockFileSystemProvider();
      final mockTransactionStorageProvider = MockTransactionStorageProvider();
      final mockSideshiftStorageProvider = MockSideshiftStorageProvider();
      final mockBoltzStorageProvider = MockBoltzStorageProvider();

      final container = ProviderContainer(overrides: [
        secureStorageProvider.overrideWithValue(mockSecureStorageProvider),
        transactionStorageProvider
            .overrideWith(() => mockTransactionStorageProvider),
        sideshiftStorageProvider
            .overrideWith(() => mockSideshiftStorageProvider),
        boltzStorageProvider.overrideWith(() => mockBoltzStorageProvider),
        fileSystemProvider.overrideWithValue(mockIoProvider),
      ]);

      tearDownAll(container.dispose);

      test('import with different account should throw error', () async {
        // Export mock data
        when(() => mockSecureStorageProvider.get(StorageKeys.mnemonic))
            .thenAnswer((_) async => Future.value((kFakeMnemonic, null)));
        when(() => mockIoProvider.writeToDocuments(
              any(),
              fileName: any(named: 'fileName'),
            )).thenAnswer((_) => Future.value(kTestFilePath));

        final jsonString = jsonEncode(originalMap);
        final encryption = await container.read(encryptionProvider.future);
        final encrypted = encryption.encrypt(jsonString);

        final result = await container.read(dataTransferProvider).export();

        expect(result, equals(kTestFilePath));
        verify(() => mockIoProvider.writeToDocuments(
              encrypted,
              fileName: any(named: 'fileName'),
            )).called(1);

        // Simulate import by reading the encrypted data from file
        when(() =>
                mockIoProvider.findFileInDocuments(query: any(named: 'query')))
            .thenAnswer((_) => Future.value(kTestFilePath));
        when(() => mockIoProvider.readFromDocuments(filePath: kTestFilePath))
            .thenAnswer((_) => Future.value(encrypted));
        when(() => mockSecureStorageProvider.get(StorageKeys.mnemonic))
            .thenAnswer((_) async => Future.value(('diff-mnemonic', null)));
        container.invalidate(encryptionProvider);

        expect(
          () => container.read(dataTransferProvider).import(),
          throwsA(isA<AquaDataTransferInvalidImportKeyError>()),
        );
      });
    });
  });
}
