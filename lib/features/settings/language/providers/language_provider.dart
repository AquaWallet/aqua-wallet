import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

// System languages that are supported by the app.
enum SupportedLanguageCodes {
  albanian('sq', 'Shqip'),
  arabic('ar', 'العربية'),
  catalan('ca', 'Català'),
  chinese('zh', '中文简体'),
  english('en', 'English'),
  french('fr', 'Français'),
  german('de', 'Deutsch'),
  italian('it', 'Italiano'),
  polish('pl', 'Polski'),
  portuguese('pt', 'Português'),
  serbian('sr', 'Srpski'),
  spanish('es', 'Español');

  const SupportedLanguageCodes(this.value, this.displayName);

  final String value;
  final String displayName;
}

// System languages that are hidden behind the [isHiddenLanguagesEnabled] flag.
enum HiddenLanguageCodes {
  bulgarian('bg', 'Български'),
  czech('cs', 'Čeština'),
  dutch('nl', 'Nederlands'),
  hungarian('hu', 'Magyar'),
  thai('th', 'ไทย');

  const HiddenLanguageCodes(this.value, this.displayName);

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
          SupportedLanguageCodes.arabic.value,
          context.loc.languageSettingsArabic,
          SupportedLanguageCodes.arabic.displayName,
          RegionsStatic.sa,
        ),
        Language(
          SupportedLanguageCodes.catalan.value,
          context.loc.languageSettingsCatalan,
          SupportedLanguageCodes.catalan.displayName,
          RegionsStatic.catalonia,
        ),
        Language(
          SupportedLanguageCodes.chinese.value,
          context.loc.languageSettingsChineseSimplified,
          SupportedLanguageCodes.chinese.displayName,
          RegionsStatic.cn,
        ),
        Language(
          SupportedLanguageCodes.french.value,
          context.loc.languageSettingsFrench,
          SupportedLanguageCodes.french.displayName,
          RegionsStatic.fr,
        ),
        Language(
          SupportedLanguageCodes.german.value,
          context.loc.languageSettingsGerman,
          SupportedLanguageCodes.german.displayName,
          RegionsStatic.de,
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
            HiddenLanguageCodes.bulgarian.value,
            context.loc.languageSettingsBulgarian,
            HiddenLanguageCodes.bulgarian.displayName,
            RegionsStatic.bg,
          ),
          Language(
            HiddenLanguageCodes.czech.value,
            context.loc.languageSettingsCzech,
            HiddenLanguageCodes.czech.displayName,
            RegionsStatic.cz,
          ),
          Language(
            HiddenLanguageCodes.dutch.value,
            context.loc.languageSettingsNederlands,
            HiddenLanguageCodes.dutch.displayName,
            RegionsStatic.nl,
          ),
          Language(
            HiddenLanguageCodes.hungarian.value,
            context.loc.languageSettingsHungarian,
            HiddenLanguageCodes.hungarian.displayName,
            RegionsStatic.hu,
          ),
          Language(
            HiddenLanguageCodes.thai.value,
            context.loc.languageSettingsThai,
            HiddenLanguageCodes.thai.displayName,
            RegionsStatic.th,
          ),
        ],
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
