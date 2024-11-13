import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/features/settings/exchange_rate/providers/conversion_currencies_provider.dart';
import 'package:aqua/features/settings/exchange_rate/providers/exchange_rate_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

/////////////////////
/// Amount

/// User entered amount
final receiveAssetAmountProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Amount entered was fiat toggled
final amountCurrencyProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});

/// Amount to add to bip21 uri.
/// - This will be different from the user entered amount if user entered amount is in fiat, as we want to add the btc/lbtc amount to the bip21 uri
final receiveAssetAmountForBip21Provider =
    Provider.family.autoDispose<String?, Asset>((ref, asset) {
  final userEntered = ref.watch(receiveAssetAmountProvider);
  final fiatCurrency = ref.watch(amountCurrencyProvider);
  final fiatRates = ref.watch(fiatRatesProvider).unwrapPrevious().valueOrNull;
  final fiatAmount = ref.read(parsedAssetAmountAsDecimalProvider(userEntered));
  final currentRate =
      ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));

  // if fiat currency and any btc/lbtc/lightning asset, we want to add the btc/lbtc amount to the bip21 uri
  if (fiatCurrency != null &&
      fiatRates != null &&
      (asset.isBTC || asset.isLBTC || asset.isLightning)) {
    final fiatRate =
        fiatRates.firstWhere((element) => element.code == fiatCurrency);
    final bitcoinAmountDecimalFormat = (fiatAmount.toDouble() / fiatRate.rate);
    // return amount in sats
    return (bitcoinAmountDecimalFormat * satsPerBtc)
        .toDouble()
        .toStringAsFixed(0);
  } else if (fiatCurrency == currentRate.currency.value &&
      (asset.isBTC || asset.isLBTC || asset.isLightning)) {
    final amountInSats = ref
            .watch(fiatToSatsAsIntProvider((
              Asset.btc(),
              fiatAmount
            ))) // We are using asset.btc here because the rates are per btc
            .asData
            ?.value ??
        0;
    return amountInSats.toDouble().toStringAsFixed(0);
  } else {
    return userEntered;
  }
});

/// Amount as Decimal
final parsedAssetAmountAsDecimalProvider =
    Provider.family.autoDispose<Decimal, String?>((ref, amountStr) {
  if (amountStr == null || amountStr.isEmpty || amountStr == ".") {
    return Decimal.zero;
  }

  try {
    return Decimal.parse(amountStr);
  } catch (e) {
    throw FormatException(
        "The provided string cannot be parsed as a double: $amountStr");
  }
});

/////////////////////
/// Conversion Displays

/// Amount converted to fiat or btc/lbtc for display
final receiveAssetAmountConversionDisplayProvider = FutureProvider.autoDispose
    .family<String?, (Asset, String?, String?)>((ref, params) {
  final asset = params.$1;
  final fiatCurrency = params.$2 ?? ref.watch(amountCurrencyProvider);
  final fiatRates = ref.watch(fiatRatesProvider).unwrapPrevious().valueOrNull;
  final amountStr = params.$3 ?? ref.watch(receiveAssetAmountProvider);
  final currentRate =
      ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
  var amountAsDecimal = ref.read(parsedAssetAmountAsDecimalProvider(amountStr));
  if (amountStr == null) {
    throw Exception("Amount is null");
  }

  if (fiatRates == null &&
      fiatCurrency == currentRate.currency.value &&
      (asset.isBTC || asset.isLBTC || asset.isLightning)) {
    final amountInSats = ref
            .watch(fiatToSatsAsIntProvider((Asset.btc(), amountAsDecimal)))
            .asData
            ?.value ??
        0;
    return amountInSats.toDouble().toStringAsFixed(0);
  }

  if (fiatCurrency != null) {
    if (fiatRates == null) return '';

    if (asset.isLightning == true ||
        asset.isLBTC == true ||
        asset.isBTC == true) {
      amountAsDecimal = amountAsDecimal * Decimal.fromInt(satsPerBtc);
    }

    final fiatRate =
        fiatRates.firstWhere((element) => element.code == fiatCurrency);
    final res = (amountAsDecimal.toDouble() / fiatRate.rate)
        .toDouble()
        .toStringAsFixed(0);

    return res;
  }

  return ref
      .read(fiatProvider)
      .getSatsToFiatDisplay(int.parse(amountStr), true);
});
