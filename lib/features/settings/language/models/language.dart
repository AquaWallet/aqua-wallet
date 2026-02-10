import 'package:aqua/features/account/models/api_models.dart';
import 'package:aqua/features/settings/region/models/region.dart';
import 'package:aqua/features/shared/shared.dart';

class Language {
  final String languageCode;
  final String originalLanguageName;
  final String translatedLanguageName;
  final Region region;

  Language(
    this.languageCode,
    this.translatedLanguageName,
    this.originalLanguageName,
    this.region,
  );
}

extension LanguageExtension on Language {
  AnkaraLanguages? get toAnkaraLanguage {
    return AnkaraLanguages.values
            .firstWhereOrNull((e) => e.code == languageCode) ??
        AnkaraLanguages.english;
  }
}
