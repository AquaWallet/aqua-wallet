import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/settings/settings.dart';

final exchangeRatesProvider =
    Provider.autoDispose<ReferenceExchangeRateProvider>((ref) {
  final prefs = ref.watch(prefsProvider);
  return ReferenceExchangeRateProvider(ref, prefs);
});

class ReferenceExchangeRateProvider extends ChangeNotifier {
  final ProviderRef ref;
  final UserPreferencesNotifier prefs;

  ReferenceExchangeRateProvider(this.ref, this.prefs);

  //TODO - To be fetched from GDK
  List<ExchangeRate> get availableExchangeRates => <ExchangeRate>[
        const ExchangeRate('United States Dollar', '\$', 'USD'),
        const ExchangeRate('Canadian Dollar', '\$', 'CAD'),
        const ExchangeRate('Great British Pound', '£', 'GBP'),
        const ExchangeRate('Euro', '€', 'EUR'),
      ];

  ExchangeRate get currentCurrency => availableExchangeRates.firstWhere(
        (e) => e.symbol.toLowerCase() == prefs.referenceCurrency?.toLowerCase(),
        orElse: () => availableExchangeRates.first,
      );

  Future<void> setReferenceCurrency(ExchangeRate currency) async {
    prefs.setReferenceCurrency(currency.symbol);
    notifyListeners();
  }
}
