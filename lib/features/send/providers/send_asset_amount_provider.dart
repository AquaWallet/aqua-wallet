import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/send/providers/send_asset_fee_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';

/// ---------------------
/// Amount

/// Raw user entered amount
final userEnteredAmountProvider = StateProvider.autoDispose<double?>((ref) {
  return null;
});

final userEnteredAmountIsUsdProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final useAllFundsProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

/// Entered amount converted to with precision of asset.
/// - Needed by `formatterProvider` to format amount for display
final userEnteredAmountWithPrecisionProvider =
    StateProvider.family.autoDispose<int, Asset>((ref, asset) {
  final userEnteredAmount = ref.watch(userEnteredAmountProvider);
  if (userEnteredAmount == null) {
    return 0;
  }

  // convert from usd input to sats if needed
  final isUsdInput = ref.watch(userEnteredAmountIsUsdProvider);
  final shouldConvertToSats =
      isUsdInput && (asset.isBTC || asset.isLBTC || asset.isLightning);
  if (shouldConvertToSats) {
    final amountInSats = ref
            .watch(fiatToSatsAsIntProvider((asset, userEnteredAmount)))
            .asData
            ?.value ??
        0;
    final amountBTC = amountInSats / satsPerBtc;
    final amountWithPrecision = ref
        .read(formatterProvider)
        .parseAssetAmountDirect(
            amount: amountBTC.toString(), precision: asset.precision);
    return amountWithPrecision;
  } else {
    final amountWithPrecision = ref
        .read(formatterProvider)
        .parseAssetAmountDirect(
            amount: userEnteredAmount.toString(), precision: asset.precision);
    return amountWithPrecision;
  }
});

/// UI display of amount (without fees)
final amountMinusFeesToDisplayProvider =
    StateProvider.autoDispose<String?>((ref) {
  final asset = ref.watch(sendAssetProvider);
  final userEnteredAmountWithPrecision =
      ref.watch(userEnteredAmountWithPrecisionProvider(asset));
  final assetPrecision = asset.precision;

  return ref.watch(formatterProvider).formatAssetAmount(
        amount: userEnteredAmountWithPrecision,
        precision: assetPrecision,
      );
});

/// UI display of amount (with onchain fees and service fees)
final amountWithFeesToDisplayProvider =
    StateProvider.autoDispose.family<String?, Asset>((ref, asset) {
  final userEnteredAmount = ref.watch(userEnteredAmountProvider) ?? 0;
  var fee = ref.watch(feeInSatsProvider).toDouble();
  var serviceFee = 0.0;

  // add service fees
  if (asset.isSideshift) {
    final sideshiftFee = ref.watch(sideshiftServiceFeeProvider(asset));
    serviceFee = double.parse(sideshiftFee.toStringAsFixed(2));
    fee = 0.01; // hardcoded liquid fee for now
  } else if (asset.isLightning) {
    serviceFee = ref.watch(boltzServiceFeeProvider(asset)).toDouble();
  }

  final total = userEnteredAmount + fee + serviceFee;
  final totalWithPrecision = ref.read(formatterProvider).parseAssetAmountDirect(
      amount: total.toString(), precision: asset.precision);
  return ref.watch(formatterProvider).formatAssetAmount(
        amount: totalWithPrecision,
        precision: asset.precision,
      );
});
