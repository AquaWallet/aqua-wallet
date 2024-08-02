import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

//ANCHOR - Isar Storage

final storageProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = Isar.getInstance() ??
      await Isar.open(
        [
          TransactionDbModelSchema,
          SideshiftOrderDbModelSchema,
          BoltzSwapDbModelSchema,
        ],
        directory: dir.path,
      );
  ref.onDispose(isar.close);
  return isar;
});
