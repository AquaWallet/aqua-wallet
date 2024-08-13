import 'package:aqua/config/config.dart';
import 'package:aqua/features/sideshift/providers/sideshift_send_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class SendAssetReviewInfoCard extends HookConsumerWidget {
  const SendAssetReviewInfoCard({
    super.key,
    required this.amountDisplay,
  });

  final String amountDisplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(sendAssetProvider);
    final address = ref.watch(sendAddressProvider);
    final sideShiftOrderId = ref.watch(sideshiftPendingOrderProvider)?.id ?? '';

    return BoxShadowCard(
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
                  assetId: asset.id,
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
                      context.loc.sendAssetReviewScreenConfirmAmountTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    //ANCHOR - Amount & Symbol
                    Text(
                      "$amountDisplay ${asset.ticker}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
            if (address != null && !asset.isLightning) ...[
              //ANCHOR - Address
              LabelCopyableTextView(
                label: context.loc.sendAssetReviewScreenConfirmAddressTitle,
                value: address,
              ),
              //ANCHOR - Divider
              DashedDivider(
                height: 36.h,
                thickness: 2.h,
                color: Theme.of(context).colors.divider,
              ),
              //ANCHOR - Shift id (sideshift only)
              if (asset.isSideshift) ...[
                SizedBox(height: 16.h),
                LabelCopyableTextView(
                  label: context.loc.sendAssetReviewScreenConfirmShiftIdTitle,
                  value: sideShiftOrderId,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
