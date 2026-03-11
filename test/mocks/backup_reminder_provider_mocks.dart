import 'package:aqua/features/backup/backup.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupReminderNotifier extends ChangeNotifier
    with Mock
    implements BackupReminderNotifier {
  @override
  Future<void> setIsWalletBackedUp(bool value) async {}
}
