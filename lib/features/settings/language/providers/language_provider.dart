import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

enum SupportedLanguageCodes {
  albanian('sq', 'Shqip'),
  bulgarian('bg', 'Български'),
  catalan('ca', 'Català'),
  czech('cs', 'Čeština'),
  german('de', 'Deutsch'),
  english('en', 'English'),
  spanish('es', 'Español'),
  french('fr', 'Français'),
  hungarian('hu', 'Magyar'),
  italian('it', 'Italiano'),
  dutch('nl', 'Nederlands'),
  polish('pl', 'Polski'),
  portuguese('pt', 'Português'),
  serbian('sr', 'Srpski'),
  thai('th', 'ไทย');

  const SupportedLanguageCodes(this.value, this.displayName);

  final String value;
  final String displayName;
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
        Language(
          SupportedLanguageCodes.english.value,
          context.loc.languageSettingsEnglish,
          SupportedLanguageCodes.english.displayName,
          RegionsStatic.us,
        ),
        Language(
          SupportedLanguageCodes.spanish.value,
          context.loc.languageSettingsSpanish,
          SupportedLanguageCodes.spanish.displayName,
          RegionsStatic.es,
        ),
        Language(
          SupportedLanguageCodes.portuguese.value,
          context.loc.languageSettingsPortugal,
          SupportedLanguageCodes.portuguese.displayName,
          RegionsStatic.pt,
        ),
        Language(
          SupportedLanguageCodes.albanian.value,
          context.loc.languageSettingsAlbanian,
          SupportedLanguageCodes.albanian.displayName,
          RegionsStatic.sq,
        ),
        Language(
          SupportedLanguageCodes.catalan.value,
          context.loc.languageSettingsCatalan,
          SupportedLanguageCodes.catalan.displayName,
          RegionsStatic.catalonia,
        ),
        Language(
          SupportedLanguageCodes.german.value,
          context.loc.languageSettingsGerman,
          SupportedLanguageCodes.german.displayName,
          RegionsStatic.de,
        ),
        Language(
          SupportedLanguageCodes.french.value,
          context.loc.languageSettingsFrench,
          SupportedLanguageCodes.french.displayName,
          RegionsStatic.fr,
        ),
        Language(
          SupportedLanguageCodes.italian.value,
          context.loc.languageSettingsItalian,
          SupportedLanguageCodes.italian.displayName,
          RegionsStatic.it,
        ),
        Language(
          SupportedLanguageCodes.polish.value,
          context.loc.languageSettingsPolish,
          SupportedLanguageCodes.polish.displayName,
          RegionsStatic.pl,
        ),
        Language(
          SupportedLanguageCodes.serbian.value,
          context.loc.languageSettingsSerbian,
          SupportedLanguageCodes.serbian.displayName,
          RegionsStatic.rs,
        ),
        if (prefs.isHiddenLanguagesEnabled) ...[
          Language(
            SupportedLanguageCodes.bulgarian.value,
            context.loc.languageSettingsBulgarian,
            SupportedLanguageCodes.bulgarian.displayName,
            RegionsStatic.bg,
          ),
          Language(
            SupportedLanguageCodes.czech.value,
            context.loc.languageSettingsCzech,
            SupportedLanguageCodes.czech.displayName,
            RegionsStatic.cz,
          ),
          Language(
            SupportedLanguageCodes.dutch.value,
            context.loc.languageSettingsNederlands,
            SupportedLanguageCodes.dutch.displayName,
            RegionsStatic.nl,
          ),
          Language(
            SupportedLanguageCodes.hungarian.value,
            context.loc.languageSettingsHungarian,
            SupportedLanguageCodes.hungarian.displayName,
            RegionsStatic.hu,
          ),
          Language(
            SupportedLanguageCodes.thai.value,
            context.loc.languageSettingsThai,
            SupportedLanguageCodes.thai.displayName,
            RegionsStatic.th,
          ),
        ]
      ];

  Language get currentLanguage {
    final languageCode = prefs.languageCode;
    return supportedLanguages.firstWhere(
      (e) => e.languageCode == languageCode,
      orElse: () => supportedLanguages.first,
    );
  }

  Future<void> setCurrentLanguage(Language language) async {
    prefs.setLanguageCode(language.languageCode);
    notifyListeners();
  }
}
