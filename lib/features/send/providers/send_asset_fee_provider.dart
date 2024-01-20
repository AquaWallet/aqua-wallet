import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/external/boltz/boltz_provider.dart';
import 'package:aqua/features/send/models/send_asset_arguments.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

import 'package:aqua/data/provider/conversion_provider.dart';
import 'providers.dart';

/// ---------------------
/// Fee estimates and rates

/// Fetch fee rates in sats/vbyte
final feeRatesPerVByteProvider = FutureProvider.autoDispose
    .family<Map<TransactionPriority, double>, NetworkType>(
        (ref, network) async {
  final currentAsset = ref.watch(sendAssetProvider);
  if (!currentAsset.isBTC) {
    throw Exception("Only fetching fee rates for onchain BTC");
  }

  final feeRates = await ref.read(electrsProvider).fetchFeeRates(network);
  logger.d('[$network] feeRates: $feeRates');
  return feeRates;
});

/// Estimate fee from user selected fee rate * transaction size
final estimatedFeeProvider = StateProvider.autoDispose<int?>((ref) {
  final gdkTx = ref.watch(sendAssetTransactionProvider).asData?.value;
  final selectedFeeRate = ref.watch(selectedFeeRatePerKByteProvider);

  if (gdkTx != null && selectedFeeRate != null) {
    return (gdkTx.transactionVsize! * (selectedFeeRate / 1000)).toInt();
  }
  return null;
});

/// ---------------------
/// Fees actual

/// Fee in sats
/// - Initially set to default
/// - Updated to estimated fee based on fee rate user selected (for btc only currently)
/// - Then updated to the fee returned from a formed transaction
final feeInSatsProvider = Provider.autoDispose<int>((ref) {
  // formed transaction
  final gdkTx = ref.watch(sendAssetTransactionProvider).asData?.value;
  if (gdkTx != null) {
    logger.d('[FEE] fee coming from formed gdk tx: ${gdkTx.fee}');
    return gdkTx.fee!.toInt();
  }

  // estimated
  final estimatedFee = ref.watch(estimatedFeeProvider);
  if (estimatedFee != null) {
    logger.d('[FEE] fee coming estimated based on tx size: $estimatedFee');
    return estimatedFee;
  }

  return 0;
});

/// Cache user selected fee asset (which asset to pay fees in)
final selectedFeeAssetProvider = StateProvider.autoDispose<FeeAsset>((ref) {
  final asset = ref.read(sendAssetProvider);
  return asset == Asset.btc() ? FeeAsset.btc : FeeAsset.lbtc;
});

/// Cache fee rate selected by user (for btc only currently)
final selectedFeeRatePerKByteProvider = StateProvider.autoDispose<int?>((ref) {
  final fetchedRates =
      ref.watch(feeRatesPerVByteProvider(NetworkType.bitcoin)).asData?.value;
  if (fetchedRates != null) {
    return fetchedRates[TransactionPriority.low]!.toInt() *
        1000; // fetchRates comes back as sats per byte, so * 1000 to get sats per kb
  }
  return null;
});

/// Service fee from external service - boltz
final boltzServiceFeeProvider =
    Provider.family.autoDispose<int, Asset>((ref, asset) {
  if (asset.isLightning) {
    final boltzOrder = ref.watch(boltzSwapSuccessResponseProvider);
    final userEnteredAmountWithPrecision =
        ref.watch(userEnteredAmountWithPrecisionProvider(asset));
    if (boltzOrder != null) {
      int userEnteredAmountSats = userEnteredAmountWithPrecision;
      final boltzExpectedAmount = boltzOrder.expectedAmount;
      int boltzServiceFee = boltzExpectedAmount - userEnteredAmountSats.toInt();
      return boltzServiceFee;
    }
  }

  return 0;
});

/// Service fee from external service - sideshift
final sideshiftServiceFeeProvider =
    Provider.family.autoDispose<double, Asset>((ref, asset) {
  if (asset.isSideshift) {
    final pendingOrder = ref.watch(pendingOrderProvider);
    if (pendingOrder is SideshiftFixedOrderResponse) {
      double serviceFeeDouble = double.parse(pendingOrder.depositAmount!) -
          double.parse(pendingOrder.settleAmount!);
      logger.d("[B] service fee - sideshift: $serviceFeeDouble");
      return serviceFeeDouble;
    }
  }
  return 0;
});

/// ---------------------
/// Fees UI display

/// UI display of fee
final feeToDisplayProvider =
    StateProvider.autoDispose.family<String?, Asset>((ref, asset) {
  var feeInSats = ref.watch(feeInSatsProvider);

  // add service fees
  if (asset.isSideshift) {
    double serviceFeeDouble = ref.watch(sideshiftServiceFeeProvider(asset));
    final total = serviceFeeDouble + 0.01; // hardcoded liquid fee for now
    logger.d(
        '[FEE] sideshift service fee - serviceFeeDouble: $serviceFeeDouble - : ${serviceFeeDouble.toStringAsFixed(2)} - feeInSats: $feeInSats');
    return total.toStringAsFixed(2);
  }

  if (asset.isLightning) {
    final boltzServiceFee = ref.watch(boltzServiceFeeProvider(asset));
    final total = feeInSats + boltzServiceFee;
    logger.d(
        '[FEE] boltzServiceFee: $boltzServiceFee - feeInSats: $feeInSats - total: $total');
    return total.toString();
  }

  return ref.watch(formatterProvider).formatAssetAmount(
        amount: feeInSats,
        precision: asset.precision,
      );
});

final feeInFiatToDisplayProvider =
    StateProvider.autoDispose.family<String?, Asset>((ref, asset) {
  var feeInSats = ref.watch(feeInSatsProvider);
  return ref.watch(conversionProvider((Asset.btc(), feeInSats)));
});
