import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart' hide AssetsResponse;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';

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
      message: context.loc.swapErrorUnselectedAsset,
    );
  }
  if (deliverAsset.isBTC && !receiveAsset.isLBTC) {
    return SideswapInvalidArgumentsException(
      message: context.loc.swapErrorInvalidBtcPair,
    );
  }
  if (deliverAsset.isLBTC && (!receiveAsset.isBTC && !receiveAsset.isUSDt)) {
    return SideswapInvalidArgumentsException(
      message: context.loc.swapErrorInvalidLbtcPair,
    );
  }
  if (deliverAsset.isUSDt && !receiveAsset.isLBTC) {
    return SideswapInvalidArgumentsException(
      message: context.loc.swapErrorInvalidUsdtPair,
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
      message: context.loc.exchangeSwapInsufficientFunds,
    );
  }

  final pegFeeError = ref.watch(amountMinusChainFeeEstProvider).hasError;
  if (inputState.isPeg && inputState.deliverAmountSatoshi > 0 && pegFeeError) {
    return SideswapInsufficientFundsException(
      isDeliver: isDeliver,
      message: context.loc.swapErrorUnspendableAmount,
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
    final pegInServiceFee = statusStream?.serverFeePercentPegIn;
    final pegOutServiceFee = statusStream?.serverFeePercentPegOut;

    final minPegInAmountSatWithFee =
        minPegInAmountSat != null && pegInServiceFee != null
            ? (minPegInAmountSat + (minPegInAmountSat * pegInServiceFee / 100))
                .ceil()
            : null;
    final minPegOutAmountSatWithFee = minPegOutAmountSat != null &&
            pegOutServiceFee != null
        ? (minPegOutAmountSat + (minPegOutAmountSat * pegOutServiceFee / 100))
            .ceil()
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
          message: context.loc.errorMinPegInAmount(minPegInAmount),
        );
      }
    } else {
      final pegOutAmountLessThanMinLimit = minPegOutAmountSatWithFee != null &&
          deliverAmountSat < minPegOutAmountSatWithFee;
      if (pegOutAmountLessThanMinLimit) {
        return SideswapMinPegOutAmountException(
          message: context.loc.errorMinPegOutAmount(minPegOutAmount),
        );
      }
    }
  }

  return null;
});
