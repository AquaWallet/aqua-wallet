import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';

class SendAssetReviewInfoCard extends HookConsumerWidget {
  const SendAssetReviewInfoCard({
    super.key,
    required this.arguments,
  });

  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(sendAssetProvider);
    final amountDisplay = ref.watch(amountMinusFeesToDisplayProvider);

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
                  assetId: arguments.asset.id,
                  assetLogoUrl: arguments.asset.logoUrl,
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
                      AppLocalizations.of(context)!
                          .sendAssetReviewScreenConfirmAmountTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    //ANCHOR - Amount & Symbol
                    Text(
                      "$amountDisplay ${arguments.asset.ticker}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
            if (arguments.recipientAddress != null && !asset.isLightning) ...[
              //ANCHOR - Divider
              Divider(
                height: 36.h,
                thickness: 2.h,
                color: Theme.of(context).colors.divider,
              ),
              //ANCHOR - Address
              //TODO: This is not copying
              LabelCopyableTextView(
                label: AppLocalizations.of(context)!
                    .sendAssetReviewScreenConfirmAddressTitle,
                value: arguments.recipientAddress!,
              ),
              //ANCHOR - Shift id (sideshift only)
              if (arguments.asset.isSideshift) ...[
                SizedBox(height: 16.h),
                LabelCopyableTextView(
                  label: AppLocalizations.of(context)!
                      .sendAssetReviewScreenConfirmShiftIdTitle,
                  value: ref.watch(pendingOrderProvider)?.id ?? '',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
