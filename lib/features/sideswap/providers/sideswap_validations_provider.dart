import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/settings.dart' hide AssetsResponse;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

final swapValidationsProvider = Provider.autoDispose
    .family<SideswapException?, BuildContext>((ref, context) {
  final priceStream = ref.watch(sideswapPriceStreamResultStateProvider);
  final inputState = ref.watch(sideswapInputStateProvider);
  final formatter = ref.read(formatProvider);
  final deliverIncomingSatoshi =
      ref.watch(swapIncomingDeliverSatoshiAmountProvider);
  final deliverAsset = inputState.deliverAsset;
  final receiveAsset = inputState.receiveAsset;

  //ANCHOR - Argument validation
  if (deliverAsset == null || receiveAsset == null) {
    return SideswapInvalidArgumentsException(
      message: context.loc.swapErrorUnselectedAsset,
    );
  }

  //ANCHOR - Is swappable validation
  final isSwappable = ref.read(swapAssetsProvider).isSwappable(
        deliverAsset,
        receiveAsset,
      );

  if (!isSwappable) {
    return switch (deliverAsset) {
      _ when (deliverAsset.isBTC) => SideswapInvalidArgumentsException(
          message: context.loc.swapErrorInvalidBtcPair,
        ),
      _ when (deliverAsset.isLBTC) => SideswapInvalidArgumentsException(
          message: context.loc.swapErrorInvalidLbtcPair,
        ),
      _ when (deliverAsset.isUSDt) => SideswapInvalidArgumentsException(
          message: context.loc.swapErrorInvalidUsdtPair,
        ),
      _ => SideswapInvalidArgumentsException(
          message: context.loc.swapErrorInvalidPair,
        ),
    };
  }

  //ANCHOR - Insufficient balance check
  final isDeliver = inputState.userInputSide == SwapUserInputSide.deliver;
  final assetBalance = isDeliver ? deliverAsset.amount : receiveAsset.amount;
  final assetSatoshi = isDeliver
      ? inputState.deliverAmountSatoshi
      : inputState.receiveAmountSatoshi;
  final isInsufficientBalance =
      assetBalance < assetSatoshi || assetBalance < deliverIncomingSatoshi;
  if (isInsufficientBalance) {
    return SideswapInsufficientFundsException(
      isDeliver: isDeliver,
      message: context.loc.insufficientFunds,
    );
  }

  final pegFeeError = ref.watch(amountMinusFirstOnchainFeeEstProvider).hasError;
  if (inputState.isPeg && inputState.deliverAmountSatoshi > 0 && pegFeeError) {
    return SideswapInsufficientFundsException(
      isDeliver: isDeliver,
      message: context.loc.swapErrorUnspendableAmount,
    );
  }

  //ANCHOR - Sideswap Peg errors
  final deliverAmountSat = inputState.deliverAmountSatoshi;
  if (inputState.isPeg && deliverAmountSat > 0) {
    final minPegInAmountSatWithFee = ref.watch(minPegInAmountWithFeeProvider);
    final minPegOutAmountSatWithFee = ref.watch(minPegOutAmountWithFeeProvider);

    final minPegInAmount = formatter.formatAssetAmount(
      amount: minPegInAmountSatWithFee,
      asset: deliverAsset,
    );
    final minPegOutAmount = formatter.formatAssetAmount(
      amount: minPegOutAmountSatWithFee,
      asset: deliverAsset,
    );

    if (inputState.isPegIn) {
      final pegInAmountLessThanMinLimit =
          deliverAmountSat < minPegInAmountSatWithFee;
      if (pegInAmountLessThanMinLimit) {
        return SideswapMinPegInAmountException(
          message: context.loc.errorMinPegInAmount(minPegInAmount),
        );
      }
    } else {
      final pegOutAmountLessThanMinLimit =
          deliverAmountSat < minPegOutAmountSatWithFee;
      if (pegOutAmountLessThanMinLimit) {
        return SideswapMinPegOutAmountException(
          message: context.loc.errorMinPegOutAmount(minPegOutAmount),
        );
      }
    }
  }

  //ANCHOR - Sideswap API errors
  if (priceStream != null && priceStream.errorMsg != null) {
    final convertedErrorMsg = _convertApiErrorToDisplayUnit(
      priceStream.errorMsg!,
      deliverAsset,
      formatter,
      ref.read(displayUnitsProvider),
    );

    if (inputState.userInputSide == SwapUserInputSide.deliver &&
        priceStream.sendAmount != null) {
      return SideswapSendAmountException(message: convertedErrorMsg);
    }
    if (inputState.userInputSide == SwapUserInputSide.receive &&
        priceStream.recvAmount != null) {
      return SideswapReceiveAmountException(message: convertedErrorMsg);
    }
  }

  return null;
});

/// Converts BTC amounts in API error messages to the user's display unit.
/// API errors like "Min: 0.000001626" are always in BTC format.
String _convertApiErrorToDisplayUnit(
  String errorMsg,
  Asset asset,
  FormatService formatter,
  DisplayUnitsProvider displayUnits,
) {
  final numberPattern = RegExp(r'(\d+\.?\d*)');
  final displayUnit = displayUnits.getForcedDisplayUnit(asset);
  final unitName = displayUnits.getAssetDisplayUnit(
    asset,
    forcedDisplayUnit: displayUnit,
  );

  return errorMsg.replaceAllMapped(numberPattern, (match) {
    final btcString = match.group(1)!;
    final btcDecimal = Decimal.tryParse(btcString);
    if (btcDecimal == null) return btcString;

    final sats = (btcDecimal * Decimal.fromInt(satsPerBtc)).toBigInt().toInt();
    final formattedAmount = formatter.formatAssetAmount(
      amount: sats,
      asset: asset,
      displayUnitOverride: displayUnit,
    );
    return '$formattedAmount $unitName';
  });
}

final swapLiquidityWarningProvider =
    Provider.autoDispose.family<SideswapWarning?, AppLocalizations>((ref, loc) {
  final inputState = ref.watch(sideswapInputStateProvider);
  final serverStatus = ref.watch(sideswapStatusStreamResultStateProvider);
  final deliverAmountSatoshi = inputState.deliverAmountSatoshi;

  if (!inputState.isPeg || deliverAmountSatoshi <= 0) {
    return null;
  }

  final receiveAsset = inputState.receiveAsset;
  if (receiveAsset == null) {
    return null;
  }

  if (inputState.isPegIn) {
    final liquidity = serverStatus?.pegInWalletBalance;
    if (liquidity != null && liquidity < deliverAmountSatoshi) {
      return SideswapInsufficientLiquidityWarning(
        message: loc.swapWarningInsufficientLiquidity,
      );
    }
  } else {
    final liquidity = serverStatus?.pegOutWalletBalance;
    if (liquidity != null && liquidity < deliverAmountSatoshi) {
      return SideswapInsufficientLiquidityWarning(
        message: loc.swapWarningInsufficientLiquidity,
      );
    }
  }

  return null;
});
