import 'dart:async';
import 'dart:math';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';
import 'package:rxdart/rxdart.dart';

class SatoshiToFiatConversionModel {
  final String currencySymbol;
  final Decimal decimal;
  final String formatted;
  final String formattedWithCurrency;

  SatoshiToFiatConversionModel({
    required this.currencySymbol,
    required this.decimal,
    required this.formatted,
    required this.formattedWithCurrency,
  });
}

// Respects user settings (user session default currency default)
// Rebuilds when currency changes to ensure rateStream fetches fresh rates
final fiatProvider = Provider.autoDispose<FiatProvider>((ref) {
  ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
  return FiatProvider(ref);
});

class FiatProvider {
  static const _rateTimeout = Duration(seconds: 5);

  final AutoDisposeProviderRef ref;
  final Stream<(Decimal, String, String)>? _forcedRateStream;

  FiatProvider(this.ref, {Stream<(Decimal, String, String)>? forcedRateStream})
      : _forcedRateStream = forcedRateStream;

  late final Stream<(Decimal, String, String)> rateStream = _forcedRateStream ??
      Stream<void>.periodic(const Duration(milliseconds: 5000))
          .startWith(null)
          .switchMap((_) => Stream.value(_)
                  .map((_) => const GdkConvertData(
                        satoshi: 1,
                      ))
                  .asyncMap(
                      (data) => ref.read(bitcoinProvider).convertAmount(data))
                  .asyncMap((data) {
                final rate = data?.fiatRate;
                if (rate == null) {
                  throw FiatProviderNullFiatRateException();
                }

                return (
                  Decimal.parse(rate),
                  data?.fiatCurrency ?? '',
                  data?.currencySymbol ?? '\$',
                );
              }).onErrorResumeNext(const Stream.empty()))
          .shareReplay(maxSize: 1);

  Future<(Decimal, String, String)> _getRate() async {
    try {
      return await rateStream.first.timeout(_rateTimeout);
    } on StateError {
      throw FiatProviderNullFiatRateException();
    } on TimeoutException {
      throw FiatProviderTimeoutException(_rateTimeout);
    }
  }

  //ANCHOR: - Satoshi to Fiat
  Decimal satoshiToFiat(Asset asset, int satoshi, Decimal rate) {
    if (!asset.hasFiatRate) {
      throw FiatProviderParseAssetAmountException();
    }

    final precisionRate = Decimal.parse(
        pow(10, asset.precision).toStringAsFixed(asset.precision));

    return (Decimal.fromInt(satoshi) / precisionRate).toDecimal() * rate;
  }

  String formatFiat(Decimal fiatValue, String code, {bool withSymbol = true}) {
    final availableCurrencies =
        ref.read(exchangeRatesProvider).availableCurrencies;
    final currency =
        availableCurrencies.firstWhere((c) => c.currency.value == code);
    final formatter = ref.read(formatProvider);

    return formatter.formatFiatAmount(
      amount: fiatValue,
      specOverride: currency.currency.format,
      withSymbol: withSymbol,
    );
  }

  // ANCHOR: - Format Sats to Fiat with Rate and Currency Code Display
  String formatSatsToFiatWithRateDisplay(
      {required Asset asset,
      required int satoshi,
      required Decimal rate,
      required String currencyCode}) {
    final fiatValue = satoshiToFiat(asset, satoshi, rate);
    return formatFiat(fiatValue, currencyCode);
  }

  Stream<SatoshiToFiatConversionModel> satoshiToReferenceCurrencyStream(
          Asset asset, int satoshi) =>
      rateStream.map((rate) {
        final decimalAmount = satoshiToFiat(asset, satoshi, rate.$1);
        final formattedAmount =
            formatFiat(decimalAmount, rate.$2, withSymbol: true);

        return SatoshiToFiatConversionModel(
          currencySymbol: rate.$2,
          decimal: decimalAmount,
          formatted: formattedAmount,
          formattedWithCurrency: formattedAmount,
        );
      }).onErrorResumeNext(const Stream.empty());

  //ANCHOR: - Fiat to Satoshi
  Future<Decimal> fiatToSatoshi(Asset asset, Decimal amount) async {
    final rate = await _getRate();
    final assetPrecision =
        asset.isLightning ? Asset.btc().precision : asset.precision;
    final precisionRate =
        Decimal.parse(pow(10, assetPrecision).toStringAsFixed(assetPrecision));
    final divided = amount / rate.$1;

    return divided.toDecimal(scaleOnInfinitePrecision: assetPrecision) *
        precisionRate;
  }

  Stream<String> fiatToSatoshiStream(Asset asset, String amount) =>
      rateStream.switchMap((rate) => Stream.value(rate).asyncMap((rate) async {
            if (!asset.hasFiatRate) {
              throw FiatProviderParseAssetAmountException();
            }

            final decimalAmount = Decimal.parse(amount);

            final result = (decimalAmount / rate.$1)
                .toDouble()
                .toStringAsFixed(asset.precision);

            return result;
          }).onErrorResumeNext(const Stream.empty()));

  /// Convenience method to get the fiat value of a satoshi amount to display
  Future<String> getSatsToFiatDisplay(int satoshi, bool withSymbol) async {
    final (rate, symbol, _) = await _getRate();
    final fiatValue = satoshiToFiat(Asset.btc(amount: satoshi), satoshi, rate);
    return formatFiat(fiatValue, symbol, withSymbol: withSymbol);
  }

  /// Convenience method to get the fiat value of a satoshi amount
  Future<Decimal> getSatsToFiat(int satoshi) async {
    final (rate, _, _) = await _getRate();
    return satoshiToFiat(Asset.btc(amount: satoshi), satoshi, rate);
  }
}

/// Provider to get the fiat value of a satoshi amount
final satsToFiatDisplayWithSymbolProvider = FutureProvider.autoDispose
    .family<String, int>((ref, satoshi) =>
        ref.read(fiatProvider).getSatsToFiatDisplay(satoshi, true));

/// Provider to convert a fiat amount to its equivalent in satoshis as a double
final fiatToSatsAsIntProvider =
    FutureProvider.family<int, (Asset, Decimal)>((ref, params) async {
  final asset = params.$1;
  final amount = params.$2;
  final Decimal sats =
      await ref.read(fiatProvider).fiatToSatoshi(asset, amount);
  return sats.toBigInt().toInt();
});

class FiatProviderNullFiatRateException implements Exception {}

class FiatProviderTimeoutException implements Exception {
  final Duration timeout;
  FiatProviderTimeoutException(this.timeout);

  @override
  String toString() => 'Fiat rate stream timed out after ${timeout.inSeconds}s';
}

class FiatProviderParseAssetAmountException implements Exception {}
