import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SwapForm extends HookConsumerWidget {
  const SwapForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliverFocusNode = useFocusNode();

    final progressState = ref.watch(swapLoadingIndicatorStateProvider);
    final isLoading = progressState == const SwapProgressState.connecting();
    final validationError = ref.watch(swapValidationsProvider(context));

    final deliverIncomingSatoshi =
        ref.watch(swapIncomingDeliverSatoshiAmountProvider);
    final receiveIncomingSatoshi =
        ref.watch(swapIncomingReceiveSatoshiAmountProvider(context));

    deliverFocusNode.addListener(() {
      if (deliverFocusNode.hasFocus) {
        ref.read(sideswapInputStateProvider.notifier)
          ..setUserInputSide(SwapUserInputSide.deliver)
          ..setDeliverAmount(ref.read(swapIncomingDeliverAmountProvider));
      }
    });
    ref.listen(
      sideswapWebsocketSubscribedAssetIdStateProvider,
      (_, __) {},
    );

    final isContinueEnabled = validationError == null &&
        deliverIncomingSatoshi > 0 &&
        receiveIncomingSatoshi > 0;
    final input = ref.watch(sideswapInputStateProvider);

    final onContinueHandler = useCallback(() async {
      if (input.isPeg) {
        ref.read(sideswapWebsocketProvider).sendPeg(isPegIn: input.isPegIn);
      } else {
        final priceOffer = ref.read(sideswapPriceStreamResultStateProvider);
        if (priceOffer != null) {
          ref.read(sideswapWebsocketProvider).sendSwap(priceOffer);
        }
      }
    }, [input]);

    return Skeletonizer(
      enabled: isLoading,
      child: SingleChildScrollView(
        child: BoxShadowContainer(
          decoration: BoxDecoration(
            color: Theme.of(context).colors.inverseSurfaceColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            boxShadow: [Theme.of(context).shadow],
          ),
          padding: EdgeInsets.only(
            top: context.adaptiveDouble(mobile: 114.0, smallMobile: 94.0),
            bottom: 34.0,
            left: 28.0,
            right: 28.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
              //ANCHOR - Deliver Asset
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      //ANCHOR - Title
                      Text(
                        context.loc.exchangeTransferFromTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                  const SizedBox(height: 13.0),
                  //ANCHOR - Deliver Asset Picker
                  SwapAmountInput(
                    isReceive: false,
                    focusNode: deliverFocusNode,
                    onChanged: (value) => ref
                        .read(sideswapInputStateProvider.notifier)
                        .setDeliverAmount(value),
                    onAssetSelected: (asset) => ref
                        .read(sideswapInputStateProvider.notifier)
                        .setDeliverAsset(asset),
                  ),
                  const SizedBox(height: 14.0),
                  //ANCHOR - Balance
                  SwapAssetBalance(
                    isReceive: false,
                    textColor: validationError?.message != null
                        ? AquaColors.vermillion
                        : null,
                  ),
                ],
              ),
              SizedBox(
                  height:
                      context.adaptiveDouble(mobile: 18.0, smallMobile: 5.0)),
              const Row(
                children: [
                  //ANCHOR - Rate
                  SwapConversionRateView(),
                  Spacer(),
                  //ANCHOR - Switch button
                  SwapAssetsSwitchButton(),
                ],
              ),
              SizedBox(
                  height:
                      context.adaptiveDouble(mobile: 18.0, smallMobile: 5.0)),
              //ANCHOR - Receive Asset
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //ANCHOR - Title
                  Text(
                    context.loc.exchangeTransferToTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 9.0),
                  //ANCHOR - Receive Asset Picker
                  SwapAmountInput(
                    isReceive: true,
                    isEditable: false,
                    onChanged: (value) => ref
                        .read(sideswapInputStateProvider.notifier)
                        .setReceiveAmount(value),
                    onAssetSelected: (asset) => ref
                        .read(sideswapInputStateProvider.notifier)
                        .setReceiveAsset(asset),
                  ),
                  const SizedBox(height: 14.0),
                  //ANCHOR - Balance
                  const SwapAssetBalance(isReceive: true),
                ],
              ),
              SizedBox(
                  height:
                      context.adaptiveDouble(mobile: 18.0, smallMobile: 5.0)),
              //ANCHOR - Error Message
              CustomError(errorMessage: validationError?.message),
              SizedBox(
                  height:
                      context.adaptiveDouble(mobile: 22.0, smallMobile: 5.0)),
              //ANCHOR - Swap Button
              AquaElevatedButton(
                onPressed: isContinueEnabled ? onContinueHandler : null,
                debounce: true,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.3),
                  disabledForegroundColor:
                      Theme.of(context).colorScheme.onSurface,
                ),
                child: Text(context.loc.continueLabel),
              ),
              SizedBox(
                  height:
                      context.adaptiveDouble(mobile: 30.0, smallMobile: 10.0)),
              //ANCHOR - Peg Info Message
              const PegInfoMessageView(),
            ],
          ),
        ),
      ),
    );
  }
}

class SwapScreen extends HookConsumerWidget {
  static const routeName = '/exchangeSwapScreen';

  const SwapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resetFormWithError = useCallback((String message) {
      ref.invalidate(sideswapInputStateProvider);
      context.showErrorSnackbar(message);
    }, []);
    ref.listen(
      sideswapWebsocketProvider,
      (_, __) {},
    );
    ref.listen(
      swapDeliverAndReceiveWatcherProvider,
      (_, request) {
        if (request == null) {
          return;
        }

        ref.read(sideswapWebsocketProvider).subscribeAsset(request);
      },
    );
    ref.listen(
      swapAssetsProvider,
      (_, notifier) {
        final assets = notifier.assets;
        if (assets.isEmpty || assets.length < 2) {
          return;
        }

        final deliverAsset = assets.firstWhere((e) => e.isLBTC);
        final receiveAsset = assets.firstWhere((e) => e.id != deliverAsset.id);

        ref.read(sideswapInputStateProvider.notifier)
          ..setDeliverAsset(deliverAsset)
          ..setReceiveAsset(receiveAsset);
      },
    );
    ref.listen(
      swapProvider,
      (_, state) => state.maybeWhen(
        data: (data) => data.maybeWhen(
          pendingVerification: (data) => context.push(
            SwapReviewScreen.routeName,
            extra: data,
          ),
          orElse: () => null,
        ),
        orElse: () {},
      ),
    );
    ref.listen(
      pegProvider,
      (_, state) => state.maybeWhen(
        data: (data) => data.maybeWhen(
          pendingVerification: (data) => context.push(
            SwapReviewScreen.routeName,
            extra: data,
          ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AquaAppBar(
        title: context.loc.swaps,
        showActionButton: false,
        backgroundColor: Theme.of(context).colors.inverseSurfaceColor,
        foregroundColor: Theme.of(context).colors.onBackground,
        iconBackgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        iconForegroundColor: Theme.of(context).colors.onBackground,
      ),
      extendBodyBehindAppBar: true,
      body: const SwapForm(),
    );
  }
}
