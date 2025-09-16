import 'dart:async';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

final fiatRatesProvider =
    AsyncNotifierProvider<FiatRatesNotifier, List<BitcoinFiatRatesResponse>>(
        FiatRatesNotifier.new);

class FiatRatesUnavailableError implements Exception {}

class FiatRatesNotifier extends AsyncNotifier<List<BitcoinFiatRatesResponse>> {
  @override
  FutureOr<List<BitcoinFiatRatesResponse>> build() async {
    final client = ref.read(dioProvider);
    const endpoint =
        'https://btcpay.aquawallet.io/api/rates?storeId=6pQ5dngUNiack4TKgoehPFxDzwoXX961mYjHgWMrZC6X';

    try {
      final response = await client.get(endpoint);
      final json = response.data as List<dynamic>;
      final feeRatesResponse =
          json.map((map) => BitcoinFiatRatesResponse.fromJson(map));
      ref.refreshAfter(const Duration(seconds: 15));
      return feeRatesResponse.toList();
    } catch (e) {
      throw FiatRatesUnavailableError();
    }
  }
}

final conversionCurrenciesProvider =
    Provider.autoDispose<ConversionCurrenciesProvider>((ref) {
  final prefs = ref.watch(prefsProvider);
  final fiatRates = ref.watch(fiatRatesProvider).asData?.value;
  return ConversionCurrenciesProvider(ref, prefs, fiatRates);
});

class ConversionCurrenciesProvider extends ChangeNotifier {
  final ProviderRef ref;
  final UserPreferencesNotifier prefs;
  final List<BitcoinFiatRatesResponse>? fiatRates;

  ConversionCurrenciesProvider(this.ref, this.prefs, this.fiatRates);

  List<BitcoinFiatRatesResponse> get availableCurrencies {
    fiatRates?.sort((a, b) => a.code.compareTo(b.code));
    return fiatRates ?? [];
  }

  List<String> get enabledCurrencies {
    final referenceCurrency = prefs.referenceCurrency;
    if (referenceCurrency != null &&
        !prefs.enabledConversionCurrencies.contains(referenceCurrency)) {
      // configured reference currency should always be enabled
      return [...prefs.enabledConversionCurrencies, referenceCurrency];
    }

    return prefs.enabledConversionCurrencies;
  }

  Future<void> addCurrency(String currencyCode) async {
    prefs.addConversionCurrency(currencyCode);
    notifyListeners();
  }

  Future<void> removeCurrency(String currencyCode) async {
    prefs.removeConversionCurrency(currencyCode);
    notifyListeners();
  }
}
