import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveSwapContent extends HookConsumerWidget
    with GenericErrorPromptMixin {
  const ReceiveSwapContent({
    super.key,
    required this.deliverAsset,
    this.swapPair,
  });

  final Asset deliverAsset;
  final SwapPair? swapPair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (swapPair == null) {
      return const SizedBox.shrink();
    }

    final args = useMemoized(() => SwapArgs(pair: swapPair!), [swapPair]);

    final swapOrder = ref.watch(swapOrderProvider(args));
    final order = swapOrder.valueOrNull?.order;
    final swapOrderNotifier = ref.read(swapOrderProvider(args).notifier);

    // Handle swap provider errors with modal
    ref.listen(swapOrderProvider(args), (_, state) {
      showGenericErrorPromptOnAsyncError(
        context,
        state,
        title: context.loc.genericSwapError,
        onPrimaryButtonTap: () {
          context.popUntilPath(ReceiveMenuScreen.routeName);
        },
      );
    });

    // create order
    final createSwapOrder = useCallback((String? amount) async {
      final swapAsset = SwapAssetExt.fromAsset(deliverAsset);
      final receiveAddress =
          (await ref.read(liquidProvider).getReceiveAddress())?.address;
      final request = SwapOrderRequest(
        receiveAddress: receiveAddress,
        from: swapAsset,
        to: SwapAssetExt.usdtLiquid,
        type: SwapOrderType.variable,
        amount: amount != null ? Decimal.parse(amount) : null,
      );
      await swapOrderNotifier.createReceiveOrder(request);
    }, [deliverAsset, swapOrderNotifier]);

    // amount (if needed)
    final needsAmount = swapOrderNotifier.needsAmountOnReceive;
    final showAmountSheet = useState(needsAmount);

    useEffect(() {
      if (!needsAmount) {
        createSwapOrder(null);
        return;
      }

      if (showAmountSheet.value && needsAmount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && swapOrder.valueOrNull?.rate != null) {
            final minLimit =
                '${swapOrder.valueOrNull?.rate?.min.toStringAsFixed(2)} USDt';
            final maxLimit =
                '${swapOrder.valueOrNull?.rate?.max.toStringAsFixed(2)} USDt';
            context.push(
              ReceiveAmountScreen.routeName,
              extra: ReceiveAmountArguments(
                asset: deliverAsset,
                swapPair: swapPair,
                minLimit: minLimit,
                maxLimit: maxLimit,
                onContinuePressed: () {
                  final amount = ref.read(receiveAssetAmountProvider);
                  showAmountSheet.value = false;
                  if (amount != null) {
                    createSwapOrder(amount.replaceAll(',', ''));
                  }
                },
                isAmountCompulsory: true,
              ),
            );
          } else {
            swapOrderNotifier.getRate();
          }
        });
      }
      return null;
    }, [showAmountSheet.value, needsAmount, swapOrder.valueOrNull?.rate]);

    // Handle errors and timeout - navigate to error screen
    ref.listen(swapOrderProvider(args), (_, state) {
      if (state.hasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.push(ServiceErrorScreen.routeName);
          }
        });
      }
    });

    // main qr content
    final enableShareButton = swapOrder.hasValue;
    final address = swapOrder.valueOrNull?.order?.depositAddress ?? '';

    //NOTE - The Swap content is too complicated to have simple Skeletonizer
    //wrapping, hence the easier route it just create a simplified loading state
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: order == null
          ? _LoadingContent(args: args)
          : _SwapContent(
              order: order,
              enableShareButton: enableShareButton,
              address: address,
            ),
    );
  }
}

class _SwapContent extends StatelessWidget {
  const _SwapContent({
    required this.order,
    required this.enableShareButton,
    required this.address,
  });

  final SwapOrder order;
  final bool enableShareButton;
  final String address;

  @override
  Widget build(BuildContext context) {
    final deliverAsset = order.from.toAsset();
    final swapPair = SwapPair(
      from: order.from,
      to: order.to,
    );

    return Column(
      children: [
        //ANCHOR - USDt Swap Warning
        const _SwapWarningLabel(),
        const SizedBox(height: 24),
        //ANCHOR - Address QR Code
        ReceiveAssetAddressQrCard(
          asset: deliverAsset,
          address: address,
          swapOrder: order,
          swapPair: swapPair,
        ),
        const SizedBox(height: 23),
        //ANCHOR - Swap Information Card
        ReceiveSwapInformation(
          order: order,
          swapPair: swapPair,
          deliverAssetNetwork: deliverAsset.usdtOption.networkLabel(context),
        ),
      ],
    );
  }
}

class _SwapWarningLabel extends StatelessWidget {
  const _SwapWarningLabel();

  @override
  Widget build(BuildContext context) {
    return Skeleton.keep(
      child: AquaText.body2Medium(
        text: context.loc.usdAutoSwapToLUsdtDescription,
        color: context.aquaColors.textTertiary,
      ),
    );
  }
}

class _LoadingContent extends HookConsumerWidget {
  const _LoadingContent({
    required this.args,
  });

  final SwapArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceProvider = args.serviceProvider ??
        ref.watch(swapServiceResolverProvider(args.pair));
    final serviceName = serviceProvider!.displayName;

    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          //ANCHOR - USDt Swap Warning
          const _SwapWarningLabel(),
          const SizedBox(height: 24),
          //ANCHOR - Address QR Code
          AquaCard.glass(
            width: double.maxFinite,
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                //ANCHOR - Warning Chip
                Skeleton.keep(
                  child: AltUsdtNetworkWarningChip(
                    asset: Asset.usdtEth(),
                  ),
                ),
                const SizedBox(height: 14),
                //ANCHOR - Single Use Address with expiry
                const Skeleton.keep(
                  child: SingleUseReceiveAddressLabel(),
                ),
                const SizedBox(height: 4),
                //ANCHOR - Expiry date
                AquaText.caption1Medium(
                  text: 'lorem ipsum dolor sit',
                  textAlign: TextAlign.center,
                  color: context.aquaColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Skeleton.shade(
                  child: Container(
                    width: kQrCardSize,
                    height: kQrCardSize,
                    decoration: BoxDecoration(
                      color: context.aquaColors.surfaceTertiary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'lorem ipsum dolor sit amet lorem ipsum sit',
                ),
                const Text(
                  'lorem ipsum dolor',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AquaCard.glass(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //ANCHOR - Range Min/Max
                  _LoadingStateInfoItem(
                    context.loc.range,
                  ),
                  const SizedBox(height: 32),
                  //ANCHOR - Swap Service Fee
                  _LoadingStateInfoItem(
                    context.loc.receiveAssetScreenSwapServiceFee,
                  ),
                  const SizedBox(height: 32),
                  //ANCHOR - Provider Processing Fee
                  _LoadingStateInfoItem(
                    context.loc.providerProcessingFee(serviceName),
                  ),
                  const SizedBox(height: 32),
                  //ANCHOR - Swap ID with copy button
                  _LoadingStateInfoItem(
                    context.loc.providerId,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _LoadingStateInfoItem extends StatelessWidget {
  const _LoadingStateInfoItem(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Skeleton.keep(
          child: Text(
            label,
            style: AquaTypography.body1SemiBold,
          ),
        ),
        const Text(
          'lorem',
          style: AquaTypography.body1SemiBold,
        ),
      ],
    );
  }
}
