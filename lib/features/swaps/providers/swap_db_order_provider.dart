import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:isar/isar.dart';

final swapDBOrderProvider = AsyncNotifierProvider.family<SwapDBOrderNotifier,
    SwapOrderDbModel?, String>(() {
  return SwapDBOrderNotifier();
});

class SwapDBOrderNotifier
    extends FamilyAsyncNotifier<SwapOrderDbModel?, String> {
  @override
  FutureOr<SwapOrderDbModel?> build(String arg) async {
    try {
      final storage = await ref.watch(storageProvider.future);
      return await storage.swapOrderDbModels
          .where()
          .orderIdEqualTo(arg)
          .findFirst();
    } catch (e, st) {
      logger.error('Error fetching order by ID: $arg', e, st);
      return null;
    }
  }
}
