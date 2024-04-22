import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/logger.dart';

final swapLoadingIndicatorStateProvider =
    StateProvider.autoDispose<SwapProgressState>((ref) {
  final sideswapAssets = ref.watch(swapAssetsProvider).assets;
  if (sideswapAssets.isEmpty) {
    return const SwapProgressState.connecting();
  }

  return const SwapProgressState.empty();
});

final sideswapStatusStreamResultStateProvider =
    StateProvider.autoDispose<ServerStatusResult?>((ref) => null);

final sideswapPriceStreamResultStateProvider =
    StateProvider.autoDispose<PriceStreamResult?>((ref) => null);

final sideswapWebsocketSubscribedAssetIdStateProvider =
    StateProvider.autoDispose<String>((ref) => '');

final swapDeliverAndReceiveWatcherProvider =
    Provider.autoDispose<SubscribePriceStreamRequest?>((ref) {
  final inputState = ref.watch(sideswapInputStateProvider);

  final sendBitcoins = inputState.deliverAsset?.isLBTC == true;
  final asset =
      sendBitcoins ? inputState.receiveAsset : inputState.deliverAsset;

  return SubscribePriceStreamRequest(
    asset: asset?.id ?? '',
    sendBitcoins: sendBitcoins,
    sendAmount: inputState.userInputSendAmount,
    recvAmount: inputState.userInputReceiveAmount,
  );
});

final sideswapConversionRateAmountProvider =
    Provider.autoDispose<String?>((ref) {
  final inputState = ref.watch(sideswapInputStateProvider);

  if (inputState.isPeg) {
    return inputState.isPegIn ? '1 BTC = 1 L-BTC' : '1 L-BTC = 1 BTC';
  }

  final allAssets = ref.watch(assetsProvider);
  final bestOffer = ref.watch(sideswapPriceStreamResultStateProvider);

  if (bestOffer == null) {
    return null;
  }

  final subscribedAssetId =
      ref.watch(sideswapWebsocketSubscribedAssetIdStateProvider);

  return allAssets.maybeWhen(data: (assets) {
    if (assets.any((e) => e.id == subscribedAssetId)) {
      final asset = assets.firstWhere((e) => e.id == subscribedAssetId);

      if (!(bestOffer.price == null || subscribedAssetId.isEmpty)) {
        final d = ref
            .watch(currencyFormatProvider(2))
            .format(bestOffer.price!)
            .replaceAllMapped(
                reRemoveTrailingDecimals, (e) => e.group(1) ?? '');
        return '1 L-BTC = $d ${asset.ticker}';
      }
    }

    return null;
  }, orElse: () {
    return null;
  });
});

final swapIncomingDeliverAmountProvider = Provider.autoDispose<String>((ref) {
  final inputState = ref.watch(sideswapInputStateProvider);
  final priceStream = ref.watch(sideswapPriceStreamResultStateProvider);

  final deliverAsset = inputState.deliverAsset;

  if (deliverAsset == null ||
      inputState.receiveAsset == null ||
      priceStream == null) {
    return inputState.deliverAmount.toString();
  }

  if (priceStream.sendAmount == inputState.deliverAmountSatoshi) {
    return ref.read(formatterProvider).convertAssetAmountToDisplayUnit(
          amount: priceStream.sendAmount ?? 0,
          precision: deliverAsset.precision,
        );
  }

  return inputState.deliverAmount.toString();
});

final swapIncomingDeliverSatoshiAmountProvider =
    Provider.autoDispose<int>((ref) {
  final inputState = ref.watch(sideswapInputStateProvider);
  final deliverIncomingAmount = ref.watch(swapIncomingDeliverAmountProvider);

  final deliverAsset = inputState.deliverAsset;

  if (deliverAsset == null || deliverIncomingAmount.isEmpty) {
    return 0;
  }

  return ref.watch(formatterProvider).parseAssetAmountDirect(
        amount: deliverIncomingAmount,
        precision: deliverAsset.precision,
      );
});

final swapIncomingReceiveAmountProvider =
    Provider.autoDispose.family<String, BuildContext>((ref, context) {
  final inputState = ref.watch(sideswapInputStateProvider);
  final invalidConversion = inputState.deliverAsset != null &&
      inputState.receiveAsset != null &&
      inputState.deliverAsset!.id == inputState.receiveAsset!.id;
  final swapValidationError = ref.watch(swapValidationsProvider(context));

  if (invalidConversion || swapValidationError != null) {
    return '0';
  }

  final receiveAsset = inputState.receiveAsset;
  if (inputState.isPeg) {
    final amount = ref.read(formatterProvider).convertAssetAmountToDisplayUnit(
          amount: ref.watch(maxPegFeeDeductedAmountProvider).asData?.value ?? 0,
          precision: inputState.deliverAsset!.precision,
        );
    logger.d('[PEG] MaxPegFeeDeductedAmount: $amount');
    if (amount == "0") {
      return amount;
    } else {
      // this is the sideswap fee. This should ideally come from the value we
      // get from the `server_status` call to sideswap. but puttin this in for
      // now do we are accurate in predicting how much btc/lbtc comes back to
      // the user.
      final amountAfterSideSwapFeeDedcution =
          double.parse(amount) * sideSwapPegInOutReturnRate;
      return amountAfterSideSwapFeeDedcution
          .toStringAsFixed(inputState.deliverAsset!.precision);
    }
  }

  final priceStream = ref.watch(sideswapPriceStreamResultStateProvider);

  if (inputState.deliverAsset == null ||
      receiveAsset == null ||
      priceStream == null) {
    return inputState.receiveAmount.toString();
  }

  if (priceStream.recvAmount != null) {
    return ref.watch(formatterProvider).convertAssetAmountToDisplayUnit(
          amount: priceStream.recvAmount ?? 0,
          precision: receiveAsset.precision,
        );
  }

  return inputState.receiveAmount.toString();
});

final swapIncomingReceiveSatoshiAmountProvider =
    Provider.autoDispose.family<int, BuildContext>((ref, context) {
  final inputState = ref.watch(sideswapInputStateProvider);
  final receiveIncomingAmount =
      ref.watch(swapIncomingReceiveAmountProvider(context));

  final receiveAsset = inputState.receiveAsset;

  if (receiveAsset == null || receiveIncomingAmount.isEmpty) {
    return 0;
  }

  return ref.watch(formatterProvider).parseAssetAmountDirect(
        amount: receiveIncomingAmount,
        precision: receiveAsset.precision,
      );
});
