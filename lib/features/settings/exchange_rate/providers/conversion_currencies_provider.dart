import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/settings/settings.dart';

final fiatRatesProvider = AsyncNotifierProvider.autoDispose<FiatRatesNotifier,
    List<BitcoinFiatRatesResponse>?>(FiatRatesNotifier.new);

class FiatRatesUnavailableError implements Exception {}

class FiatRatesNotifier
    extends AutoDisposeAsyncNotifier<List<BitcoinFiatRatesResponse>?> {
  @override
  FutureOr<List<BitcoinFiatRatesResponse>?> build() async {
    final client = ref.read(dioProvider);
    const endpoint =
        'https://btcpay.aquawallet.io/api/rates?storeId=331kH4p4q1TUSdGsfCSmkaDEsP7EmrgrVHGq7zY5SPg9';

    try {
      final response = await client.get(endpoint);
      final json = response.data as List<dynamic>;
      final feeRatesResponse =
          json.map((map) => BitcoinFiatRatesResponse.fromJson(map));
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
