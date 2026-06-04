import 'package:aqua/config/constants/pref_keys.dart';
import 'package:aqua/features/feature_flags/providers/setup_config_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

final lightningAddressNotificationProvider =
    ChangeNotifierProvider<LightningAddressNotificationProvider>((ref) {
  final isLnAddressEnabled = ref.watch(lnAddressRemoteFlagProvider);
  return LightningAddressNotificationProvider(
      isLnAddressEnabled, ref.read(sharedPreferencesProvider));
});

class LightningAddressNotificationProvider extends ChangeNotifier {
  LightningAddressNotificationProvider(this._isLnAddressEnabled, this._prefs);

  final bool _isLnAddressEnabled;
  final SharedPreferences _prefs;

  bool get shouldShowLightningAddressWelcomeScreen {
    if (!_isLnAddressEnabled) {
      return false;
    }
    return !(_prefs.getBool(PrefKeys.hasSeenLightningAddressWelcomeScreen) ??
        false);
  }

  Future<void> markWelcomeScreenAsSeen() async {
    await _prefs.setBool(PrefKeys.hasSeenLightningAddressWelcomeScreen, true);
    notifyListeners();
  }

  Future<void> resetWelcomeScreenForDebug() async {
    await _prefs.setBool(PrefKeys.hasSeenLightningAddressWelcomeScreen, false);
    notifyListeners();
  }
}
