import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:rxdart/rxdart.dart';

const int satsPerBtc = 100000000;

class BtcPriceUiModel {
  final String price;
  final String priceChange;
  final String priceChangePercent;
  final String priceWithSymbol;
  final FiatCurrency currency;
  final String symbol;
  final bool isCached;
  final bool isSymbolLeading;

  BtcPriceUiModel({
    required this.price,
    required this.priceChange,
    required this.priceChangePercent,
    required this.priceWithSymbol,
    required this.currency,
    required this.symbol,
    required this.isCached,
    required this.isSymbolLeading,
  });

  static BtcPriceUiModel placeholder = BtcPriceUiModel(
    price: '0',
    priceChange: '0',
    priceChangePercent: '0',
    priceWithSymbol: '0 ${FiatCurrency.usd.format.symbol}',
    currency: FiatCurrency.usd,
    symbol: FiatCurrency.usd.format.symbol,
    isCached: true,
    isSymbolLeading: FiatCurrency.usd.format.isSymbolLeading,
  );

  factory BtcPriceUiModel.fromFormattedParts({
    required String numericPrice,
    required String fullPriceString,
    required ExchangeRate currentExchangeRate,
    bool isCached = false,
    String priceChange = '',
    String priceChangePercent = '',
  }) {
    return BtcPriceUiModel(
      price: numericPrice,
      priceChange: priceChange,
      priceChangePercent: priceChangePercent,
      priceWithSymbol: fullPriceString,
      currency: currentExchangeRate.currency,
      symbol: currentExchangeRate.currency.format.symbol,
      isCached: isCached,
      isSymbolLeading: currentExchangeRate.currency.format.isSymbolLeading,
    );
  }
}

// A special BTC price provider reserved for the home screen header with some
// additional logic to handle the case where the BTC price is not available.
// When the BTC price is not availalbe (as in being loaded or in absence of
// internet connection), the goal is to show cached value if available, else a
// loading skeleton.
//
// NOTE - Do NOT use for non-UI stuff, cached value could break calculations and
// lead to loss of funds for the user.
final btcPriceProvider =
    StreamProvider.family<AsyncValue<BtcPriceUiModel>, int>((ref, precision) {
  final fProvider = ref.read(fiatProvider);
  final formatter = ref.read(formatProvider);
  final ExchangeRate currentExchangeRate = ref.watch(
      exchangeRatesProvider.select((provider) => provider.currentCurrency));

  return fProvider.rateStream.map((rateTuple) {
    final Decimal btcPriceInFiat = rateTuple.$1;
    final String numericPrice = formatter.formatFiatAmount(
      amount: btcPriceInFiat,
      specOverride: currentExchangeRate.currency.format,
      decimalPlacesOverride: precision,
      withSymbol: false,
    );
    final String fullPrice = formatter.formatFiatAmount(
      amount: btcPriceInFiat,
      specOverride: currentExchangeRate.currency.format,
      decimalPlacesOverride: precision,
    );

    return AsyncValue.data(BtcPriceUiModel.fromFormattedParts(
      numericPrice: numericPrice,
      fullPriceString: fullPrice,
      currentExchangeRate: currentExchangeRate,
    ));
  }).startWith(const AsyncValue.loading());
});

final btcPriceUiModelProvider =
    StreamProvider.family<BtcPriceUiModel, int>((ref, precision) async* {
  final ExchangeRate currentExchangeRate = ref.watch(
    exchangeRatesProvider.select((provider) => provider.currentCurrency),
  );
  final formatter = ref.read(formatProvider);

  final cache = ref.read(keyValueCacheServiceProvider);
  final cachedBtcPrice = cache.get(CacheKey.btcPrice);
  final cachedCurrencyNameInCache = cache.get(CacheKey.btcPriceCurrency)?.value;

  if (cachedBtcPrice != null &&
      cachedCurrencyNameInCache == currentExchangeRate.currency.name) {
    final Decimal btcPriceInFiat = Decimal.parse(cachedBtcPrice.value);
    final String numericPrice = formatter.formatFiatAmount(
      amount: btcPriceInFiat,
      specOverride: currentExchangeRate.currency.format,
      decimalPlacesOverride: precision,
      withSymbol: false,
    );
    final String fullPrice = formatter.formatFiatAmount(
      amount: btcPriceInFiat,
      specOverride: currentExchangeRate.currency.format,
      decimalPlacesOverride: precision,
      withSymbol: true,
    );
    yield BtcPriceUiModel.fromFormattedParts(
      numericPrice: numericPrice,
      fullPriceString: fullPrice,
      currentExchangeRate: currentExchangeRate,
      isCached: true,
    );
  } else {
    final rateTuple = await ref.read(fiatProvider).rateStream.first;
    final Decimal btcPriceInFiatRaw = rateTuple.$1;

    final String numericPriceRaw = formatter.formatFiatAmount(
      amount: btcPriceInFiatRaw,
      specOverride: currentExchangeRate.currency.format,
      decimalPlacesOverride: precision,
      withSymbol: false,
    );
    final String fullPriceRaw = formatter.formatFiatAmount(
      amount: btcPriceInFiatRaw,
      specOverride: currentExchangeRate.currency.format,
      decimalPlacesOverride: precision,
      withSymbol: true,
    );

    cache.save(CacheKey.btcPrice, btcPriceInFiatRaw.toString());
    cache.save(CacheKey.btcPriceCurrency, currentExchangeRate.currency.name);

    yield BtcPriceUiModel.fromFormattedParts(
        numericPrice: numericPriceRaw,
        fullPriceString: fullPriceRaw,
        currentExchangeRate: currentExchangeRate);
  }
});

final currenciesProvider = FutureProvider.family
    .autoDispose<List<String>, BuildContext>((ref, context) async {
  final currencies = await ref.read(aquaProvider).getAvailableCurrencies();
  return currencies?.perExchange?.entries
          .expand((exchange) => exchange.value.map((currencyCode) => context.loc
              .refExRateSettingsScreenItemLabel(currencyCode, exchange.key)))
          .toList() ??
      [];
});
