import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapReviewInfoCard extends HookConsumerWidget {
  const SwapReviewInfoCard({
    super.key,
    required this.order,
    required this.input,
  });

  final SwapStartWebResult order;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, ref) {
    final asset = useMemoized(() => input.deliverAsset!);
    final receiveAmount = useMemoized(() {
      final asset = input.receiveAsset;
      final receiveAmount = order.recvAmount;
      if (asset != null) {
        final amount = ref.read(formatterProvider).formatAssetAmountDirect(
              amount: receiveAmount,
              precision: asset.precision,
            );
        return "$amount ${input.receiveAsset!.ticker}";
      }
      return '-';
    });

    return BoxShadowCard(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      color: Theme.of(context).colors.addressFieldContainerBackgroundColor,
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
                          input.deliverAmount,
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
            //ANCHOR - Receive Amount
            LabelCopyableTextView(
              label: context.loc.conversionReceiveAmount,
              value: receiveAmount,
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
              value: order.orderId,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
