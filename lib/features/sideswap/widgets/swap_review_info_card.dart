import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/components/icon/icon.dart';

class SwapReviewInfoCard extends HookConsumerWidget {
  const SwapReviewInfoCard({
    super.key,
    required this.order,
    required this.input,
  });

  final SwapStartWebResult order;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliverAsset = useMemoized(() => input.deliverAsset!);
    final deliverDisplayUnit = ref.watch(displayUnitsProvider
        .select((p) => p.getForcedDisplayUnit(deliverAsset)));
    final formatter = ref.read(formatProvider);
    final deliverCryptoAmountInSats = useMemoized(() {
      if (input.deliverAmount.isEmpty) return 0;
      return ref.read(formatterProvider).parseAssetAmountToSats(
            amount: input.deliverAmount,
            precision: deliverAsset.precision,
            asset: deliverAsset,
          );
    }, [input.deliverAmount, deliverAsset.precision]);

    final receiveAsset = useMemoized(() => input.receiveAsset);
    final receiveDisplayUnit = ref.watch(displayUnitsProvider.select((p) =>
        receiveAsset != null ? p.getForcedDisplayUnit(receiveAsset) : null));

    final receiveAmountFormattedString = useMemoized(() {
      if (receiveAsset != null && receiveDisplayUnit != null) {
        final rawReceiveAmount = order.recvAmount;
        final formattedAmountOnly = formatter.formatAssetAmount(
          amount: rawReceiveAmount,
          asset: receiveAsset,
          displayUnitOverride: receiveDisplayUnit,
        );
        final ticker = receiveAsset.getDisplayTicker(receiveDisplayUnit);
        return "$formattedAmountOnly $ticker";
      }
      return '-';
    }, [order.recvAmount, receiveAsset, receiveDisplayUnit]);

    return BoxShadowCard(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      color: Theme.of(context).colors.addressFieldContainerBackgroundColor,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                deliverAsset.isLBTC
                    ? AquaAssetIcon.lightningBtcComposite(
                        size: 51.0,
                      )
                    : AssetIcon(
                        assetId: deliverAsset.id,
                        assetLogoUrl: deliverAsset.logoUrl,
                        size: 51.0,
                      ),
                const SizedBox(width: 19.0),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2.0),
                    Text(
                      context.loc.pegOrderReviewTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    AssetCryptoAmount(
                      forceVisible: true,
                      asset: deliverAsset,
                      amount: deliverCryptoAmountInSats.toString(),
                      style: Theme.of(context).textTheme.headlineSmall,
                      forceDisplayUnit: deliverDisplayUnit,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36.0),
            LabelCopyableTextView(
              label: context.loc.youWillReceive,
              value: receiveAmountFormattedString,
            ),
            //ANCHOR - Divider
            DashedDivider(
              height: 32.0,
              thickness: 2.0,
              color: Theme.of(context).colors.divider,
            ),
            //ANCHOR - Order ID
            LabelCopyableTextView(
              label: context.loc.orderId,
              value: order.orderId,
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
