import 'dart:async';

import 'package:aqua/config/constants/pref_keys.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/migration/multi_wallet_migration_provider.dart';
import 'package:aqua/features/shared/providers/env_provider.dart';
import 'package:aqua/features/shared/providers/shared_prefs_provider.dart';
import 'package:aqua/features/wallet/models/stored_wallet.dart';
import 'package:aqua/features/wallet/models/wallet_state.dart';
import 'package:aqua/features/wallet/providers/stored_wallets_provider.dart';
import 'package:aqua/features/wallet/utils/bip32_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/isar_test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for record types
    registerFallbackValue((null, null) as (String?, StorageError?));
    registerFallbackValue(
        (null, null) as (Map<String, String>?, StorageError?));
    registerFallbackValue(null as StorageError?);

    // Register fallback values for StoredWallet list
    registerFallbackValue(<StoredWallet>[]);
  });
  group('MultiWalletMigrationProvider', () {
    late MockStorage mockStorage;
    late MockStoredWalletsNotifier mockStoredWalletsNotifier;
    late SharedPreferences mockSharedPrefs;
    late ProviderContainer container;
    late Isar isar;

    const testMnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const testWalletId = '73c5da0a'; // Expected fingerprint for test mnemonic
    const testRegion = 'US';
    const testExchangeRate = 'USD';

    setUp(() async {
      mockStorage = MockStorage();
      mockStoredWalletsNotifier = MockStoredWalletsNotifier();
      mockSharedPrefs = MockSharedPreferences();

      // Create in-memory Isar instance for testing
      isar = await Isar.open(
        [
          TransactionDbModelSchema,
          SwapOrderDbModelSchema,
          BoltzSwapDbModelSchema,
          PegOrderDbModelSchema,
          SideshiftOrderDbModelSchema,
        ],
        directory: '',
        name: 'multi_wallet_test_${DateTime.now().millisecondsSinceEpoch}',
      );

      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          storedWalletsProvider.overrideWith(() => mockStoredWalletsNotifier),
          sharedPreferencesProvider.overrideWithValue(mockSharedPrefs),
          envProvider.overrideWith((ref) => EnvNotifier(mockSharedPrefs)),
          storageProvider.overrideWith((ref) async => isar),
        ],
      );

      // Setup default mock behaviors for storage
      when(() => mockStorage.get(any())).thenAnswer((_) async => (null, null));
      when(() => mockStorage.save(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => null);
      when(() => mockStorage.delete(any())).thenAnswer((_) async => null);
      when(() => mockStorage.getAll()).thenAnswer((_) async => (null, null));
      when(() => mockStorage.deleteAll()).thenAnswer((_) async => null);

      // Setup default mock behaviors for stored wallets notifier
      when(() => mockStoredWalletsNotifier.saveWalletsList(any()))
          .thenAnswer((_) async {});
      when(() => mockStoredWalletsNotifier.loadStoredWallets())
          .thenAnswer((_) async => <StoredWallet>[]);
      when(() => mockStoredWalletsNotifier.getCurrentWalletId())
          .thenAnswer((_) async => null);

      // Setup default mock behaviors for shared preferences
      when(() => mockSharedPrefs.getString(any())).thenReturn(null);
      when(() => mockSharedPrefs.getBool(any())).thenReturn(null);
      when(() => mockSharedPrefs.getStringList(any())).thenReturn(null);
      when(() => mockSharedPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockSharedPrefs.setBool(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockSharedPrefs.setStringList(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockSharedPrefs.remove(any())).thenAnswer((_) async => true);
    });

    tearDown(() async {
      container.dispose();
      await isar.close(deleteFromDisk: true);
    });

    test('should skip migration when no legacy mnemonic exists', () async {
      // Arrange
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (null, null));

      // Act
      final result = await container.read(multiWalletMigrationProvider.future);

      // Assert
      expect(result, isNull);
      verify(() => mockStorage.get(StorageKeys.legacyMnemonic)).called(1);
      verifyNever(() =>
          mockStorage.save(key: any(named: 'key'), value: any(named: 'value')));
      verifyNever(() => mockStoredWalletsNotifier.saveWalletsList(any()));
    });

    test(
        'should skip migration when legacy mnemonic exists and migrated mnemonic exists with the same value',
        () async {
      // Arrange
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (testMnemonic, null));
      when(() => mockStorage.get(StorageKeys.mnemonic(testWalletId)))
          .thenAnswer((_) async => (testMnemonic, null));

      // Act
      final result = await container.read(multiWalletMigrationProvider.future);

      // Assert
      expect(result, isNull);
      verify(() => mockStorage.get(StorageKeys.legacyMnemonic)).called(1);
      verify(() => mockStorage.get(StorageKeys.mnemonic(testWalletId)))
          .called(1);
      verifyNever(() =>
          mockStorage.save(key: any(named: 'key'), value: any(named: 'value')));
      verifyNever(() => mockStoredWalletsNotifier.saveWalletsList(any()));
    });

    test('should perform migration when only legacy mnemonic exists', () async {
      // Arrange
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (testMnemonic, null));
      when(() => mockStorage.save(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => null);
      when(() => mockStorage.delete(any())).thenAnswer((_) async => null);

      // Act
      await container.read(multiWalletMigrationProvider.future);

      // Assert - Verify wallet ID generation
      final expectedWalletId = generateBip32Fingerprint(testMnemonic);
      expect(expectedWalletId, equals(testWalletId));

      // Assert - Verify mnemonic migration
      verify(() => mockStorage.save(
            key: StorageKeys.mnemonic(expectedWalletId),
            value: testMnemonic,
          )).called(1);
      verifyNever(() => mockStorage.delete(StorageKeys.legacyMnemonic));

      // Assert - Verify wallet set as default
      verify(() => mockStorage.save(
            key: StorageKeys.currentWalletId,
            value: testWalletId,
          )).called(1);

      // Assert - Verify wallet entry creation
      final captured =
          verify(() => mockStoredWalletsNotifier.saveWalletsList(captureAny()))
              .captured;
      expect(captured, hasLength(1));

      final wallets = captured.first as List<StoredWallet>;
      expect(wallets, hasLength(1));

      final wallet = wallets.first;
      expect(wallet.id, equals(testWalletId));
      expect(wallet.name, equals("Main Wallet"));
      expect(wallet.createdAt, isA<DateTime>());
    });

    test('should migrate wallet settings from shared preferences', () async {
      // Arrange
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (testMnemonic, null));
      when(() => mockStorage.save(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => null);
      when(() => mockStorage.delete(any())).thenAnswer((_) async => null);

      // Setup legacy preferences
      when(() => mockSharedPrefs.getString(PrefKeys.region))
          .thenReturn(testRegion);
      when(() => mockSharedPrefs.getString(PrefKeys.exchangeRate))
          .thenReturn(testExchangeRate);
      when(() => mockSharedPrefs.getBool(PrefKeys.directPegIn))
          .thenReturn(true);

      // Act
      await container.read(multiWalletMigrationProvider.future);

      // Assert
      verifyNever(() => mockSharedPrefs.remove(PrefKeys.region));
      verifyNever(() => mockSharedPrefs.remove(PrefKeys.exchangeRate));
      verifyNever(() => mockSharedPrefs.remove(PrefKeys.directPegIn));
    });

    test('should migrate user assets settings for mainnet environment',
        () async {
      // Arrange
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (testMnemonic, null));
      when(() => mockStorage.save(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => null);
      when(() => mockStorage.delete(any())).thenAnswer((_) async => null);

      final testAssets = ['asset1', 'asset2'];
      when(() => mockSharedPrefs.getStringList(PrefKeys.userAssets))
          .thenReturn(testAssets);
      when(() => mockSharedPrefs.getStringList(
              PrefKeys.userAssetsForWallet(testWalletId, 'mainnet')))
          .thenReturn(null);

      // Act
      await container.read(multiWalletMigrationProvider.future);

      // Assert
      verify(() => mockSharedPrefs.setStringList(
          PrefKeys.userAssetsForWallet(testWalletId, 'mainnet'),
          testAssets)).called(1);
      verify(() => mockSharedPrefs.remove(PrefKeys.userAssets)).called(1);
    });

    test('should run only once due to FutureProvider caching', () async {
      // This test verifies that the migration logic runs only once, even if the provider
      // is accessed multiple times, because FutureProvider caches the result after first execution

      // Arrange
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (null, null));

      // Act - Call the provider multiple times to verify caching behavior
      final result1 = await container.read(multiWalletMigrationProvider.future);
      final result2 = await container.read(multiWalletMigrationProvider.future);

      // Assert
      expect(result1, isNull);
      expect(result2, isNull);

      // Verify that the migration logic (storage check) was only executed once
      // due to FutureProvider caching, ensuring migration doesn't run multiple times
      verify(() => mockStorage.get(StorageKeys.legacyMnemonic)).called(1);
    });
  });

  group('WalletId Database Migration', () {
    late Isar isar;

    const testMnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    const testWalletId = '73c5da0a'; // Expected fingerprint for test mnemonic

    setUp(() async {
      // Create in-memory Isar instance for testing
      isar = await Isar.open(
        [
          TransactionDbModelSchema,
          SwapOrderDbModelSchema,
          BoltzSwapDbModelSchema,
          PegOrderDbModelSchema,
          SideshiftOrderDbModelSchema,
        ],
        directory: '',
        name: 'wallet_migration_test_${DateTime.now().millisecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    test('migrates all database collections to include walletId', () async {
      // Setup: Create records across all collections without walletId
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(createTransaction(txhash: 'tx1'));
        await isar.boltzSwapDbModels.put(createBoltzSwap(boltzId: 'boltz_1'));
        await isar.swapOrderDbModels.put(createSwapOrder(orderId: 'swap_1'));
        await isar.pegOrderDbModels.put(createPegOrder(orderId: 'peg_1'));
      });

      // Setup mock providers
      final mockStorage = MockStorage();
      final mockStoredWalletsNotifier = MockStoredWalletsNotifier();
      final mockSharedPrefs = MockSharedPreferences();

      when(() => mockStorage.get(any())).thenAnswer((_) async => (null, null));
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (testMnemonic, null));
      when(() => mockStorage.save(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => null);
      when(() => mockStoredWalletsNotifier.saveWalletsList(any()))
          .thenAnswer((_) async {});
      when(() => mockSharedPrefs.getString(any())).thenReturn(null);
      when(() => mockSharedPrefs.getBool(any())).thenReturn(null);
      when(() => mockSharedPrefs.getStringList(any())).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          storedWalletsProvider.overrideWith(() => mockStoredWalletsNotifier),
          sharedPreferencesProvider.overrideWithValue(mockSharedPrefs),
          envProvider.overrideWith((ref) => EnvNotifier(mockSharedPrefs)),
          storageProvider.overrideWith((ref) async => isar),
        ],
      );

      // Execute migration
      await container.read(multiWalletMigrationProvider.future);

      // Verify: all records now have testWalletId
      final tx = await isar.transactionDbModels.where().findFirst();
      final boltz = await isar.boltzSwapDbModels.where().findFirst();
      final swap = await isar.swapOrderDbModels.where().findFirst();
      final peg = await isar.pegOrderDbModels.where().findFirst();

      expect(tx?.walletId, testWalletId);
      expect(boltz?.walletId, testWalletId);
      expect(swap?.walletId, testWalletId);
      expect(peg?.walletId, testWalletId);

      container.dispose();
    });

    test('skips records that already have walletId', () async {
      const existingWalletId = 'existing_wallet_id';

      // Setup: Create transactions with existing walletId
      await isar.writeTxn(() async {
        await isar.transactionDbModels
            .put(createTransaction(txhash: 'tx1', walletId: existingWalletId));
        await isar.transactionDbModels.put(createTransaction(txhash: 'tx2'));
      });

      // Setup mock providers
      final mockStorage = MockStorage();
      final mockStoredWalletsNotifier = MockStoredWalletsNotifier();
      final mockSharedPrefs = MockSharedPreferences();

      when(() => mockStorage.get(any())).thenAnswer((_) async => (null, null));
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (testMnemonic, null));
      when(() => mockStorage.save(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => null);
      when(() => mockStoredWalletsNotifier.saveWalletsList(any()))
          .thenAnswer((_) async {});
      when(() => mockSharedPrefs.getString(any())).thenReturn(null);
      when(() => mockSharedPrefs.getBool(any())).thenReturn(null);
      when(() => mockSharedPrefs.getStringList(any())).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          storedWalletsProvider.overrideWith(() => mockStoredWalletsNotifier),
          sharedPreferencesProvider.overrideWithValue(mockSharedPrefs),
          envProvider.overrideWith((ref) => EnvNotifier(mockSharedPrefs)),
          storageProvider.overrideWith((ref) async => isar),
        ],
      );

      // Execute migration
      await container.read(multiWalletMigrationProvider.future);

      // Verify: existing walletId was preserved, new one was added
      final tx1 = await isar.transactionDbModels
          .filter()
          .txhashEqualTo('tx1')
          .findFirst();
      final tx2 = await isar.transactionDbModels
          .filter()
          .txhashEqualTo('tx2')
          .findFirst();

      expect(tx1?.walletId, existingWalletId);
      expect(tx2?.walletId, testWalletId);

      container.dispose();
    });

    test('migration is idempotent - can run multiple times safely', () async {
      // Setup: Create transaction without walletId
      await isar.writeTxn(() async {
        await isar.transactionDbModels.put(createTransaction(txhash: 'tx1'));
      });

      // Setup mock providers for first run
      final mockStorage = MockStorage();
      final mockStoredWalletsNotifier = MockStoredWalletsNotifier();
      final mockSharedPrefs = MockSharedPreferences();

      when(() => mockStorage.get(any())).thenAnswer((_) async => (null, null));
      when(() => mockStorage.get(StorageKeys.legacyMnemonic))
          .thenAnswer((_) async => (testMnemonic, null));
      when(() => mockStorage.save(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => null);
      when(() => mockStoredWalletsNotifier.saveWalletsList(any()))
          .thenAnswer((_) async {});
      when(() => mockSharedPrefs.getString(any())).thenReturn(null);
      when(() => mockSharedPrefs.getBool(any())).thenReturn(null);
      when(() => mockSharedPrefs.getStringList(any())).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          storedWalletsProvider.overrideWith(() => mockStoredWalletsNotifier),
          sharedPreferencesProvider.overrideWithValue(mockSharedPrefs),
          envProvider.overrideWith((ref) => EnvNotifier(mockSharedPrefs)),
          storageProvider.overrideWith((ref) async => isar),
        ],
      );

      // Execute migration first time
      await container.read(multiWalletMigrationProvider.future);

      // Verify first migration
      var transactions = await isar.transactionDbModels.where().findAll();
      expect(transactions.length, 1);
      expect(transactions.first.walletId, testWalletId);

      container.dispose();

      // Create new mocks and container for second run (simulates app restart)
      // Note: Must create new mock notifier since it can only be used with one container
      final mockStoredWalletsNotifier2 = MockStoredWalletsNotifier();
      when(() => mockStoredWalletsNotifier2.saveWalletsList(any()))
          .thenAnswer((_) async {});

      final container2 = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          storedWalletsProvider.overrideWith(() => mockStoredWalletsNotifier2),
          sharedPreferencesProvider.overrideWithValue(mockSharedPrefs),
          envProvider.overrideWith((ref) => EnvNotifier(mockSharedPrefs)),
          storageProvider.overrideWith((ref) async => isar),
        ],
      );

      // Execute migration second time
      await container2.read(multiWalletMigrationProvider.future);

      // Verify: Still only one transaction with same walletId
      transactions = await isar.transactionDbModels.where().findAll();
      expect(transactions.length, 1);
      expect(transactions.first.walletId, testWalletId);

      container2.dispose();
    });
  });
}

// Mock classes
class MockStoredWalletsNotifier extends AsyncNotifier<WalletState>
    with Mock
    implements StoredWalletsNotifier {
  @override
  FutureOr<WalletState> build() async => WalletState.initial();
}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockStorage extends Mock implements IStorage {}

// Extension for WalletState.initial() if it doesn't exist
extension WalletStateInitial on WalletState {
  static WalletState initial() => const WalletState(
        wallets: [],
        currentWallet: null,
      );
}
