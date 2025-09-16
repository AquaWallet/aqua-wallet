import 'package:coin_cz/common/decimal/decimal_ext.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/sideshift/sideshift.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = CustomLogger(FeatureFlag.isar);

const String kSwapOrderVersionKey = 'swap_order_version';

class IsarMigrationManager {
  final Isar isar;
  final SharedPreferences prefs;

  IsarMigrationManager(this.isar, this.prefs);

  Future<void> performMigrationIfNeeded() async {
    final currentVersion =
        prefs.getInt(kSwapOrderVersionKey) ?? DatabaseMigration.initial.version;
    _logger.debug('Current $kSwapOrderVersionKey: $currentVersion');

    if (currentVersion < DatabaseMigration.latestVersion) {
      for (var version = currentVersion;
          version < DatabaseMigration.latestVersion;
          version++) {
        final nextMigration = DatabaseMigration.fromVersion(version + 1);
        if (nextMigration != null) {
          _logger.info(
              'Migrating to version ${nextMigration.version}: ${nextMigration.description}');
          await _migrateToNextVersion(nextMigration);
          await prefs.setInt(kSwapOrderVersionKey, nextMigration.version);
          _logger.info(
              'Updated $kSwapOrderVersionKey to ${nextMigration.version}');
        } else {
          _logger.warning('Unknown database version: ${version + 1}');
          break;
        }
      }
    } else {
      _logger.debug('No migration needed, already at version $currentVersion');
    }
  }

  Future<void> _migrateToNextVersion(DatabaseMigration migration) async {
    switch (migration) {
      case DatabaseMigration.sideshiftToSwapOrder:
        await _migrateV1ToV2();
        break;
      case DatabaseMigration.initial:
        // No migration needed for initial version
        break;
    }
  }

  Future<void> _migrateV1ToV2() async {
    try {
      final orderCount = await isar.sideshiftOrderDbModels.count();
      _logger
          .debug('Total SideshiftOrderDbModel objects to migrate: $orderCount');

      for (var i = 0; i < orderCount; i += 50) {
        _logger.debug('Migrating batch starting at index $i');
        final orders = await isar.sideshiftOrderDbModels
            .where()
            .offset(i)
            .limit(50)
            .findAll();

        await isar.writeTxn(() async {
          for (var order in orders) {
            try {
              final swapOrder = SwapOrderDbModel(
                id: order.id,
                orderId: order.orderId,
                createdAt: order.createdAt ?? DateTime.now(),
                fromAsset: order.depositCoin ?? '',
                toAsset: order.settleCoin ?? '',
                depositAddress: order.depositAddress ?? '',
                settleAddress: order.settleAddress ?? '',
                depositAmount: order.depositAmount ?? '',
                settleAmount: order.settleAmount ?? '',
                serviceFeeType: SwapFeeType.percentageFee,
                serviceFeeValue:
                    DecimalExt.fromDouble(kSideshiftServiceFee).toString(),
                serviceFeeCurrency: SwapFeeCurrency.usd,
                depositCoinNetworkFee: null,
                settleCoinNetworkFee: null,
                expiresAt: order.expiresAt,
                status: SwapOrderStatus.values.firstWhere(
                  (s) => s.toString() == 'SwapOrderStatus.${order.status}',
                  orElse: () => SwapOrderStatus.unknown,
                ),
                type: SwapOrderType.values.firstWhere(
                  (t) => t.toString() == 'SwapOrderType.${order.type}',
                  orElse: () => SwapOrderType.variable,
                ),
                serviceType: SwapServiceSource.sideshift,
                onchainTxHash: order.onchainTxHash,
              );

              await isar.swapOrderDbModels.put(swapOrder);
              await isar.sideshiftOrderDbModels.delete(order.id);
            } catch (e) {
              _logger.error('Error migrating order ${order.id}: $e');
            }
          }
        });
        _logger.debug(
            'Completed migrating batch ending at index ${i + orders.length}');
      }

      _logger.info('Migration from version 1 to 2 completed successfully');
    } catch (e) {
      _logger.error('Error during migration: $e');
      rethrow;
    }
  }
}

enum DatabaseMigration {
  initial(1, 'Initial database setup'),
  sideshiftToSwapOrder(
      2, 'Migrate from SideshiftOrderDbModel to SwapOrderDbModel');

  final int version;
  final String description;

  const DatabaseMigration(this.version, this.description);

  static DatabaseMigration? fromVersion(int version) {
    try {
      return DatabaseMigration.values.firstWhere(
        (migration) => migration.version == version,
      );
    } catch (e) {
      return null;
    }
  }

  static int get latestVersion => DatabaseMigration.values.last.version;
}
