import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

enum SupportedLanguageCodes {
  english('en'),
  spanish('es'),
  portuguese('pt'),
  dutch('nl'),
  bulgarian('bg'),
  czech('cs'),
  catalan('ca');

  const SupportedLanguageCodes(this.value);

  final String value;
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
        Language(SupportedLanguageCodes.english.value),
        Language(SupportedLanguageCodes.spanish.value),
        Language(SupportedLanguageCodes.dutch.value),
        Language(SupportedLanguageCodes.bulgarian.value),
        Language(SupportedLanguageCodes.portuguese.value),
        if (prefs.isHiddenLanguagesEnabled) ...[
          //NOTE - Hidden languages go here
          Language(SupportedLanguageCodes.czech.value),
          Language(SupportedLanguageCodes.catalan.value)
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
