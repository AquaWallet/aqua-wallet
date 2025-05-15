import 'package:aqua/features/account/models/api_models.dart';
import 'package:aqua/features/shared/shared.dart';

class Language {
  final String languageCode;

  Language(this.languageCode);
}

extension LanguageExtension on Language {
  AnkaraLanguages? get toAnkaraLanguage {
    return AnkaraLanguages.values
            .firstWhereOrNull((e) => e.code == languageCode) ??
        AnkaraLanguages.english;
  }
}
