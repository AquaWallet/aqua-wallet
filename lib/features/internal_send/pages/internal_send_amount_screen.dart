import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InternalSendAmountScreen extends HookConsumerWidget {
  const InternalSendAmountScreen({super.key, required this.arguments});
  final InternalSendAmountArguments arguments;

  static const routeName = '/internalSendAmountScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sideswapInputStateProvider);
    final swapAssets = ref.watch(swapAssetsProvider).assets;
    final isDarkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    final resetFormWithError = useCallback((String message) {
      ref.invalidate(sideswapInputStateProvider);
      context.showErrorSnackbar(message);
    });

    final cryptoAmountInSats = useMemoized(() {
      try {
        return ref.read(formatterProvider).parseAssetAmountDirect(
              amount: input.deliverAssetBalance,
              precision: arguments.deliverAsset.precision,
            );
      } catch (_) {
        return 0;
      }
    }, [input.deliverAssetBalance]);
    final displayUnit = ref.watch(displayUnitsProvider
        .select((p) => p.getForcedDisplayUnit(arguments.deliverAsset)));

    useEffect(() {
      Future.microtask(() {
        if (input.assets.isNotEmpty) {
          ref.read(sideswapInputStateProvider.notifier)
            ..setDeliverAsset(arguments.deliverAsset)
            ..setReceiveAsset(arguments.receiveAsset);
        }
      });
      return null;
    }, [swapAssets.length]);

    ref
      ..listen(
        sideswapWebsocketProvider,
        (_, __) {},
      )
      ..listen(
        swapDeliverAndReceiveWatcherProvider,
        (_, request) {
          if (request == null) {
            return;
          }

          ref.read(sideswapWebsocketProvider).subscribeAsset(request);
        },
      )
      ..listen(
        sideswapWebsocketSubscribedAssetIdStateProvider,
        (_, __) {},
      )
      ..listen(
        swapProvider,
        (_, state) => state.maybeWhen(
          data: (data) => data.maybeWhen(
            pendingVerification: (data) {
              context.push(
                InternalSendReviewScreen.routeName,
                extra: InternalSendArguments.swapReview(
                  deliverAsset: arguments.deliverAsset,
                  receiveAsset: arguments.receiveAsset,
                  swap: data,
                ),
              );
              return null;
            },
            orElse: () => null,
          ),
          orElse: () {},
        ),
      )
      ..listen(
        pegProvider,
        (_, state) => state.maybeWhen(
          data: (data) => data.maybeWhen(
            pendingVerification: (data) {
              context.push(
                InternalSendReviewScreen.routeName,
                extra: InternalSendArguments.pegReview(
                  deliverAsset: arguments.deliverAsset,
                  receiveAsset: arguments.receiveAsset,
                  peg: data,
                ),
              );
              return null;
            },
            orElse: () => null,
          ),
          error: (error, _) => switch (error.runtimeType) {
            PegGdkFeeExceedingAmountException _ => resetFormWithError(
                context.loc.pegErrorFeeExceedAmount,
              ),
            PegGdkInsufficientFeeBalanceException _ => resetFormWithError(
                context.loc.insufficientBalanceToCoverFees,
              ),
            PegGdkTransactionException _ => resetFormWithError(
                context.loc.pegErrorTransaction,
              ),
            _ => logger.debug('[PEG] Error: $error'),
          },
          orElse: () {},
        ),
      );

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.internalSend,
        showActionButton: false,
        backgroundColor: context.colors.inverseSurfaceColor,
        iconBackgroundColor:
            context.colors.addressFieldContainerBackgroundColor,
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: context.colors.inverseSurfaceColor,
      body: Skeletonizer(
        enabled: swapAssets.isEmpty,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //ANCHOR - Deliver Asset Logo
                  InternalSendAssetIcon(
                    asset: arguments.deliverAsset,
                    isLayerTwoIcon: arguments.receiveAsset.isBTC,
                  ),
                  const SizedBox(width: 10.0),
                  //ANCHOR - Arrow Icon
                  SizedBox.square(
                    dimension: 24.0,
                    child: SvgPicture.asset(isDarkMode
                        ? Svgs.internalSendArrowLight
                        : Svgs.internalSendArrow),
                  ),
                  const SizedBox(width: 10.0),
                  //ANCHOR - Receive Asset Logo
                  InternalSendAssetIcon(
                    asset: arguments.receiveAsset,
                    isLayerTwoIcon: arguments.receiveAsset.isLBTC,
                  ),
                ],
              ),
              const Row(),
              const SizedBox(height: 16.0),
              //ANCHOR - Balance
              AssetCryptoAmount(
                forceVisible: true,
                forceDisplayUnit: displayUnit,
                asset: arguments.deliverAsset,
                amount: cryptoAmountInSats.toString(),
                style: context.textTheme.headlineLarge,
              ),
              const SizedBox(height: 20.0),
              if (!arguments.deliverAsset.isUSDt) ...[
                //ANCHOR - USD Balance
                const _AssetUsdBalance(),
                const SizedBox(height: 40.0),
              ],
              //ANCHOR - Amount Input
              const _AmountInput(),
              const SizedBox(height: 11.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!arguments.deliverAsset.isUSDt) ...{
                    //ANCHOR - Min/Max Range
                    const _AmountConversionValue(),
                  },
                  const Spacer(),
                  //NOTE - Utility for sending minimum possible amount for testing
                  if (kDebugMode && input.isPeg) ...[
                    //ANCHOR - Send Minimum Possible Amount Button
                    const SwapSendMinButton(),
                    const SizedBox(width: 8.0),
                  ],
                  //ANCHOR - Send All Button
                  const SwapSendMaxButton(),
                ],
              ),
              //ANCHOR - Error Message
              const _AmountInputError(),
              const Spacer(),
              //ANCHOR - Swap Button
              const _CreateSwapButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountInputError extends HookConsumerWidget {
  const _AmountInputError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationError = ref.watch(swapValidationsProvider(context));
    return CustomError(errorMessage: validationError?.message);
  }
}

class _AmountInput extends HookConsumerWidget {
  const _AmountInput();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountInputController = useTextEditingController();

    final input = ref.watch(sideswapInputStateProvider);
    final currency =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
    useEffect(() {
      amountInputController.text = input.deliverAmount;
      return null;
    }, [input.deliverAmount]);

    return SendAssetAmountInput(
      controller: amountInputController,
      onChanged: (value) =>
          ref.read(sideswapInputStateProvider.notifier).setDeliverAmount(value),
      onCurrencyTypeToggle: () =>
          ref.read(sideswapInputStateProvider.notifier).switchInputType(),
      symbol: input.isFiat
          ? currency.currency.value
          : input.deliverAsset?.ticker ?? '',
      //TODO - Add support for Fiat/Crypto switching
      allowUsdToggle: false,
      precision: input.deliverAsset?.precision ?? 8,
    );
  }
}

class _CreateSwapButton extends HookConsumerWidget {
  const _CreateSwapButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sideswapInputStateProvider);
    final validationError = ref.watch(swapValidationsProvider(context));
    final deliverIncomingSatoshi =
        ref.watch(swapIncomingDeliverSatoshiAmountProvider);
    final receiveIncomingSatoshi =
        ref.watch(swapIncomingReceiveSatoshiAmountProvider(context));

    final isContinueEnabled = useMemoized(
      () =>
          validationError == null &&
          deliverIncomingSatoshi > 0 &&
          receiveIncomingSatoshi > 0,
      [validationError, deliverIncomingSatoshi, receiveIncomingSatoshi],
    );

    final onContinueHandler = useCallback(() async {
      if (input.isPeg) {
        ref.read(sideswapWebsocketProvider).sendPeg(isPegIn: input.isPegIn);
      } else {
        final priceOffer = ref.read(sideswapPriceStreamResultStateProvider);
        if (priceOffer != null) {
          ref.read(sideswapWebsocketProvider).sendSwap(priceOffer);
        }
      }
    }, [input.isPeg]);

    return AquaElevatedButton(
      onPressed: isContinueEnabled ? onContinueHandler : null,
      debounce: true,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: context.colorScheme.onSurface.withOpacity(.3),
        disabledForegroundColor: context.colorScheme.onSurface,
      ),
      child: Text(context.loc.continueLabel),
    );
  }
}

class _AmountConversionValue extends HookConsumerWidget {
  const _AmountConversionValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sideswapInputStateProvider);

    final convertedDeliverAmount = useMemoized(() {
      return input.isFiat
          ? input.deliverAmount
          : ref
                  .read(satsToFiatDisplayWithSymbolProvider(
                      input.deliverAmountSatoshi))
                  .asData
                  ?.value ??
              '';
    }, [input]);

    return AssetCryptoAmount(
      forceVisible: true,
      amount: convertedDeliverAmount,
      asset: input.isFiat ? input.deliverAsset : null,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _AssetUsdBalance extends HookConsumerWidget {
  const _AssetUsdBalance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sideswapInputStateProvider);
    final balance = ref
            .watch(satsToFiatDisplayWithSymbolProvider(
                input.deliverAsset?.amount ?? 0))
            .asData
            ?.value ??
        '';

    return Container(
      decoration: BoxDecoration(
        color: context.colors.usdPillBackgroundColor,
        borderRadius: BorderRadius.circular(30.0),
      ),
      padding:
          const EdgeInsets.only(left: 20.0, right: 20.0, top: 3.0, bottom: 2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AssetCryptoAmount(
            forceVisible: true,
            amount: balance,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.usdPillTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
