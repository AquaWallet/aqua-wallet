import 'package:aqua/features/settings/settings.dart';
import 'package:mocktail/mocktail.dart';

class MockPrefsProvider extends Mock implements UserPreferencesNotifier {}

extension MockPrefsProviderX on MockPrefsProvider {
  void mockGetLanguageCodeCall(String value) {
    when(() => languageCode).thenReturn(value);
  }

  void mockGetReferenceCurrencyCall(String value) {
    when(() => referenceCurrency).thenReturn(value);
  }
}
