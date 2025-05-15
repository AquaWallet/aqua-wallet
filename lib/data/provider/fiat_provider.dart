import 'dart:io';
import 'dart:math';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
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

final fiatProvider =
    Provider.autoDispose<FiatProvider>((ref) => FiatProvider(ref));

class FiatProvider {
  final AutoDisposeProviderRef ref;

  FiatProvider(this.ref);

  final _formatter = NumberFormat.currency(
    locale: Platform.localeName,
    symbol: '',
  );

  late final Stream<(Decimal, String)> rateStream = Stream<void>.periodic(
          const Duration(milliseconds: 5000))
      .startWith(null)
      .switchMap((_) => Stream.value(_)
              .map((_) => const GdkConvertData(satoshi: 1))
              .asyncMap((data) => ref.read(bitcoinProvider).convertAmount(data))
              .asyncMap((data) {
            final rate = data?.fiatRate;
            if (rate == null) {
              throw FiatProviderNullFiatRateException();
            }

            return (Decimal.parse(rate), data?.fiatCurrency ?? '');
          }).onErrorResumeNext(const Stream.empty()))
      .shareReplay(maxSize: 1);

  //ANCHOR: - Satoshi to Fiat
  Decimal satoshiToFiat(Asset asset, int satoshi, Decimal rate) {
    if (!asset.hasFiatRate) {
      throw FiatProviderParseAssetAmountException();
    }

    final precisionRate = Decimal.parse(
        pow(10, asset.precision).toStringAsFixed(asset.precision));

    return (Decimal.fromInt(satoshi) / precisionRate).toDecimal() * rate;
  }

  String formattedFiat(Decimal fiat) {
    final parsedResult = double.parse(fiat.toString());

    return _formatter.format(parsedResult);
  }

  Stream<SatoshiToFiatConversionModel> satoshiToReferenceCurrencyStream(
          Asset asset, int satoshi) =>
      rateStream.map((rate) {
        final decimalAmount = satoshiToFiat(asset, satoshi, rate.$1);
        final formattedAmount = formattedFiat(decimalAmount);

        return SatoshiToFiatConversionModel(
            currencySymbol: rate.$2,
            decimal: decimalAmount,
            formatted: formattedAmount,
            formattedWithCurrency: '${rate.$2} $formattedAmount');
      }).onErrorResumeNext(const Stream.empty());

  //ANCHOR: - Fiat to Satoshi
  Future<Decimal> fiatToSatoshi(Asset asset, Decimal amount) async {
    final rate = await rateStream.first;
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
    final (rate, currency) = await rateStream.first;
    final fiatValue = satoshiToFiat(Asset.btc(amount: satoshi), satoshi, rate);
    final formattedValue = formattedFiat(fiatValue);
    return withSymbol ? '$currency $formattedValue' : formattedValue;
  }

  /// Convenience method to get the fiat value of a satoshi amount
  Future<Decimal> getSatsToFiat(int satoshi) async {
    final (rate, _) = await rateStream.first;
    final fiatValue = satoshiToFiat(Asset.btc(amount: satoshi), satoshi, rate);
    return fiatValue;
  }
}

/// Provider to get the fiat value of a satoshi amount
final satsToFiatDisplayWithSymbolProvider = FutureProvider.family<String, int>(
    (ref, satoshi) =>
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

class FiatProviderParseAssetAmountException implements Exception {}
