import 'dart:math';

import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:aqua/features/settings/exchange_rate/providers/exchange_rate_provider.dart';
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

  BtcPriceUiModel({
    required this.price,
    required this.priceChange,
    required this.priceChangePercent,
    required this.priceWithSymbol,
    required this.currency,
  });

  static BtcPriceUiModel placeholder = BtcPriceUiModel(
    price: '0',
    priceChange: '0',
    priceChangePercent: '0',
    priceWithSymbol: '0',
    currency: FiatCurrency.usd,
  );
}

final btcPriceProvider =
    StreamProvider.family<AsyncValue<BtcPriceUiModel>, int>((ref, precision) {
  final fProvider = ref.read(fiatProvider);
  final currentCurrency = ref.watch(exchangeRatesProvider).currentCurrency;
  final formatter = ref.read(currencyFormatProvider(precision));
  return fProvider.rateStream.map((rate) {
    final precisionRate = Decimal.parse(pow(10, 8).toStringAsFixed(8));
    final btcValue =
        (satsPerBtc / precisionRate.toDouble()) * rate.$1.toDouble();
    final formattedValue = formatter.format(btcValue);
    final priceWithSymbol = '${currentCurrency.currency.symbol}$formattedValue';

    return AsyncValue.data(BtcPriceUiModel(
      price: formattedValue,
      priceChange: '',
      priceChangePercent: '',
      priceWithSymbol: priceWithSymbol,
      currency: currentCurrency.currency,
    ));
  }).startWith(const AsyncValue.loading());
});

final currenciesProvider = FutureProvider.family
    .autoDispose<List<String>, BuildContext>((ref, context) async {
  final currencies = await ref.read(aquaProvider).getAvailableCurrencies();
  return currencies?.perExchange?.entries
          .expand((exchange) => exchange.value.map((currency) => context.loc
              .refExRateSettingsScreenItemLabel(currency, exchange.key)))
          .toList() ??
      [];
});
