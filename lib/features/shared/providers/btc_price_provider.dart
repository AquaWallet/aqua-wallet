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
}

final priceProvider = Provider.family<_BtcPrice, int>((ref, precision) {
  return _BtcPrice(ref, precision);
});

class _BtcPrice {
  _BtcPrice(this._ref, this._precision);

  final Ref _ref;
  final int _precision;

  Stream<AsyncValue<BtcPriceUiModel>> priceStream() {
    final rateStream = _ref.read(fiatProvider).rateStream;

    return rateStream.map((rate) {
      final currentCurrency = _ref.read(exchangeRatesProvider).currentCurrency;

      final precisionRate = Decimal.parse(pow(10, 8).toStringAsFixed(8));
      final btcValue =
          (satsPerBtc / precisionRate.toDouble()) * rate.toDouble();
      final formatter = _ref.read(currencyFormatProvider(_precision));
      final formattedValue = formatter.format(btcValue);
      final priceWithSymbol =
          '${currentCurrency.currency.symbol}$formattedValue';

      return AsyncValue.data(BtcPriceUiModel(
        price: formattedValue,
        priceChange: '',
        priceChangePercent: '',
        priceWithSymbol: priceWithSymbol,
        currency: currentCurrency.currency,
      ));
    }).startWith(const AsyncValue.loading());
  }
}

final _btcPriceProvider = StreamProvider.autoDispose
    .family<AsyncValue<BtcPriceUiModel>, int>((ref, precision) {
  return ref.watch(priceProvider(precision)).priceStream();
});

final btcPriceProvider = Provider.autoDispose
    .family<AsyncValue<BtcPriceUiModel>, int>((ref, precision) {
  return ref.watch(_btcPriceProvider(precision)).asData?.value ??
      const AsyncValue.loading();
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
