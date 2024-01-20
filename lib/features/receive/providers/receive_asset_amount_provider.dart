import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';

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
    var amountAsDouble =
        ref.read(parsedAssetAmountAsDoubleProvider(userEntered));
    if (asset.isLightning == true) {
      amountAsDouble = amountAsDouble * satsPerBtc;
    }
    final btcConversion =
        ref.watch(conversionFiatProvider((asset, amountAsDouble)));
    return btcConversion;
  } else {
    return userEntered;
  }
});

/// Amount as double
final parsedAssetAmountAsDoubleProvider =
    Provider.family.autoDispose<double, String?>((ref, amountStr) {
  if (amountStr == null || amountStr.isEmpty) {
    return 0;
  }

  try {
    return double.parse(amountStr);
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
    var amountAsDouble = ref.read(parsedAssetAmountAsDoubleProvider(amountStr));
    if (asset.isLightning == true) {
      amountAsDouble = amountAsDouble * satsPerBtc;
    }

    return ref.watch(conversionFiatProvider((asset, amountAsDouble)));
  } else {
    final amountInSats = ref
        .read(formatterProvider)
        .parseAssetAmountDirect(amount: amountStr, precision: asset.precision);
    return ref.read(fiatProvider).getSatsToFiat(amountInSats);
  }
});
