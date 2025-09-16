import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/data/provider/isar_migration_provider.dart';
import 'package:coin_cz/features/boltz/models/db_models.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = CustomLogger(FeatureFlag.isar);

//ANCHOR - Isar Storage

final storageProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();

  _logger.debug('Opening Isar database');
  final isar = Isar.getInstance() ??
      await Isar.open(
        [
          TransactionDbModelSchema,
          SwapOrderDbModelSchema,
          BoltzSwapDbModelSchema,
          PegOrderDbModelSchema,
          SideshiftOrderDbModelSchema
        ],
        directory: dir.path,
      );

  final migrationManager = IsarMigrationManager(isar, prefs);
  await migrationManager.performMigrationIfNeeded();

  ref.onDispose(isar.close);
  return isar;
});
