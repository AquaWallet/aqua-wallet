import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart' hide AssetsResponse;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

final swapValidationsProvider = Provider.autoDispose
    .family<SideswapException?, BuildContext>((ref, context) {
  final priceStream = ref.watch(sideswapPriceStreamResultStateProvider);
  final statusStream = ref.watch(sideswapStatusStreamResultStateProvider);
  final inputState = ref.watch(sideswapInputStateProvider);
  final deliverIncomingSatoshi =
      ref.watch(swapIncomingDeliverSatoshiAmountProvider);
  final deliverAsset = inputState.deliverAsset;
  final receiveAsset = inputState.receiveAsset;

  //ANCHOR - Argument validation
  if (deliverAsset == null || receiveAsset == null) {
    return SideswapInvalidArgumentsException(
      message: AppLocalizations.of(context)!.swapErrorUnselectedAsset,
    );
  }
  if (deliverAsset.isBTC && !receiveAsset.isLBTC) {
    return SideswapInvalidArgumentsException(
      message: AppLocalizations.of(context)!.swapErrorInvalidBtcPair,
    );
  }
  if (deliverAsset.isLBTC && (!receiveAsset.isBTC && !receiveAsset.isUSDt)) {
    return SideswapInvalidArgumentsException(
      message: AppLocalizations.of(context)!.swapErrorInvalidLbtcPair,
    );
  }
  if (deliverAsset.isUSDt && !receiveAsset.isLBTC) {
    return SideswapInvalidArgumentsException(
      message: AppLocalizations.of(context)!.swapErrorInvalidUsdtPair,
    );
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
      message: AppLocalizations.of(context)!.exchangeSwapInsufficientFunds,
    );
  }

  final pegFeeError = ref.watch(maxPegFeeDeductedAmountProvider).hasError;
  if (inputState.isPeg && inputState.deliverAmountSatoshi > 0 && pegFeeError) {
    return SideswapInsufficientFundsException(
      isDeliver: isDeliver,
      message: AppLocalizations.of(context)!.swapErrorUnspendableAmount,
    );
  }

  //ANCHOR - Sideswap API errors
  if (priceStream != null && priceStream.errorMsg != null) {
    if (inputState.userInputSide == SwapUserInputSide.deliver &&
        priceStream.sendAmount != null) {
      return SideswapSendAmountException(message: priceStream.errorMsg!);
    }
    if (inputState.userInputSide == SwapUserInputSide.receive &&
        priceStream.recvAmount != null) {
      return SideswapReceiveAmountException(message: priceStream.errorMsg!);
    }
  }

  //ANCHOR - Sideswap Peg errors
  final deliverAmountSat = inputState.deliverAmountSatoshi;
  if (inputState.isPeg && deliverAmountSat > 0) {
    final minPegInAmountSat = statusStream?.minPegInAmount;
    final minPegOutAmountSat = statusStream?.minPegOutAmount;

    final minPegInAmountSatWithFee = minPegInAmountSat != null
        ? (minPegInAmountSat + (minPegInAmountSat * onePercent)).ceil()
        : null;
    final minPegOutAmountSatWithFee = minPegOutAmountSat != null
        ? (minPegOutAmountSat + (minPegOutAmountSat * onePercent)).ceil()
        : null;

    final minPegInAmount = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: minPegInAmountSatWithFee ?? 0,
          precision: deliverAsset.precision,
        );
    final minPegOutAmount = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: minPegOutAmountSatWithFee ?? 0,
          precision: deliverAsset.precision,
        );

    if (inputState.isPegIn) {
      final pegInAmountLessThanMinLimit = minPegInAmountSatWithFee != null &&
          deliverAmountSat < minPegInAmountSatWithFee;
      if (pegInAmountLessThanMinLimit) {
        return SideswapMinPegInAmountException(
          message:
              AppLocalizations.of(context)!.errorMinPegInAmount(minPegInAmount),
        );
      }
    } else {
      final pegOutAmountLessThanMinLimit = minPegOutAmountSatWithFee != null &&
          deliverAmountSat < minPegOutAmountSatWithFee;
      if (pegOutAmountLessThanMinLimit) {
        return SideswapMinPegOutAmountException(
          message: AppLocalizations.of(context)!
              .errorMinPegOutAmount(minPegOutAmount),
        );
      }
    }
  }

  return null;
});
