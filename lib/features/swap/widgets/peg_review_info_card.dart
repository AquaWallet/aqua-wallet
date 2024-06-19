import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PegReviewInfoCard extends HookConsumerWidget {
  const PegReviewInfoCard({
    super.key,
    required this.data,
    required this.input,
  });

  final SwapPegReviewModel data;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = useMemoized(() => input.deliverAsset!);
    final deliverAmountDisplay = useMemoized(() => input.deliverAmount);
    final receiveAmountDisplay = useMemoized(() {
      return ref.read(formatterProvider).formatAssetAmountDirect(
            amount: data.receiveAmount,
            precision: asset.precision,
          );
    });

    return BoxShadowCard(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      color: Theme.of(context).colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                //ANCHOR - Logo
                AssetIcon(
                  assetId: asset.isLBTC ? 'Layer2Bitcoin' : asset.id,
                  assetLogoUrl: asset.logoUrl,
                  size: 51.r,
                ),
                SizedBox(width: 19.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),
                    //ANCHOR - Amount Title
                    Text(
                      context.loc.pegOrderReviewTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //ANCHOR - Amount
                        Text(
                          deliverAmountDisplay,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(width: 6.w),
                        //ANCHOR - Symbol
                        Text(
                          asset.ticker,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AquaColors.graniteGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 36.h),
            //ANCHOR - Receive amount
            LabelCopyableTextView(
              label: context.loc.conversionReceiveAmount,
              value: "$receiveAmountDisplay ${input.receiveAsset!.ticker}",
            ),
            //ANCHOR - Divider
            DashedDivider(
              height: 32.h,
              thickness: 2.h,
              color: Theme.of(context).colors.divider,
            ),
            //ANCHOR - Order ID
            LabelCopyableTextView(
              label: context.loc.pegOrderReviewOrderId,
              value: data.order.orderId,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
