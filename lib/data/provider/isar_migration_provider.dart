import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = CustomLogger(FeatureFlag.isar);

const kSwapOrderVersionKey = 'swap_order_version';
const kTransactionVersionKey = 'transaction_version';
const kV2BatchSize = 50;
const kV4BatchSize = 100;

class IsarMigrationManager {
  final Isar isar;
  final SharedPreferences prefs;

  IsarMigrationManager(this.isar, this.prefs);

  Future<void> performMigrationIfNeeded() async {
    final swapOrderVersion =
        prefs.getInt(kSwapOrderVersionKey) ?? DatabaseMigration.initial.version;
    final transactionVersion = prefs.getInt(kTransactionVersionKey) ??
        DatabaseMigration.initial.version;

    if (swapOrderVersion < DatabaseMigration.sideshiftToSwapOrder.version) {
      await _migrateV1ToV2();
      await prefs.setInt(
          kSwapOrderVersionKey, DatabaseMigration.sideshiftToSwapOrder.version);
    }

    if (transactionVersion <
        DatabaseMigration.addSwapServiceSourceToTransactions.version) {
      await _migrateTransactionsToV4();
      await prefs.setInt(kTransactionVersionKey,
          DatabaseMigration.addSwapServiceSourceToTransactions.version);
    }
  }

  Future<void> _migrateV1ToV2() async {
    try {
      final orderCount = await isar.sideshiftOrderDbModels.count();
      _logger
          .debug('Total SideshiftOrderDbModel objects to migrate: $orderCount');

      for (var i = 0; i < orderCount; i += kV2BatchSize) {
        _logger.debug('Migrating batch starting at index $i');
        final orders = await isar.sideshiftOrderDbModels
            .where()
            .offset(i)
            .limit(kV2BatchSize)
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

  Future<void> _migrateTransactionsToV4() async {
    try {
      _logger.debug('Migrating transactions to include swapServiceSource');

      final txCount = await isar.transactionDbModels.count();
      _logger.debug('Total transactions to check: $txCount');

      var migratedCount = 0;

      await isar.writeTxn(() async {
        for (var i = 0; i < txCount; i += kV4BatchSize) {
          final transactions = await isar.transactionDbModels
              .where()
              .offset(i)
              .limit(kV4BatchSize)
              .findAll();

          for (var tx in transactions) {
            if (!tx.isUSDtSwap ||
                tx.swapServiceSource != null ||
                tx.serviceOrderId == null) {
              continue;
            }

            try {
              final swapOrder = await isar.swapOrderDbModels
                  .where()
                  .orderIdEqualTo(tx.serviceOrderId!)
                  .findFirst();

              if (swapOrder != null) {
                final updated = tx.copyWith(
                  swapServiceSource: swapOrder.serviceType,
                );
                await isar.transactionDbModels.put(updated);
                migratedCount++;
                _logger.debug(
                  'Updated transaction ${tx.id} with swapServiceSource: ${swapOrder.serviceType}',
                );
              } else {
                _logger.warning(
                  'Swap order not found for transaction ${tx.id} with serviceOrderId: ${tx.serviceOrderId}',
                );
              }
            } catch (e) {
              _logger.error(
                'Error migrating transaction ${tx.id}: $e',
              );
            }
          }

          _logger
              .debug('Processed batch ${i + 1} to ${i + transactions.length}');
        }
      });

      _logger.info(
        'Transaction migration to V4 completed successfully. Migrated $migratedCount transactions.',
      );
    } catch (e, stack) {
      _logger.error('Error during transaction migration to V4: $e\n$stack');
      rethrow;
    }
  }
}

enum DatabaseMigration {
  initial(1, 'Initial database setup'),
  sideshiftToSwapOrder(
      2, 'Migrate from SideshiftOrderDbModel to SwapOrderDbModel'),
  addWalletIdToTransactions(3, 'Add walletId field to transactions'),
  addSwapServiceSourceToTransactions(
      4, 'Add swapServiceSource to existing USDt swap transactions');

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
