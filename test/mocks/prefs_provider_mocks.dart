import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockUserPreferencesNotifier extends Mock
    implements UserPreferencesNotifier {}

extension MockPrefsProviderX on MockUserPreferencesNotifier {
  void mockGetLanguageCodeCall(String value) {
    when(() => languageCode).thenReturn(value);
  }

  void mockGetBlockExplorerCall(String? value) {
    when(() => blockExplorer).thenReturn(value);
  }

  void mockGetRegionCall(String? value) {
    when(() => region).thenReturn(value);
  }

  void mockGetReferenceCurrencyCall(String value) {
    when(() => referenceCurrency).thenReturn(value);
  }

  void mockGetDarkModeCall(bool value) {
    when(() => isDarkMode(any())).thenReturn(value);
  }

  void mockGetBotevModeCall(bool value) {
    when(() => isBotevMode).thenReturn(value);
  }

  void mockGetDisplayUnitCall(SupportedDisplayUnits value) {
    when(() => displayUnits).thenReturn(value.value);
  }

  void mockGetNonLiquidUsdtWarningDisplayedCall(bool value) {
    when(() => isNonLiquidUsdtWarningDisplayed).thenReturn(value);
  }

  void mockGetLightningWarningDisplayedCall(bool value) {
    when(() => isLightningWarningDisplayed).thenReturn(value);
  }

  void mockMarkNonLiquidUsdtWarningDisplayedCall() {
    when(() => markNonLiquidUsdtWarningDisplayed()).thenAnswer((_) async {});
  }

  void mockMarkLightningWarningDisplayedCall() {
    when(() => markLightningWarningDisplayed()).thenAnswer((_) async {});
  }
}
