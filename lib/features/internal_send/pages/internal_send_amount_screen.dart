import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InternalSendAmountScreen extends HookConsumerWidget {
  const InternalSendAmountScreen({super.key});

  static const routeName = '/internalSendAmountScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments = ModalRoute.of(context)?.settings.arguments
        as InternalSendAmountArguments;

    final input = ref.watch(sideswapInputStateProvider);
    final swapAssets = ref.watch(swapAssetsProvider).assets;
    final isDarkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    final resetFormWithError = useCallback((String message) {
      ref.invalidate(sideswapInputStateProvider);
      context.showErrorSnackbar(message);
    });

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
              Navigator.of(context).pushNamed(
                InternalSendReviewScreen.routeName,
                arguments: InternalSendArguments.swapReview(
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
              Navigator.of(context).pushNamed(
                InternalSendReviewScreen.routeName,
                arguments: InternalSendArguments.pegReview(
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
                context.loc.pegInsufficientFeeBalanceError,
              ),
            PegGdkTransactionException _ => resetFormWithError(
                context.loc.pegErrorTransaction,
              ),
            _ => logger.d('[PEG] Error: $error'),
          },
          orElse: () {},
        ),
      );

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.internalSendScreenTitle,
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
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
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
                  SizedBox(width: 10.w),
                  //ANCHOR - Arrow Icon
                  SizedBox.square(
                    dimension: 24.r,
                    child: SvgPicture.asset(isDarkMode
                        ? Svgs.internalSendArrowLight
                        : Svgs.internalSendArrow),
                  ),
                  SizedBox(width: 10.w),
                  //ANCHOR - Receive Asset Logo
                  InternalSendAssetIcon(
                    asset: arguments.receiveAsset,
                    isLayerTwoIcon: arguments.receiveAsset.isLBTC,
                  ),
                ],
              ),
              const Row(),
              SizedBox(height: 16.h),
              //ANCHOR - Balance
              Text(
                '${input.deliverAssetBalance} ${input.deliverAsset?.ticker}',
                style: context.textTheme.headlineLarge,
              ),
              SizedBox(height: 20.h),
              if (!arguments.deliverAsset.isUSDt) ...[
                //ANCHOR - USD Balance
                const _AssetUsdBalance(),
                SizedBox(height: 40.h),
              ],
              //ANCHOR - Amount Input
              const _AmountInput(),
              SizedBox(height: 11.h),
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
                    SizedBox(width: 8.w),
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
      child: Text(context.loc.internalSendScreenContinueButton),
    );
  }
}

class _AmountConversionValue extends HookConsumerWidget {
  const _AmountConversionValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sideswapInputStateProvider);
    final amountSatsToFiat = ref
        .watch(satsToFiatDisplayWithSymbolProvider(input.deliverAmountSatoshi))
        .asData
        ?.value;
    final amountFiatToSats = input.deliverAsset != null
        ? ref.watch(conversionFiatProvider((
            input.deliverAsset!,
            ref.watch(parsedAssetAmountAsDecimalProvider(input.deliverAmount))
          )))
        : '';

    final convertedDeliverAmount = useMemoized(() {
      final ticker = input.deliverAsset?.ticker ?? '';
      final fiatToSats = amountFiatToSats ?? '';
      final satsToFiat = amountSatsToFiat ?? '';
      return input.isFiat ? '$ticker $fiatToSats' : satsToFiat;
    }, [input.deliverAsset, amountFiatToSats, amountSatsToFiat]);

    return Text(
      "≈ $convertedDeliverAmount",
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
        borderRadius: BorderRadius.circular(30.r),
      ),
      padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 3.h, bottom: 2.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            balance,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.usdPillTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
