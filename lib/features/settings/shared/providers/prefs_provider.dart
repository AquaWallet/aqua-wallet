import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsProvider = ChangeNotifierProvider<UserPreferencesNotifier>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UserPreferencesNotifier(prefs);
});

class UserPreferencesNotifier extends ChangeNotifier {
  UserPreferencesNotifier(this._prefs);

  final SharedPreferences _prefs;

  // wallet has at least one transaction (used for backup notifications)
  bool get hasTransacted => _prefs.getBool(PrefKeys.hasTransacted) ?? false;
  Future<void> setTransacted({required bool hasTransacted}) async {
    _prefs.setBool(PrefKeys.hasTransacted, hasTransacted);
    notifyListeners();
  }

  //ANCHOR - Dark Mode

  bool get isDarkMode => _prefs.getBool(PrefKeys.darkMode) ?? false;

  Future<void> switchDarkMode() async {
    _prefs.setBool(PrefKeys.darkMode, !isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme({required bool dark}) async {
    _prefs.setBool(PrefKeys.darkMode, dark);
    notifyListeners();
  }

  //ANCHOR - Language

  String get languageCode =>
      _prefs.getString(PrefKeys.languageCode) ?? LanguageCodes.english;

  Future<void> setLanguageCode(String languageCode) async {
    _prefs.setString(PrefKeys.languageCode, languageCode);
    notifyListeners();
  }

  //ANCHOR - Hidden Languages

  bool get isHiddenLanguagesEnabled =>
      _prefs.getBool(PrefKeys.hiddenLanguages) ?? false;

  Future<bool> switchHiddenLanguages() async {
    final newValue = !isHiddenLanguagesEnabled;
    _prefs.setBool(PrefKeys.hiddenLanguages, newValue);
    notifyListeners();
    return newValue;
  }

  //ANCHOR Region

  String? get region => _prefs.getString(PrefKeys.region);

  Future<void> setRegion(String region) async {
    _prefs.setString(PrefKeys.region, region);
    notifyListeners();
  }

  Future<void> removeRegion() async {
    _prefs.remove(PrefKeys.region);
    notifyListeners();
  }

  //ANCHOR - Reference Exchange Rate

  String? get referenceCurrency => _prefs.getString(PrefKeys.exchangeRate);

  Future<void> setReferenceCurrency(String symbol) async {
    _prefs.setString(PrefKeys.exchangeRate, symbol);
    notifyListeners();
  }

  //ANCHOR - Block Explorer

  String? get blockExplorer => _prefs.getString(PrefKeys.blockExplorer);

  Future<void> setBlockExplorer(String name) async {
    _prefs.setString(PrefKeys.blockExplorer, name);
    notifyListeners();
  }

  //ANCHOR Enabled Assets

  List<String> get userAssetIds =>
      _prefs.getStringList(PrefKeys.userAssets) ?? [];

  Future<void> addAllAssets(List<String> assetIds) async {
    await _prefs.remove(PrefKeys.userAssets);
    await _prefs.setStringList(PrefKeys.userAssets, assetIds);
    notifyListeners();
  }

  Future<void> addAsset(String assetId) async {
    if (!userAssetIds.contains(assetId)) {
      final updated = [...userAssetIds, assetId];
      _prefs.setStringList(PrefKeys.userAssets, updated);
      notifyListeners();
    }
  }

  Future<void> removeAsset(String assetId) async {
    final updated = userAssetIds.where((id) => id != assetId).toList();
    _prefs.setStringList(PrefKeys.userAssets, updated);
    notifyListeners();
  }
}
