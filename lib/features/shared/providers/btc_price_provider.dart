import 'dart:math';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:rxdart/rxdart.dart';

const int satsPerBtc = 100000000;

class BtcPriceUiModel {
  final String price;
  final String priceChange;
  final String priceChangePercent;

  BtcPriceUiModel({
    required this.price,
    required this.priceChange,
    required this.priceChangePercent,
  });
}

final priceProvider = Provider<_BtcPrice>((ref) {
  return _BtcPrice(ref);
});

class _BtcPrice {
  _BtcPrice(this._ref);

  final Ref _ref;

  Stream<AsyncValue<BtcPriceUiModel>> priceStream() => _ref
      .read(fiatProvider)
      .rateStream
      .map((rate) {
        final precisionRate = Decimal.parse(pow(10, 8).toStringAsFixed(8));
        return ((Decimal.fromInt(satsPerBtc) / precisionRate).toDecimal() *
                rate)
            .toDouble();
      })
      .map((value) {
        final formatter = _ref.read(currencyFormatProvider(2));
        return BtcPriceUiModel(
          price: formatter.format(value),
          priceChange: '',
          priceChangePercent: '',
        );
      })
      .map((value) => AsyncValue.data(value))
      .startWith(const AsyncValue.loading());
}

final _btcPriceProvider =
    StreamProvider.autoDispose<AsyncValue<BtcPriceUiModel>>((ref) async* {
  yield* ref.watch(priceProvider).priceStream();
});

final btcPriceProvider =
    Provider.autoDispose<AsyncValue<BtcPriceUiModel>>((ref) {
  return ref.watch(_btcPriceProvider).asData?.value ??
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
