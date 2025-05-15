enum AppTheme {
  light,
  dark,
  deepOcean;

  static AppTheme byName(String name) {
    return switch (name) {
      'Light' => AppTheme.light,
      'Dark' => AppTheme.dark,
      'Deep Ocean' => AppTheme.deepOcean,
      _ => AppTheme.light,
    };
  }
}

extension AppThemeX on AppTheme {
  String get name => switch (this) {
        AppTheme.light => 'Light',
        AppTheme.dark => 'Dark',
        AppTheme.deepOcean => 'Deep Ocean',
      };
}
