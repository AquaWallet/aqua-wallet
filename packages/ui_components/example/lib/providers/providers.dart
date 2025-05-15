import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/models/models.dart';

final _lightTheme = AquaLightTheme();
final _darkTheme = AquaDarkTheme();
final _deepOceanTheme = AquaDeepOceanTheme();

final themeProvider = Provider<ThemeData>((ref) {
  final selectedTheme = ref.watch(prefsProvider).selectedTheme;
  return switch (selectedTheme) {
    AppTheme.light => _lightTheme.themeData,
    AppTheme.dark => _darkTheme.themeData,
    AppTheme.deepOcean => _deepOceanTheme.themeData,
  };
});

final sharedPreferencesProvider = Provider.autoDispose<SharedPreferences>((_) {
  throw UnimplementedError('SharedPreferencesProvider is not implemented');
});

final prefsProvider = ChangeNotifierProvider<UserPreferencesNotifier>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UserPreferencesNotifier(prefs);
});

class UserPreferencesNotifier extends ChangeNotifier {
  UserPreferencesNotifier(this._prefs);

  static const _selectedThemeKey = 'selectedTheme';

  final SharedPreferences _prefs;

  AppTheme get selectedTheme {
    final theme = _prefs.getString(_selectedThemeKey);
    return theme == null ? AppTheme.light : AppTheme.byName(theme);
  }

  Future<void> switchTheme(AppTheme theme) async {
    _prefs.setString(_selectedThemeKey, theme.name);
    notifyListeners();
  }
}
