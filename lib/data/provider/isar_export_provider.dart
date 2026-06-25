import 'package:aqua/data/provider/isar_database_provider.dart';
import 'package:aqua/data/services/isar_export_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isarExportServiceProvider = Provider<IsarExportService?>((ref) {
  final isarAsync = ref.watch(storageProvider);

  return isarAsync.whenOrNull(data: (isar) {
    final service = IsarExportService(isar);
    service.start();
    ref.onDispose(service.dispose);
    return service;
  });
});
