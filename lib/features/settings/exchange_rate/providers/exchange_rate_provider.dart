import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final Map<FiatCurrency, ExchangeRate> currencyModelLookup = {
  FiatCurrency.usd:
      const ExchangeRate(FiatCurrency.usd, ExchangeRateSource.bitstamp),
  FiatCurrency.eur:
      const ExchangeRate(FiatCurrency.eur, ExchangeRateSource.kraken),
  FiatCurrency.cad:
      const ExchangeRate(FiatCurrency.cad, ExchangeRateSource.bullbitcoin),
  FiatCurrency.gbp:
      const ExchangeRate(FiatCurrency.gbp, ExchangeRateSource.coingecko),
  FiatCurrency.chf:
      const ExchangeRate(FiatCurrency.chf, ExchangeRateSource.coingecko),
  FiatCurrency.aud:
      const ExchangeRate(FiatCurrency.aud, ExchangeRateSource.coingecko),
  FiatCurrency.brl:
      const ExchangeRate(FiatCurrency.brl, ExchangeRateSource.coingecko),
  FiatCurrency.cny:
      const ExchangeRate(FiatCurrency.cny, ExchangeRateSource.coingecko),
  FiatCurrency.czk:
      const ExchangeRate(FiatCurrency.czk, ExchangeRateSource.coingecko),
  FiatCurrency.dkk:
      const ExchangeRate(FiatCurrency.dkk, ExchangeRateSource.coingecko),
  FiatCurrency.hkd:
      const ExchangeRate(FiatCurrency.hkd, ExchangeRateSource.coingecko),
  FiatCurrency.ils:
      const ExchangeRate(FiatCurrency.ils, ExchangeRateSource.coingecko),
  FiatCurrency.inr:
      const ExchangeRate(FiatCurrency.inr, ExchangeRateSource.coingecko),
  FiatCurrency.jpy:
      const ExchangeRate(FiatCurrency.jpy, ExchangeRateSource.coingecko),
  FiatCurrency.mxn:
      const ExchangeRate(FiatCurrency.mxn, ExchangeRateSource.coingecko),
  FiatCurrency.myr:
      const ExchangeRate(FiatCurrency.myr, ExchangeRateSource.coingecko),
  FiatCurrency.ngn:
      const ExchangeRate(FiatCurrency.ngn, ExchangeRateSource.coingecko),
  FiatCurrency.nok:
      const ExchangeRate(FiatCurrency.nok, ExchangeRateSource.coingecko),
  FiatCurrency.nzd:
      const ExchangeRate(FiatCurrency.nzd, ExchangeRateSource.coingecko),
  FiatCurrency.pln:
      const ExchangeRate(FiatCurrency.pln, ExchangeRateSource.coingecko),
  FiatCurrency.rub:
      const ExchangeRate(FiatCurrency.rub, ExchangeRateSource.coingecko),
  FiatCurrency.sek:
      const ExchangeRate(FiatCurrency.sek, ExchangeRateSource.coingecko),
  FiatCurrency.sgd:
      const ExchangeRate(FiatCurrency.sgd, ExchangeRateSource.coingecko),
  FiatCurrency.thb:
      const ExchangeRate(FiatCurrency.thb, ExchangeRateSource.coingecko),
  FiatCurrency.turkishLira: const ExchangeRate(
      FiatCurrency.turkishLira, ExchangeRateSource.coingecko),
  FiatCurrency.vnd:
      const ExchangeRate(FiatCurrency.vnd, ExchangeRateSource.coingecko),
  FiatCurrency.zar:
      const ExchangeRate(FiatCurrency.zar, ExchangeRateSource.coingecko),
};

final gdkSettingsProvider =
    AsyncNotifierProvider<GdkSettingsNotifier, GdkSettingsEvent>(
        GdkSettingsNotifier.new);

class GdkSettingsNotifier extends AsyncNotifier<GdkSettingsEvent> {
  @override
  FutureOr<GdkSettingsEvent> build() async {
    final settings = await ref.read(liquidProvider).getSettings();
    final userReferenceCurrency = ref.read(prefsProvider).referenceCurrency;
    final userPriceSource = ref.read(prefsProvider).priceSource;

    // If user has a saved currency preference, ensure GDK uses it
    if (userReferenceCurrency != null &&
        (settings.pricing?.currency?.toLowerCase() !=
                userReferenceCurrency.toLowerCase() ||
            settings.pricing?.exchange?.toLowerCase() !=
                userPriceSource?.toLowerCase())) {
      // Get the exchange rate from lookup (includes default source for the currency)
      final currencyEnum = FiatCurrency.values.firstWhereOrNull(
        (c) => c.value.toLowerCase() == userReferenceCurrency.toLowerCase(),
      );
      final exchangeRate =
          currencyEnum != null ? currencyModelLookup[currencyEnum] : null;

      if (exchangeRate != null) {
        // Apply user's saved preference to GDK
        final newGdkSettings = GdkSettingsEvent(
          pricing: GdkPricing(
            currency: exchangeRate.currency.value,
            exchange: userPriceSource ?? exchangeRate.source.value,
          ),
        );
        await ref.read(bitcoinProvider).changeSettings(newGdkSettings);
        await ref.read(liquidProvider).changeSettings(newGdkSettings);

        // Return the updated settings
        return await ref.read(liquidProvider).getSettings();
      }
    }

    if (ref.read(prefsProvider).referenceCurrency == null &&
        settings.pricing?.currency != null) {
      // keep configured currency in pref state, if not already available
      await ref
          .read(prefsProvider)
          .setReferenceCurrency(settings.pricing!.currency!);
      logger.debug(
          '[Settings] Reference currency not set. Setting ${settings.pricing!.currency}');
    }

    return settings;
  }

  Future<void> change(GdkSettingsEvent settings) async {
    await ref.read(bitcoinProvider).changeSettings(settings);
    await ref.read(liquidProvider).changeSettings(settings);

    final newSettings = await ref.read(liquidProvider).getSettings();
    state = AsyncValue.data(newSettings);
  }
}

final gdkCurrenciesProvider =
    AsyncNotifierProvider<GdkCurrenciesNotifier, GdkCurrencyData?>(
        GdkCurrenciesNotifier.new);

class GdkCurrenciesNotifier extends AsyncNotifier<GdkCurrencyData?> {
  @override
  FutureOr<GdkCurrencyData?> build() async {
    final response = await ref.read(liquidProvider).getAvailableCurrencies();
    return response;
  }
}

final exchangeRatesProvider = Provider<ReferenceExchangeRateProvider>((ref) {
  // Only watch the specific preferences that affect exchange rates
  ref.watch(prefsProvider.select((p) => p.referenceCurrency));
  ref.watch(prefsProvider.select((p) => p.priceSource));
  final prefs = ref.read(prefsProvider);
  final availableCurrencies = ref.watch(gdkCurrenciesProvider).asData?.value;
  ref.watch(gdkSettingsProvider);
  return ReferenceExchangeRateProvider(ref, prefs, availableCurrencies);
});

class ReferenceExchangeRateProvider extends ChangeNotifier {
  final ProviderRef ref;
  final UserPreferencesNotifier prefs;
  final GdkCurrencyData? gdkAvailableCurrencies;

  ReferenceExchangeRateProvider(
      this.ref, this.prefs, this.gdkAvailableCurrencies);

  List<ExchangeRate> get availableCurrencies {
    if (gdkAvailableCurrencies == null || gdkAvailableCurrencies!.all == null) {
      return [];
    }

    return currencyModelLookup.values
        .where((er) =>
            gdkAvailableCurrencies!.all!.contains(er.currency.value) &&
            gdkAvailableCurrencies!.perExchange!.containsKey(er.source.value) &&
            gdkAvailableCurrencies!.perExchange![er.source.value]!
                .contains(er.currency.value))
        .toList();
  }

  ExchangeRate get currentCurrency {
    final localCurrency = prefs.referenceCurrency?.toLowerCase();
    final localSource = prefs.priceSource?.toLowerCase();

    if (gdkAvailableCurrencies == null ||
        gdkAvailableCurrencies?.perExchange == null ||
        gdkAvailableCurrencies!.perExchange!.isEmpty) {
      return usdCurrency;
    }

    for (final entry in gdkAvailableCurrencies!.perExchange!.entries) {
      final source = entry.key.toLowerCase();
      final currencies = (entry.value).map((c) => c.toLowerCase());

      if (source == localSource && currencies.contains(localCurrency)) {
        final currencyEnum = FiatCurrency.values.firstWhere(
          (c) => c.value.toLowerCase() == localCurrency,
          orElse: () => FiatCurrency.usd,
        );
        final sourceEnum = ExchangeRateSource.values.firstWhere(
          (s) => s.value.toLowerCase() == localSource,
          orElse: () => ExchangeRateSource.bitstamp,
        );

        return ExchangeRate(currencyEnum, sourceEnum);
      }
    }

    return currencyModelLookup[FiatCurrency.usd]!;
  }

  ExchangeRate get usdCurrency {
    return availableCurrencies.firstWhere(
      (e) => e.currency == FiatCurrency.usd,
      orElse: () => currencyModelLookup[FiatCurrency.usd]!,
    );
  }

  List<ExchangeRateSource> sourcesForCurrentCurrency(String referenceCurrency) {
    if (gdkAvailableCurrencies == null ||
        gdkAvailableCurrencies!.perExchange == null) {
      return [];
    }

    final perExchange = gdkAvailableCurrencies!.perExchange!;
    return [
      ExchangeRateSource.bitfinex,
      ExchangeRateSource.bitstamp,
      ExchangeRateSource.bullbitcoin,
      ExchangeRateSource.coingecko,
      ExchangeRateSource.kraken
    ].where(
      (source) {
        return perExchange.containsKey(source.value) &&
            perExchange[source.value]?.contains(
                  referenceCurrency.toUpperCase(),
                ) ==
                true;
      },
    ).toList();
  }

  Future<void> setReferenceCurrency(ExchangeRate er) async {
    await ref.read(gdkSettingsProvider.notifier).change(
          GdkSettingsEvent(
            pricing: GdkPricing(
              currency: er.currency.value,
              exchange: er.source.value,
            ),
          ),
        );
    prefs.setReferenceCurrency(er.currency.value);
    prefs.setPriceSource(er.source.value);
    notifyListeners();
  }
}
