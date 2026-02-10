import 'package:aqua/features/settings/settings.dart';
import 'package:mocktail/mocktail.dart';

class ReferenceExchangeRateProviderMock extends Mock
    implements ReferenceExchangeRateProvider {}

extension ReferenceExchangeRateProviderMockX
    on ReferenceExchangeRateProviderMock {
  void mockGetAvailableCurrencies({required List<ExchangeRate> value}) {
    when(() => availableCurrencies).thenReturn(value);
  }

  void mockGetCurrentCurrency({required ExchangeRate value}) {
    when(() => currentCurrency).thenReturn(value);
  }

  void mockGetSourcesForCurrentCurrency(
      {required List<ExchangeRateSource> value}) {
    when(() => sourcesForCurrentCurrency(any())).thenReturn(value);
  }

  void mockSetReferenceCurrency({required ExchangeRate value}) {
    when(() => setReferenceCurrency(any())).thenAnswer((_) async {});
  }
}
