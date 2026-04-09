import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

final exportLogsProvider =
    AutoDisposeAsyncNotifierProvider<ExportLogsNotifier, void>(
        ExportLogsNotifier.new);

class ExportLogsNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> export({Rect? sharePositionOrigin}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final logs = logger.internalLogger.history.text(
        timeFormat: logger.internalLogger.settings.timeFormat,
      );
      final fmtDate = DateTime.now().toString().replaceAll(":", " ");
      final filePath = await ref.read(fileSystemProvider).writeToTemp(
            logs,
            fileName: 'aqua_logs_$fmtDate.txt',
          );
      await Share.shareXFiles(
        [XFile(filePath)],
        sharePositionOrigin: sharePositionOrigin,
      );
    });
  }
}
