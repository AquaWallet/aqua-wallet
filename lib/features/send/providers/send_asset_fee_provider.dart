import 'dart:math';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

/// ---------------------
/// Fee estimates and rates

/// Fetch fee rates in sats/vbyte
final fetchedFeeRatesPerVByteProvider = FutureProvider.autoDispose
    .family<Map<TransactionPriority, double>, NetworkType>(
        (ref, network) async {
  final currentAsset = ref.watch(sendAssetProvider);
  if (!currentAsset.isBTC) {
    throw Exception("Only fetching fee rates for onchain BTC");
  }

  final feeRates = await ref.watch(onChainFeeProvider.future);
  logger.d('[$network] feeRates: $feeRates');
  return feeRates;
});

/// Estimate fee from user selected fee rate * transaction size
final estimatedFeeProvider = StateProvider.autoDispose<int?>((ref) {
  final transaction = ref.watch(sendAssetTransactionProvider).asData?.value;
  GdkNewTransactionReply? gdkTx = transaction?.maybeMap(
    gdkTx: (tx) => tx.gdkTx,
    orElse: () => null,
  );

  final selectedFeeRate = ref.watch(userSelectedFeeRatePerVByteProvider);

  if (gdkTx != null && selectedFeeRate != null) {
    return (gdkTx.transactionVsize! * (selectedFeeRate.rate / 1000)).toInt();
  }
  return null;
});

/// ---------------------
/// Fees actual

/// Fee in sats
/// - Initially set to default
/// - Updated to estimated fee based on fee rate user selected (for btc only currently)
/// - Then updated to the fee returned from a formed transaction
final onchainFeeInSatsProvider = Provider.autoDispose<int>((ref) {
  // formed transaction
  final transaction = ref.watch(sendAssetTransactionProvider).asData?.value;
  GdkNewTransactionReply? gdkTx = transaction?.maybeMap(
    gdkTx: (tx) => tx.gdkTx,
    orElse: () => null,
  );

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
final userSelectedFeeAssetProvider = StateProvider.autoDispose<FeeAsset>((ref) {
  final asset = ref.watch(sendAssetProvider);
  final feeAsset = switch (asset) {
    _ when (asset.isBTC) => FeeAsset.btc,
    _ when (asset.isAnyUsdt) => FeeAsset.tetherUsdt,
    _ => FeeAsset.lbtc,
  };
  return feeAsset;
});

/// Cache fee rate selected by user (for btc only currently)
final userSelectedFeeRatePerVByteProvider =
    StateProvider.autoDispose<FeeRate?>((ref) {
  final fetchedRates = ref
      .watch(fetchedFeeRatesPerVByteProvider(NetworkType.bitcoin))
      .asData
      ?.value;

  if (fetchedRates != null &&
      fetchedRates.containsKey(TransactionPriority.medium)) {
    final rate = fetchedRates[TransactionPriority.medium]!;
    return FeeRate(TransactionPriority.medium, rate);
  }
  return null;
});

/// Service fee from external service - boltz
final boltzServiceFeeProvider =
    Provider.family.autoDispose<int, Asset>((ref, asset) {
  if (asset.isLightning) {
    final userEnteredAmount = ref.read(userEnteredAmountProvider);
    if (userEnteredAmount == null) return 0;

    final userEnteredAmountWithPrecision =
        ref.watch(enteredAmountWithPrecisionProvider(userEnteredAmount));
    int userEnteredAmountSats = userEnteredAmountWithPrecision;

    return BoltzFees.serviceFeesForAmountSubmarine(userEnteredAmountSats);
  }

  return 0;
});

/// Service fee from external service - sideshift
final sideshiftServiceFeeProvider =
    Provider.family.autoDispose<Decimal, Asset>((ref, asset) {
  if (asset.isSideshift) {
    final pendingOrder = ref.watch(sideshiftPendingOrderProvider);
    if (pendingOrder is SideshiftFixedOrderResponse) {
      Decimal serviceFeeDouble = Decimal.parse(pendingOrder.depositAmount!) -
          Decimal.parse(pendingOrder.settleAmount!);
      logger.d(
          "[Send][Fee][Sideshift] service fee - sideshift: $serviceFeeDouble");
      return serviceFeeDouble;
    }
  }
  return Decimal.zero;
});

/// ---------------------
/// Fees UI display

/// UI display of fee (including service provider fees)
final totalFeeToDisplayProvider =
    StateProvider.autoDispose.family<String?, Asset>((ref, asset) {
  final feeInSats = ref.watch(onchainFeeInSatsProvider);
  final feeAsset = ref.watch(userSelectedFeeAssetProvider);
  final sendAll = ref.watch(useAllFundsProvider);

  int? calculateTaxiUsdtFee() {
    final userEnteredAmount = ref.watch(userEnteredAmountProvider);
    if (userEnteredAmount == null) {
      return null;
    }
    final enteredAmountWithPrecision =
        ref.watch(enteredAmountWithPrecisionProvider(userEnteredAmount));
    //TODO: We are setting `lowball == true` here but this will be wrong if lowball fails and we fallback to higher fees. However, since this is just for display this is fine. Should refactor to read whether lowball or not when possible.
    final usdtFee = ref
        .watch(estimatedTaxiFeeUsdtProvider(
            (enteredAmountWithPrecision, sendAll, true)))
        .asData
        ?.value;
    if (usdtFee == null) {
      return null;
    }
    return usdtFee;
  }

  if (asset.isSideshift) {
    Decimal serviceFee = ref.watch(sideshiftServiceFeeProvider(asset));
    final usdtFee = calculateTaxiUsdtFee();
    if (usdtFee == null) return "0";
    final lbtcInUsdFee = ((usdtFee - kSideswapTaxiFee)).toDouble();
    final networkFeeWithPrecision =
        feeAsset == FeeAsset.tetherUsdt ? usdtFee : lbtcInUsdFee;
    final networkFee = DecimalExt.fromDouble(
        networkFeeWithPrecision / pow(10, asset.precision));
    final total = serviceFee + networkFee;
    return total.toStringAsFixed(2);
  }

  if (asset.isLightning) {
    final boltzServiceFee = ref.watch(boltzServiceFeeProvider(asset));
    final total = feeInSats + boltzServiceFee;
    return total.toString();
  }

  if (feeAsset == FeeAsset.tetherUsdt) {
    return ref.watch(formatterProvider).formatAssetAmountDirect(
          amount: calculateTaxiUsdtFee() ?? 0,
          precision: asset.precision,
          roundingOverride: kUsdtDisplayPrecision,
        );
  }

  return ref.watch(formatterProvider).formatAssetAmountDirect(
        amount: feeInSats,
        precision: asset.precision,
      );
});

final onchainFeeInFiatToDisplayProvider =
    StateProvider.autoDispose.family<String?, Asset>((ref, asset) {
  var feeInSats = ref.watch(onchainFeeInSatsProvider);
  return ref.watch(conversionProvider((Asset.btc(), feeInSats)));
});

final customFeeInputProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});

final customFeeInFiatProvider =
    Provider.autoDispose.family<String?, (String?, int?)>((ref, args) {
  final amount = args.$1;
  final transactionVsize = args.$2;
  if (amount != null && transactionVsize != null) {
    try {
      final amountInSats = Decimal.tryParse(amount)!.toBigInt().toInt();
      return ref
          .watch(satsToFiatDisplayWithSymbolProvider(
              amountInSats * transactionVsize))
          .asData
          ?.value;
    } catch (e) {
      return null;
    }
  }

  return null;
});
