import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupReminderPrefKeys {
  static const backupReminderHintLastShown = 'backup_reminder_hint_last_shown';
  static const backupFlowLastShown = 'backup_flow_last_shown';
  static const isWalletBackedUp = 'wallet_backed_up';
}

/// Set a prefs.hasTransacted flag when wallet has at least one transaction, Bitcoin or Liquid.
/// We use this flag for backup trigger logic.
final hasTransactedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final prefs = ref.read(prefsProvider);
  if (prefs.hasTransacted) {
    return true;
  }

  final btcTrx = await ref.read(bitcoinProvider).getTransactions();
  if (btcTrx != null && btcTrx.isNotEmpty) {
    prefs.setTransacted(hasTransacted: true);
    return true;
  }

  final liquidTrx = await ref.read(liquidProvider).getTransactions();
  if (liquidTrx != null && liquidTrx.isNotEmpty) {
    prefs.setTransacted(hasTransacted: true);
    return true;
  }

  return false;
});

final backupReminderProvider =
    ChangeNotifierProvider<BackupReminderNotifier>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return BackupReminderNotifier(prefs);
});

class BackupReminderNotifier extends ChangeNotifier {
  BackupReminderNotifier(this._prefs);

  final SharedPreferences _prefs;

  // Clear method
  Future<void> clear() async {
    await _prefs.remove(BackupReminderPrefKeys.backupFlowLastShown);
    await _prefs.setBool(BackupReminderPrefKeys.isWalletBackedUp, false);
  }

  //ANCHOR - Show Main Backup Flow?
  static const Duration backupReminderLastShownExpiration = Duration(hours: 24);

  bool get shouldShowBackupFlow {
    final isWalletBackedUp =
        _prefs.getBool(BackupReminderPrefKeys.isWalletBackedUp) ?? false;
    if (isWalletBackedUp) {
      return false;
    }

    // only show if 24 hours have passed since last shown
    if (backupFlowLastShown == null) return true;

    return DateTime.now().difference(backupFlowLastShown!) >
        backupReminderLastShownExpiration;
  }

  DateTime? get backupFlowLastShown {
    final dateString =
        _prefs.getString(BackupReminderPrefKeys.backupFlowLastShown);
    if (dateString == null) {
      return null;
    }
    return DateTime.tryParse(dateString);
  }

  Future<void> setBackupFlowLastShown({DateTime? date}) async {
    final dateString = (date ?? DateTime.now()).toIso8601String();
    await _prefs.setString(
        BackupReminderPrefKeys.backupFlowLastShown, dateString);
    notifyListeners();
  }

  Future<void> setIsWalletBackedUp(bool isBackedUp) async {
    _prefs.setBool(BackupReminderPrefKeys.isWalletBackedUp, isBackedUp);
    notifyListeners();
  }
}
