import 'dart:io';

import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/settings/shared/pages/themes_settings_screen.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsProvider = ChangeNotifierProvider<UserPreferencesNotifier>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  final env = ref.read(envProvider);
  return UserPreferencesNotifier(prefs, env);
});

class UserPreferencesNotifier extends ChangeNotifier {
  UserPreferencesNotifier(this._prefs, this._env);

  final SharedPreferences _prefs;
  final Env _env;

  // wallet has at least one transaction (used for backup notifications)
  bool get hasTransacted => _prefs.getBool(PrefKeys.hasTransacted) ?? false;
  Future<void> setTransacted({required bool hasTransacted}) async {
    _prefs.setBool(PrefKeys.hasTransacted, hasTransacted);
    notifyListeners();
  }

  bool get isJan3CardExpanded =>
      _prefs.getBool(PrefKeys.jan3CardExpanded) ?? true;
  Future<void> setJan3CardExpanded({required bool isExpanded}) async {
    _prefs.setBool(PrefKeys.jan3CardExpanded, isExpanded);
    notifyListeners();
  }

  /// -------------------------------------------------------------------------------------
  /// Conversion currencies
  /// -------------------------------------------------------------------------------------
  List<String> get enabledConversionCurrencies =>
      _prefs.getStringList(PrefKeys.enabledConversionCurrencies) ?? [];

  Future<void> addConversionCurrency(String currencyCode) async {
    _prefs.setStringList(PrefKeys.enabledConversionCurrencies,
        [...enabledConversionCurrencies, currencyCode]);
    notifyListeners();
  }

  Future<void> removeConversionCurrency(String currencyCode) async {
    final enabled = enabledConversionCurrencies;
    enabled.remove(currencyCode);
    _prefs.setStringList(PrefKeys.enabledConversionCurrencies, enabled);
    notifyListeners();
  }
  // --------------------------------------------------------------------------------------

  //ANCHOR - Theme

  String get theme {
    final savedTheme = _prefs.getString(PrefKeys.theme);
    if (savedTheme != null) {
      return savedTheme;
    }

    // -------------------------------------------------------------------
    // Migration from the old system so user doesn't lose its saved theme
    // TODO: remove after some time
    // -------------------------------------------------------------------
    if (_prefs.getBool(PrefKeys.darkMode) == true) {
      _prefs.remove(PrefKeys.darkMode);
      _prefs.setString(PrefKeys.theme, AppTheme.dark.name);
      return AppTheme.dark.name;
    }

    if (_prefs.getBool(PrefKeys.botevMode) == true) {
      _prefs.remove(PrefKeys.botevMode);
      _prefs.setString(PrefKeys.theme, AppTheme.botev.name);
      return AppTheme.botev.name;
    }
    // -------------------------------------------------------------------

    return AppTheme.system.name;
  }

  Future<void> setTheme(AppTheme theme) async {
    await _prefs.setString(PrefKeys.theme, theme.name);
    notifyListeners();
  }

  //ANCHOR - Dark Mode

  bool isDarkMode(BuildContext context) {
    if (AppTheme.light.name == theme) {
      return false;
    }

    if ([AppTheme.dark.name, AppTheme.botev.name].contains(theme)) {
      return true;
    }

    // Access the brightness of the system theme
    final Brightness systemBrightness =
        MediaQuery.of(context).platformBrightness;

    return systemBrightness == Brightness.dark;
  }

  //ANCHOR - Botev Mode

  bool get isBotevMode => theme == AppTheme.botev.name;

  //ANCHOR - Balances Hidden

  bool get isBalanceHidden => _prefs.getBool(PrefKeys.balanceHidden) ?? false;

  Future<void> switchBalanceHidden() async {
    _prefs.setBool(PrefKeys.balanceHidden, !isBalanceHidden);
    notifyListeners();
  }

  //ANCHOR - Biometric Auth

  bool get isBiometricEnabled => _prefs.getBool(PrefKeys.biometric) ?? false;

  Future<void> switchBiometricAuth() async {
    _prefs.setBool(PrefKeys.biometric, !isBiometricEnabled);
    notifyListeners();
  }

  //ANCHOR - Language

  String get languageCode {
    final configuredLanguage = _prefs.getString(PrefKeys.languageCode);

    if (configuredLanguage != null) {
      // user has already configured language in app settings
      return configuredLanguage;
    }

    /**
     * per localeName docs:
     * 
     * localeName returns a language (e.g., "en")
     * a language and country code (e.g. "en_US", "de_AT"), or
     * a language, country code and character set (e.g. "en_US.UTF-8")
     * 
     * we only need the language value
     */
    final platformLocale = Platform.localeName.substring(0, 2);

    final isDeviceLocaleSupported = SupportedLanguageCodes.values
        .where((lc) => lc.value == platformLocale)
        .isNotEmpty;

    if (isDeviceLocaleSupported) {
      /**
       *  user has not yet configured language
       *  fallback to device locale if supported
       **/

      return platformLocale;
    }

    // default to English
    return SupportedLanguageCodes.english.value;
  }

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

  String? get customElectrumServerBtcUrl =>
      _prefs.getString(PrefKeys.customElectrumServerBtcUrl);

  Future<void> setCustomElectrumServerBtcUrl(String url) async {
    _prefs.setString(PrefKeys.customElectrumServerBtcUrl, url);
    notifyListeners();
  }

  String? get customElectrumServerLiquidUrl =>
      _prefs.getString(PrefKeys.customElectrumServerLiquidUrl);

  Future<void> setCustomElectrumServerLiquidUrl(String url) async {
    _prefs.setString(PrefKeys.customElectrumServerLiquidUrl, url);
    notifyListeners();
  }

  Future<void> removeCustomElectrumServerUrls() async {
    _prefs.remove(PrefKeys.customElectrumServerBtcUrl);
    _prefs.remove(PrefKeys.customElectrumServerLiquidUrl);
    notifyListeners();
  }

  //ANCHOR - Display Units

  String? get displayUnits => _prefs.getString(PrefKeys.displayUnits);

  Future<void> setDisplayUnits(String name) async {
    _prefs.setString(PrefKeys.displayUnits, name);
    notifyListeners();
  }

  //ANCHOR Enabled Assets
  String get _userAssetsKey {
    switch (_env) {
      case Env.mainnet:
        return PrefKeys.userAssets;
      case Env.testnet:
        return PrefKeys.userTestnetAssets;
      case Env.regtest:
        return PrefKeys.userRegtestAssets;
      default:
        return PrefKeys
            .userAssets; // Fallback to mainnet if somehow an unknown env is passed
    }
  }

  List<String> get userAssetIds => _prefs.getStringList(_userAssetsKey) ?? [];

  Future<void> addAllAssets(List<String> assetIds) async {
    await _prefs.remove(_userAssetsKey);
    await _prefs.setStringList(_userAssetsKey, assetIds);
    notifyListeners();
  }

  Future<void> addAsset(String assetId) async {
    if (!userAssetIds.contains(assetId)) {
      final updated = [...userAssetIds, assetId];
      await _prefs.setStringList(_userAssetsKey, updated);
      notifyListeners();
    }
  }

  Future<void> removeAsset(String assetId) async {
    final updated = userAssetIds.where((id) => id != assetId).toList();
    await _prefs.setStringList(_userAssetsKey, updated);
    notifyListeners();
  }

  Future<void> removeAllAssets() async {
    await _prefs.remove(_userAssetsKey);
    notifyListeners();
  }

  //ANCHOR - Direct Peg In

  bool get isDirectPegInEnabled =>
      _prefs.getBool(PrefKeys.directPegIn) ?? false;

  Future<void> switchDirectPegIn() async {
    _prefs.setBool(PrefKeys.directPegIn, !isDirectPegInEnabled);
    notifyListeners();
  }

  //ANCHOR - Transaction DB Restore Reminder

  bool get isTxnDatabaseRestoreReminded =>
      _prefs.getBool(PrefKeys.txnDbRestoreReminder) ?? false;

  Future<void> disableTxnDatabaseRestoreReminder() async {
    _prefs.setBool(PrefKeys.txnDbRestoreReminder, false);
    notifyListeners();
  }
}
