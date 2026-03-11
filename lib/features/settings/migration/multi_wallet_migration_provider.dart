import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/models/stored_wallet.dart';
import 'package:aqua/features/wallet/providers/providers.dart';
import 'package:aqua/features/wallet/utils/bip32_utils.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';

final _logger = CustomLogger(FeatureFlag.multiWallet);

const _kMigrationBatchSize = 100;

final multiWalletMigrationProvider = FutureProvider((ref) async {
  // Check if there's a legacy mnemonic
  final storage = ref.read(secureStorageProvider);
  final (legacyMnemonic, _) = await storage.get(StorageKeys.legacyMnemonic);

  if (legacyMnemonic == null) {
    _logger.debug('No legacy mnemonic found. Skipping migration.');
    return null;
  }

  // Generate fingerprint from mnemonic to use as ID
  final walletId = generateBip32Fingerprint(legacyMnemonic);

  final (existingWalletIdMnemonic, _) =
      await storage.get(StorageKeys.mnemonic(walletId));

  if (existingWalletIdMnemonic != null) {
    _logger.debug(
        'Legacy mnemonic has already been migrated. Skipping migration.');
    return null;
  }

  // Save the mnemonic with the new wallet-specific key
  await storage.save(
      key: StorageKeys.mnemonic(walletId), value: legacyMnemonic);

  // Set as current wallet
  await storage.save(key: StorageKeys.currentWalletId, value: walletId);

  // Create a new wallet entry
  final wallet = StoredWallet(
    id: walletId,
    name: "Main Wallet",
    createdAt: DateTime.now(),
  );

  await ref.read(storedWalletsProvider.notifier).saveWalletsList([wallet]);

  // ---------------------------------------------------------------------------------
  // Wallet settings
  // ---------------------------------------------------------------------------------

  final prefs = ref.read(sharedPreferencesProvider);

  final stringsForMigration = [];

  for (final [legacyKey, newKey] in stringsForMigration) {
    final legacyKeyValue = prefs.getString(legacyKey);
    final newKeyValue = prefs.getString(newKey);

    if (legacyKeyValue != null && newKeyValue == null) {
      // MIGRATE!
      try {
        await prefs.setString(newKey, legacyKeyValue);
        await prefs.remove(legacyKey);

        _logger.debug('Migrated $legacyKey => $newKey');
      } catch (e) {
        _logger.error('Error migrating $legacyKey => $newKey: $e');
      }
    }
  }

  final boolForMigration = [];

  for (final [legacyKey, newKey] in boolForMigration) {
    final legacyKeyValue = prefs.getBool(legacyKey);
    final newKeyValue = prefs.getBool(newKey);

    if (legacyKeyValue != null && newKeyValue == null) {
      // MIGRATE!
      try {
        await prefs.setBool(newKey, legacyKeyValue);
        await prefs.remove(legacyKey);

        _logger.debug('Migrated $legacyKey => $newKey');
      } catch (e) {
        _logger.error('Error migrating $legacyKey => $newKey: $e');
      }
    }
  }

  /// Migrate user assets settings to wallet-specific key
  try {
    final env = ref.read(envProvider);

    final mapEnvToAssetsKey = {
      Env.mainnet: PrefKeys.userAssets,
      Env.testnet: PrefKeys.userTestnetAssets,
      Env.regtest: PrefKeys.userRegtestAssets
    };
    final sourceKey = mapEnvToAssetsKey[env] ?? PrefKeys.userAssets;

    final userAssets = prefs.getStringList(sourceKey);
    final targetKey = PrefKeys.userAssetsForWallet(walletId, env.name);
    final userAssetsForWallet = prefs.getStringList(targetKey);
    if (userAssets != null && userAssetsForWallet == null) {
      await prefs.setStringList(targetKey, userAssets);
      await prefs.remove(sourceKey);
      _logger.debug(
          'Migrated user assets settings for wallet $walletId (${env.name})');
    }
  } catch (e) {
    _logger.error('Error migrating user assets settings: $e');
  }

  // ---------------------------------------------------------------------------------
  // Database records - ensure all records have walletId
  // ---------------------------------------------------------------------------------

  final isar = await ref.read(storageProvider.future);
  await _ensureWalletIdOnAllRecords(isar, walletId);

  // Invalidate storage providers to refresh state with migrated walletId data
  ref.invalidate(transactionStorageProvider);
  ref.invalidate(boltzStorageProvider);
  ref.invalidate(swapStorageProvider);
  ref.invalidate(pegStorageProvider);
});

/// Ensures all database records have a walletId.
/// This is idempotent - safe to run multiple times.
Future<void> _ensureWalletIdOnAllRecords(Isar isar, String walletId) async {
  // Transactions
  var offset = 0;
  var migratedCount = 0;
  while (true) {
    final items = await isar.transactionDbModels
        .filter()
        .walletIdIsNull()
        .offset(offset)
        .limit(_kMigrationBatchSize)
        .findAll();
    if (items.isEmpty) break;
    await isar.writeTxn(() async {
      for (var item in items) {
        await isar.transactionDbModels.put(item.copyWith(walletId: walletId));
      }
    });
    migratedCount += items.length;
    offset += items.length;
  }
  if (migratedCount > 0) {
    _logger.debug('Migrated $migratedCount transactions to include walletId');
  }

  // BoltzSwapDbModel
  offset = 0;
  migratedCount = 0;
  while (true) {
    final items = await isar.boltzSwapDbModels
        .filter()
        .walletIdIsNull()
        .offset(offset)
        .limit(_kMigrationBatchSize)
        .findAll();
    if (items.isEmpty) break;
    await isar.writeTxn(() async {
      for (var item in items) {
        await isar.boltzSwapDbModels.put(item.copyWith(walletId: walletId));
      }
    });
    migratedCount += items.length;
    offset += items.length;
  }
  if (migratedCount > 0) {
    _logger.debug('Migrated $migratedCount boltz swaps to include walletId');
  }

  // SwapOrderDbModel
  offset = 0;
  migratedCount = 0;
  while (true) {
    final items = await isar.swapOrderDbModels
        .filter()
        .walletIdIsNull()
        .offset(offset)
        .limit(_kMigrationBatchSize)
        .findAll();
    if (items.isEmpty) break;
    await isar.writeTxn(() async {
      for (var item in items) {
        await isar.swapOrderDbModels.put(item.copyWith(walletId: walletId));
      }
    });
    migratedCount += items.length;
    offset += items.length;
  }
  if (migratedCount > 0) {
    _logger.debug('Migrated $migratedCount swap orders to include walletId');
  }

  // PegOrderDbModel
  offset = 0;
  migratedCount = 0;
  while (true) {
    final items = await isar.pegOrderDbModels
        .filter()
        .walletIdIsNull()
        .offset(offset)
        .limit(_kMigrationBatchSize)
        .findAll();
    if (items.isEmpty) break;
    await isar.writeTxn(() async {
      for (var item in items) {
        await isar.pegOrderDbModels.put(item.copyWith(walletId: walletId));
      }
    });
    migratedCount += items.length;
    offset += items.length;
  }
  if (migratedCount > 0) {
    _logger.debug('Migrated $migratedCount peg orders to include walletId');
  }
}
