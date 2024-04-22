import 'dart:math';

import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/data/provider/sideshift/sideshift_provider.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/boltz/boltz_provider.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';
import 'package:aqua/common/decimal/decimal_ext.dart';

/// ---------------------
/// Amount

/// Raw user entered amount validated
final userEnteredAmountProvider =
    NotifierProvider.autoDispose<UserEnteredAmountStateNotifier, Decimal?>(
        UserEnteredAmountStateNotifier.new);

class UserEnteredAmountStateNotifier extends AutoDisposeNotifier<Decimal?> {
  @override
  Decimal? build() => null;

  void updateAmount(Decimal? newAmount) async {
    final isValid = await _validateAmount(newAmount);
    if (isValid) {
      state = newAmount;
    }
  }

  Future<bool> _validateAmount(Decimal? amount) async {
    if (amount == null || amount == Decimal.zero) {
      return false;
    }

    final asset = ref.read(sendAssetProvider);
    final assetBalanceInSats =
        await ref.read(balanceProvider).getBalance(asset);
    final amountWithPrecision =
        ref.read(enteredAmountWithPrecisionProvider(amount));
    logger.d(
        '[Send][Amount] validate amount - assetBalanceInSats: $assetBalanceInSats - amountWithPrecision: $amountWithPrecision');

    if (amountWithPrecision > assetBalanceInSats) {
      ref.read(sendAmountErrorProvider.notifier).state =
          AmountParsingException(AmountParsingExceptionType.notEnoughFunds);
      ref.read(insufficientBalanceProvider.notifier).state = true;
      throw AmountParsingException(AmountParsingExceptionType.notEnoughFunds);
    } else {
      ref.read(insufficientBalanceProvider.notifier).state = false;
    }

    // if lightning, check if amount is above or below boltz min/max
    if (asset.isLightning) {
      if (amountWithPrecision < boltzMin) {
        ref.read(sendAmountErrorProvider.notifier).state =
            AmountParsingException(AmountParsingExceptionType.belowBoltzMin);
        logger.d(
            '[Send][Amount][Boltz] validate amount - amount $amountWithPrecision is below boltz min $boltzMin');
        throw AmountParsingException(AmountParsingExceptionType.belowBoltzMin);
      } else if (amountWithPrecision > boltzMax) {
        ref.read(sendAmountErrorProvider.notifier).state =
            AmountParsingException(AmountParsingExceptionType.aboveBoltzMax);
        logger.d(
            '[Send][Amount][Boltz] validate amount - amount $amountWithPrecision is above boltz max $boltzMax');
        throw AmountParsingException(AmountParsingExceptionType.aboveBoltzMax);
      }
    }

    // if sideshift, check if amount is above or below sideshift min/max
    if (asset.isSideshift) {
      final SideshiftAssetPair assetPair = SideshiftAssetPair(
        from: SideshiftAsset.usdtLiquid(),
        to: asset == Asset.usdtEth()
            ? SideshiftAsset.usdtEth()
            : SideshiftAsset.usdtTron(),
      );
      final currentPairInfo =
          ref.watch(sideshiftPairInfoProvider(assetPair)).asData?.value;
      final min = currentPairInfo?.min;
      final max = currentPairInfo?.max;
      if (min == null || max == null) {
        return false;
      }
      final precisionMultiplier = pow(10, asset.precision).toDouble();
      final double? minDouble = double.tryParse(min);
      final double? maxDouble = double.tryParse(max);
      if (minDouble == null || maxDouble == null) {
        return false;
      }
      final minPrecision = (minDouble * precisionMultiplier).toInt();
      final maxPrecision = (maxDouble * precisionMultiplier).toInt();

      logger.d(
          '[Send][Amount][Sideshift] validate amount - amount $amountWithPrecision - min $min - max $max');
      if (amountWithPrecision < minPrecision) {
        ref.read(sendAmountErrorProvider.notifier).state =
            AmountParsingException(
                AmountParsingExceptionType.belowSideShiftMin);
        logger.d(
            '[Send][Amount][Sideshift] validate amount - amount $amountWithPrecision is below sideshift min $min');
        throw AmountParsingException(
            AmountParsingExceptionType.belowSideShiftMin);
      } else if (amountWithPrecision > maxPrecision) {
        ref.read(sendAmountErrorProvider.notifier).state =
            AmountParsingException(
                AmountParsingExceptionType.aboveSideShiftMax);
        logger.d(
            '[Send][Amount][Sideshift] validate amount - amount $amountWithPrecision is above sideshift max $max');
        throw AmountParsingException(
            AmountParsingExceptionType.aboveSideShiftMax);
      }
    }

    ref.read(sendAmountErrorProvider.notifier).state = null;
    return true;
  }
}

final isFiatInputProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

/// Use all funds provider
final useAllFundsProvider =
    NotifierProvider.autoDispose<UseAllFundsStateNotifier, bool>(
        UseAllFundsStateNotifier.new);

class UseAllFundsStateNotifier extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  void setUseAllFunds(bool useAllFunds) {
    if (useAllFunds) {
      final asset = ref.read(sendAssetProvider);
      final assetBalanceInSats =
          ref.watch(getBalanceProvider(asset)).asData?.value;
      if (assetBalanceInSats == null) {
        return;
      }

      final amountWithoutPrecision =
          DecimalExt.satsToDecimal(assetBalanceInSats, asset.precision);
      ref
          .read(userEnteredAmountProvider.notifier)
          .updateAmount(amountWithoutPrecision);
    }
    state = useAllFunds;
  }
}

/// Entered amount converted with precision of asset.
/// - This is the amount needed for gdk transaction creation
/// - Basically, amount inputs to gdk are in "sats". This is intuitive for BTC and L-BTC, however,
///    they also carried this over to USDT and other assets. So $10 USDT is actually passed as 1000000000 in gdk transactions (based on `asset.precision`).
final enteredAmountWithPrecisionProvider =
    StateProvider.family.autoDispose<int, Decimal>((ref, amount) {
  final asset = ref.watch(sendAssetProvider);

  // convert from fiat input to sats if needed
  final isFiatEntry = ref.watch(isFiatInputProvider);
  final shouldConvertToSats =
      isFiatEntry && (asset.isBTC || asset.isLBTC || asset.isLightning);
  if (shouldConvertToSats) {
    final amountInSats =
        ref.watch(fiatToSatsAsIntProvider((asset, amount))).asData?.value ?? 0;
    return amountInSats;
  } else {
    final amountWithPrecision =
        (amount * DecimalExt.fromAssetPrecision(asset.precision)).toInt();
    return amountWithPrecision;
  }
});

/// ---------------------
/// Amount Display

/// UI display of fiat conversion amount
final amountConvertedToFiatWithSymbolDisplay =
    FutureProvider.autoDispose<String?>((ref) async {
  final isFiatInput = ref.read(isFiatInputProvider);
  if (isFiatInput) {
    return null;
  }
  final amount = ref.watch(userEnteredAmountProvider);
  final amountWithPrecision =
      ref.watch(enteredAmountWithPrecisionProvider(amount ?? Decimal.zero));
  final amountInFiat = await ref
      .read(fiatProvider)
      .getSatsToFiatDisplay(amountWithPrecision, true);
  return amountInFiat;
});

/// UI display of fiat > cryption conversion amount
final amountConvertedToCryptoDisplay = Provider.autoDispose<String?>((ref) {
  final asset = ref.watch(sendAssetProvider);
  final amount = ref.watch(userEnteredAmountProvider);
  final isFiatInput = ref.watch(isFiatInputProvider);
  if (amount == null || !isFiatInput) {
    return null;
  }
  final amountInCrypto = ref.watch(conversionFiatProvider((asset, amount)));
  if (amountInCrypto == null) {
    return null;
  }
  final fiatAmountInSats = ref.read(formatterProvider).parseAssetAmountDirect(
      amount: amountInCrypto, precision: asset.precision);
  final cryptoConversion = ref.read(formatterProvider).formatAssetAmountDirect(
        amount: fiatAmountInSats,
        precision: asset.precision,
      );
  return cryptoConversion;
});

/// UI display of amount (without fees)
final amountMinusFeesToDisplayProvider =
    StateProvider.autoDispose<String?>((ref) {
  final asset = ref.watch(sendAssetProvider);
  final userEnteredAmount = ref.watch(userEnteredAmountProvider);
  if (userEnteredAmount == null) {
    return null;
  }

  final enteredAmountWithPrecision =
      ref.watch(enteredAmountWithPrecisionProvider(userEnteredAmount));
  final assetPrecision = asset.precision;

  return ref.watch(formatterProvider).formatAssetAmountDirect(
        amount: enteredAmountWithPrecision,
        precision: assetPrecision,
      );
});

/// UI display of amount (with onchain fees and service fees)
final amountWithFeesToDisplayProvider =
    StateProvider.autoDispose.family<String?, Asset>((ref, asset) {
  final userEnteredAmount =
      ref.watch(userEnteredAmountProvider) ?? Decimal.zero;
  var fee = Decimal.fromInt(ref.watch(onchainFeeInSatsProvider));
  var serviceFee = Decimal.zero;

  // add service fees
  if (asset.isSideshift) {
    final sideshiftFee = ref.watch(sideshiftServiceFeeProvider(asset));
    serviceFee = Decimal.parse(sideshiftFee.toStringAsFixed(2));
    fee = DecimalExt.fromDouble(0.01); // hardcoded liquid fee for now
  } else if (asset.isLightning) {
    final boltzFee = ref.watch(boltzServiceFeeProvider(asset));
    serviceFee = Decimal.fromInt(boltzFee);
  }

  final total = userEnteredAmount + fee + serviceFee;
  final totalWithPrecision = ref.read(formatterProvider).parseAssetAmountDirect(
      amount: total.toString(), precision: asset.precision);
  return ref.watch(formatterProvider).formatAssetAmountDirect(
        amount: totalWithPrecision,
        precision: asset.precision,
      );
});

/// ---------------------
/// Setup

final sendAssetAmountSetupProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final asset = ref.read(sendAssetProvider);

  if (asset.isSideshift) {
    final SideshiftAssetPair assetPair = SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(),
      to: asset == Asset.usdtEth()
          ? SideshiftAsset.usdtEth()
          : SideshiftAsset.usdtTron(),
    );

    // Return `true` only if pair info is available
    try {
      final pairInfo =
          ref.watch(sideshiftPairInfoProvider(assetPair)).asData?.value;
      logger.d("[Send][Sideshift] pairInfo: $pairInfo");
      return pairInfo != null;
    } catch (e) {
      logger.e("[Send][Sideshift] pairInfo error: $e");
      rethrow;
    }
  }

  // Other assets don't need setup for amount
  return true;
});
