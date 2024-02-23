import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

class LanguageCodes {
  static const english = 'en';
  static const spanish = 'es';
  static const dutch = 'nl';
  static const bulgarian = 'bg';
  static const czech = 'cs';
  static const catalan = 'ca';
}

final languageProvider =
    Provider.family.autoDispose<LanguageProvider, BuildContext>((ref, context) {
  final prefs = ref.watch(prefsProvider);
  return LanguageProvider(ref, context, prefs);
});

class LanguageProvider extends ChangeNotifier {
  final ProviderRef ref;
  final BuildContext context;
  final UserPreferencesNotifier prefs;

  LanguageProvider(this.ref, this.context, this.prefs);

  List<Language> get supportedLanguages => [
        Language(LanguageCodes.english),
        Language(LanguageCodes.spanish),
        Language(LanguageCodes.dutch),
        Language(LanguageCodes.bulgarian),

        if (prefs.isHiddenLanguagesEnabled) ...[
          //NOTE - Hidden languages go here
          Language(LanguageCodes.czech),
          Language(LanguageCodes.catalan)
        ]
      ];

  Language get currentLanguage => supportedLanguages.firstWhere(
        (e) => e.languageCode == prefs.languageCode,
        orElse: () => supportedLanguages.first,
      );

  Future<void> setCurrentLanguage(Language language) async {
    prefs.setLanguageCode(language.languageCode);
    notifyListeners();
  }
}
