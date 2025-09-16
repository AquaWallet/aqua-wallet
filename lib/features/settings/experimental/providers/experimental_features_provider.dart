import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

final featureFlagsProvider =
    ChangeNotifierProvider<FeatureFlagsNotifier>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return FeatureFlagsNotifier(prefs);
});

class FeatureFlagsNotifier extends ChangeNotifier {
  FeatureFlagsNotifier(this._prefs);

  final SharedPreferences _prefs;

  bool get multipleOnramps => _prefs.getBool(PrefKeys.multipleOnramps) ?? false;

  bool get addNoteEnabled => _prefs.getBool(PrefKeys.addNoteEnabled) ?? false;

  bool get statusIndicator => _prefs.getBool(PrefKeys.statusIndicator) ?? false;

  bool get lnurlWithdrawEnabled =>
      _prefs.getBool(PrefKeys.lnurlWithdrawEnabled) ?? false;

  bool get pokerChipSweepEnabled =>
      _prefs.getBool(PrefKeys.pokerChipSweepEnabled) ?? false;

  bool get forceBoltzFailedNormalSwapEnabled =>
      _prefs.getBool(PrefKeys.forceBoltzFailedNormalSwapEnabled) ?? false;

  bool get fakeBroadcastsEnabled =>
      _prefs.getBool(PrefKeys.fakeBroadcastsEnabled) ?? false;

  bool get activateSubaccountsEnabled =>
      _prefs.getBool(PrefKeys.activateSubaccountsEnabled) ?? false;

  bool get throwAquaBroadcastErrorEnabled =>
      _prefs.getBool(PrefKeys.throwAquaBroadcastErrorEnabled) ?? false;

  bool get dbExportEnabled => _prefs.getBool(PrefKeys.dbExportEnabled) ?? false;

  bool get forceAquaNodeNotSyncedEnabled =>
      _prefs.getBool(PrefKeys.forceAquaNodeNotSyncedEnabled) ?? false;

  bool get changellyForUSDtSwapsEnabled =>
      _prefs.getBool(PrefKeys.changellyForUSDtSwapsEnabled) ?? false;

  bool get btcDirectEnabled =>
      _prefs.getBool(PrefKeys.btcDirectEnabled) ?? true;

  bool get seedQrEnabled => _prefs.getBool(PrefKeys.seedQrEnabled) ?? false;

  bool get myFirstBitcoinEnabled =>
      _prefs.getBool(PrefKeys.myFirstBitcoinEnabled) ?? false;

  bool get payWithMoonEnabled =>
      _prefs.getBool(PrefKeys.payWithMoonEnabled) ?? false;

  bool get customElectrumUrlEnabled =>
      _prefs.getBool(PrefKeys.customElectrumUrlEnabled) ?? false;

  bool get debitCardStagingEnabled =>
      _prefs.getBool(PrefKeys.debitCardStagingEnabled) ?? false;

  void toggleFeatureFlag({
    required String key,
    required bool currentValue,
  }) {
    _prefs.setBool(key, !currentValue);
    notifyListeners();
  }
}
