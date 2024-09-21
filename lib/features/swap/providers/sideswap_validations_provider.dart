import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart' hide AssetsResponse;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';

final swapValidationsProvider = Provider.autoDispose
    .family<SideswapException?, BuildContext>((ref, context) {
  final priceStream = ref.watch(sideswapPriceStreamResultStateProvider);
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
      message: context.loc.exchangeSwapInsufficientFunds,
    );
  }

  final pegFeeError = ref.watch(amountMinusFirstOnchainFeeEstProvider).hasError;
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
    final minPegInAmountSatWithFee = ref.watch(minPegInAmountWithFeeProvider);
    final minPegOutAmountSatWithFee = ref.watch(minPegOutAmountWithFeeProvider);

    final minPegInAmount = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: minPegInAmountSatWithFee,
          precision: deliverAsset.precision,
        );
    final minPegOutAmount = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: minPegOutAmountSatWithFee,
          precision: deliverAsset.precision,
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

  return null;
});
