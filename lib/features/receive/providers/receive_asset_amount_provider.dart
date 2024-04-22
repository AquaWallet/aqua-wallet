import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

/////////////////////
/// Amount

/// User entered amount
final receiveAssetAmountProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/// Amount entered was fiat toggled
final amountEnteredIsFiatToggledProvider =
    StateProvider.autoDispose<bool>((ref) {
  return false;
});

/// Amount to add to bip21 uri.
/// - This will be different from the user entered amount if user entered amount is in fiat, as we want to add the btc/lbtc amount to the bip21 uri
final receiveAssetAmountForBip21Provider =
    Provider.family.autoDispose<String?, Asset>((ref, asset) {
  final userEntered = ref.watch(receiveAssetAmountProvider);
  final isFiatToggled = ref.watch(amountEnteredIsFiatToggledProvider);

  // if fiat toggled and any btc/lbtc/lightning asset, we want to add the btc/lbtc amount to the bip21 uri
  if (isFiatToggled && (asset.isBTC || asset.isLBTC || asset.isLightning)) {
    var amountAsDecimal =
        ref.read(parsedAssetAmountAsDecimalProvider(userEntered));
    if (asset.isLightning == true) {
      amountAsDecimal = amountAsDecimal * Decimal.fromInt(satsPerBtc);
    }
    final btcConversion =
        ref.watch(conversionFiatProvider((asset, amountAsDecimal)));
    return btcConversion;
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
final receiveAssetAmountConversionDisplayProvider =
    FutureProvider.autoDispose.family<String?, Asset>((ref, asset) {
  final isFiatToggled = ref.watch(amountEnteredIsFiatToggledProvider);
  final amountStr = ref.watch(receiveAssetAmountProvider);
  if (amountStr == null) {
    throw Exception("Amount is null");
  }

  if (isFiatToggled) {
    var amountAsDecimal =
        ref.read(parsedAssetAmountAsDecimalProvider(amountStr));
    if (asset.isLightning == true) {
      amountAsDecimal = amountAsDecimal * Decimal.fromInt(satsPerBtc);
    }

    return ref.watch(conversionFiatProvider((asset, amountAsDecimal)));
  } else {
    final amountInSats = ref
        .read(formatterProvider)
        .parseAssetAmountDirect(amount: amountStr, precision: asset.precision);
    return ref.read(fiatProvider).getSatsToFiatDisplay(amountInSats, true);
  }
});
