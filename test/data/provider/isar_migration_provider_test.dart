import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/isar_migration_provider.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/isar_test_factories.dart';

// Mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IsarMigrationManager', () {
    late Isar isar;
    late MockSharedPreferences mockPrefs;
    late IsarMigrationManager migrationManager;

    // Query helpers to reduce repetitive Isar query patterns
    Future<TransactionDbModel?> findTransaction(Isar db, String txhash) async {
      return db.transactionDbModels
          .where()
          .filter()
          .txhashEqualTo(txhash)
          .findFirst();
    }

    setUp(() async {
      // Create in-memory Isar instance for testing
      isar = await Isar.open(
        [
          SideshiftOrderDbModelSchema,
          SwapOrderDbModelSchema,
          TransactionDbModelSchema,
        ],
        directory: '',
        name: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      mockPrefs = MockSharedPreferences();
      migrationManager = IsarMigrationManager(isar, mockPrefs);

      // Default mock behaviors
      when(() => mockPrefs.getInt(any())).thenReturn(null);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    group('_migrateV1ToV2', () {
      test('migrates SideshiftOrderDbModel to SwapOrderDbModel', () async {
        // Setup: Create legacy Sideshift orders
        final legacyOrder = createSideshiftOrder(
          orderId: 'test_order_1',
          depositAddress: 'deposit_address_1',
          settleAddress: 'settle_address_1',
          depositAmount: '100000',
          settleAmount: '50000',
          expiresAt: DateTime(2024, 1, 2),
          type: SideshiftOrderType.fixed,
          onchainTxHash: 'tx_hash_1',
        );

        await isar.writeTxn(() async {
          await isar.sideshiftOrderDbModels.put(legacyOrder);
        });

        // Execute migration
        await migrationManager.performMigrationIfNeeded();

        // Verify: SwapOrderDbModel was created
        final swapOrders = await isar.swapOrderDbModels.where().findAll();
        expect(swapOrders.length, 1);

        final swapOrder = swapOrders.first;
        expect(swapOrder.orderId, 'test_order_1');
        expect(swapOrder.fromAsset, 'BTC-LBTC');
        expect(swapOrder.toAsset, 'USDT');
        expect(swapOrder.depositAddress, 'deposit_address_1');
        expect(swapOrder.settleAddress, 'settle_address_1');
        expect(swapOrder.depositAmount, '100000');
        expect(swapOrder.settleAmount, '50000');
        expect(swapOrder.serviceFeeType, SwapFeeType.percentageFee);
        expect(swapOrder.serviceFeeValue,
            DecimalExt.fromDouble(kSideshiftServiceFee).toString());
        expect(swapOrder.serviceType, SwapServiceSource.sideshift);
        expect(swapOrder.onchainTxHash, 'tx_hash_1');

        // Verify: Legacy order was deleted
        final legacyOrders =
            await isar.sideshiftOrderDbModels.where().findAll();
        expect(legacyOrders.length, 0);

        // Verify: Version was updated
        verify(() => mockPrefs.setInt(kSwapOrderVersionKey,
            DatabaseMigration.sideshiftToSwapOrder.version)).called(1);
      });
    });

    group('_migrateTransactionsToV4', () {
      test('adds swapServiceSource to USDt swap transactions', () async {
        // Setup: Create a swap order
        await isar.writeTxn(() async {
          await isar.swapOrderDbModels.put(createSwapOrder(
            orderId: 'swap_order_1',
            fromAsset: 'USDT',
            toAsset: 'USDT-ETH',
            settleAmount: '95',
          ));
        });

        // Setup: Create a USDt swap transaction without swapServiceSource
        await isar.writeTxn(() async {
          await isar.transactionDbModels.put(createTransaction(
            txhash: 'swap_tx_1',
            type: TransactionDbModelType.sideshiftSwap,
            assetId: 'USDT',
            serviceOrderId: 'swap_order_1',
          ));
        });

        // Mock prefs to trigger V4 migration
        when(() => mockPrefs.getInt(kTransactionVersionKey)).thenReturn(
            DatabaseMigration.addSwapServiceSourceToTransactions.version - 1);

        // Execute migration
        await migrationManager.performMigrationIfNeeded();

        // Verify: swapServiceSource was added
        final tx = await findTransaction(isar, 'swap_tx_1');
        expect(tx?.swapServiceSource, SwapServiceSource.sideshift);

        // Verify: Version was updated
        verify(() => mockPrefs.setInt(kTransactionVersionKey,
                DatabaseMigration.addSwapServiceSourceToTransactions.version))
            .called(1);
      });

      test('skips non-USDt swap transactions', () async {
        // Setup: Create a non-USDt transaction
        await isar.writeTxn(() async {
          await isar.transactionDbModels
              .put(createTransaction(txhash: 'regular_tx', assetId: 'BTC'));
        });

        when(() => mockPrefs.getInt(kTransactionVersionKey)).thenReturn(
            DatabaseMigration.addSwapServiceSourceToTransactions.version - 1);

        await migrationManager.performMigrationIfNeeded();

        // Verify: Transaction was not modified
        final tx = await findTransaction(isar, 'regular_tx');
        expect(tx?.swapServiceSource, null);
      });

      test('skips transactions that already have swapServiceSource', () async {
        await isar.writeTxn(() async {
          await isar.transactionDbModels.put(createTransaction(
            txhash: 'swap_tx_with_source',
            type: TransactionDbModelType.sideshiftSwap,
            assetId: 'USDT',
            swapServiceSource: SwapServiceSource.changelly,
          ));
        });

        when(() => mockPrefs.getInt(kTransactionVersionKey)).thenReturn(
            DatabaseMigration.addSwapServiceSourceToTransactions.version - 1);

        await migrationManager.performMigrationIfNeeded();

        // Verify: Unchanged
        final tx = await findTransaction(isar, 'swap_tx_with_source');
        expect(tx?.swapServiceSource, SwapServiceSource.changelly);
      });

      test('logs warning when swap order not found', () async {
        // Setup: Transaction without matching swap order
        await isar.writeTxn(() async {
          await isar.transactionDbModels.put(createTransaction(
            txhash: 'orphan_swap_tx',
            type: TransactionDbModelType.sideshiftSwap,
            assetId: 'USDT',
            serviceOrderId: 'non_existent_order',
          ));
        });

        when(() => mockPrefs.getInt(kTransactionVersionKey)).thenReturn(
            DatabaseMigration.addSwapServiceSourceToTransactions.version - 1);

        // Should not throw, just log warning
        await migrationManager.performMigrationIfNeeded();

        // Transaction remains unchanged
        final tx = await findTransaction(isar, 'orphan_swap_tx');
        expect(tx?.swapServiceSource, null);
      });
    });

    group('performMigrationIfNeeded', () {
      test('skips migration when already at latest version', () async {
        // Setup: Mock prefs to return latest version
        when(() => mockPrefs.getInt(kSwapOrderVersionKey))
            .thenReturn(DatabaseMigration.sideshiftToSwapOrder.version);
        when(() => mockPrefs.getInt(kTransactionVersionKey)).thenReturn(
            DatabaseMigration.addSwapServiceSourceToTransactions.version);

        await migrationManager.performMigrationIfNeeded();

        // Verify: No setInt calls were made (no migrations performed)
        verifyNever(() => mockPrefs.setInt(any(), any()));
      });

      test('runs multiple migrations in correct order', () async {
        // Setup: Mock prefs to indicate old version
        when(() => mockPrefs.getInt(kSwapOrderVersionKey))
            .thenReturn(DatabaseMigration.initial.version);
        when(() => mockPrefs.getInt(kTransactionVersionKey))
            .thenReturn(DatabaseMigration.initial.version);

        // Create legacy data
        await isar.writeTxn(() async {
          await isar.sideshiftOrderDbModels
              .put(createSideshiftOrder(orderId: 'legacy_order'));
        });

        await migrationManager.performMigrationIfNeeded();

        // Verify: V1 to V2 migration was performed
        verify(() => mockPrefs.setInt(kSwapOrderVersionKey,
            DatabaseMigration.sideshiftToSwapOrder.version)).called(1);

        // Verify: SwapOrder was created
        final swapOrders = await isar.swapOrderDbModels.where().findAll();
        expect(swapOrders.length, 1);
      });

      test('only runs needed migrations based on current version', () async {
        // Setup: Database already at V2, needs V4 migration only
        when(() => mockPrefs.getInt(kSwapOrderVersionKey))
            .thenReturn(DatabaseMigration.sideshiftToSwapOrder.version);
        when(() => mockPrefs.getInt(kTransactionVersionKey)).thenReturn(
            DatabaseMigration.addSwapServiceSourceToTransactions.version - 1);

        await migrationManager.performMigrationIfNeeded();

        // Verify: Only V4 migration was triggered
        verify(() => mockPrefs.setInt(kTransactionVersionKey,
                DatabaseMigration.addSwapServiceSourceToTransactions.version))
            .called(1);

        // Verify: V2 migration was not run again
        verifyNever(() => mockPrefs.setInt(kSwapOrderVersionKey,
            DatabaseMigration.sideshiftToSwapOrder.version));
      });

      test('migration is idempotent - can run multiple times safely', () async {
        // Setup: Create initial data
        await isar.writeTxn(() async {
          await isar.sideshiftOrderDbModels
              .put(createSideshiftOrder(orderId: 'test_order'));
        });

        when(() => mockPrefs.getInt(kSwapOrderVersionKey))
            .thenReturn(DatabaseMigration.initial.version);

        // Run migration first time
        await migrationManager.performMigrationIfNeeded();

        final swapOrdersFirst = await isar.swapOrderDbModels.where().findAll();
        expect(swapOrdersFirst.length, 1);

        // Mock prefs to return updated version
        when(() => mockPrefs.getInt(kSwapOrderVersionKey))
            .thenReturn(DatabaseMigration.sideshiftToSwapOrder.version);

        // Run migration again
        await migrationManager.performMigrationIfNeeded();

        // Verify: No duplicate orders created
        final swapOrdersSecond = await isar.swapOrderDbModels.where().findAll();
        expect(swapOrdersSecond.length, 1);
      });

      test('handles empty database gracefully', () async {
        // Setup: Empty database, no data to migrate
        when(() => mockPrefs.getInt(kSwapOrderVersionKey))
            .thenReturn(DatabaseMigration.initial.version);
        when(() => mockPrefs.getInt(kTransactionVersionKey))
            .thenReturn(DatabaseMigration.initial.version);

        // Execute: Run migration on empty database
        await migrationManager.performMigrationIfNeeded();

        // Verify: Migration completes without error
        // Version should still be updated since migration ran successfully
        verify(() => mockPrefs.setInt(kSwapOrderVersionKey,
            DatabaseMigration.sideshiftToSwapOrder.version)).called(1);

        // Verify: No data was created
        final swapOrders = await isar.swapOrderDbModels.where().findAll();
        expect(swapOrders.length, 0);
        final transactions = await isar.transactionDbModels.where().findAll();
        expect(transactions.length, 0);
      });

      test('continues migration even if setInt returns false', () async {
        // Setup: setInt returns false (failure to persist version)
        when(() => mockPrefs.setInt(any(), any()))
            .thenAnswer((_) async => false);
        when(() => mockPrefs.getInt(kSwapOrderVersionKey))
            .thenReturn(DatabaseMigration.initial.version);
        when(() => mockPrefs.getInt(kTransactionVersionKey))
            .thenReturn(DatabaseMigration.initial.version);

        // Create legacy data
        await isar.writeTxn(() async {
          await isar.sideshiftOrderDbModels
              .put(createSideshiftOrder(orderId: 'test_order'));
        });

        // Execute: Should not throw even if setInt fails
        await migrationManager.performMigrationIfNeeded();

        // Verify: Migration data was still processed
        final swapOrders = await isar.swapOrderDbModels.where().findAll();
        expect(swapOrders.length, 1);
        expect(swapOrders.first.orderId, 'test_order');

        // Verify: setInt was called (even though it returned false)
        verify(() => mockPrefs.setInt(kSwapOrderVersionKey,
            DatabaseMigration.sideshiftToSwapOrder.version)).called(1);
      });
    });

    group('DatabaseMigration enum', () {
      test('versions are sequential and unique', () {
        final versions =
            DatabaseMigration.values.map((m) => m.version).toList();

        // Check uniqueness
        expect(versions.toSet().length, versions.length);

        // Check sequential (starting from 1)
        for (var i = 0; i < versions.length; i++) {
          expect(versions[i], i + 1);
        }
      });
    });
  });
}
