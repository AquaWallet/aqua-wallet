import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/send/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:aqua/data/provider/sideshift/models/sideshift.dart';

import 'package:aqua/features/settings/manage_assets/models/assets.dart';

class ReceiveShiftInformation extends HookConsumerWidget {
  const ReceiveShiftInformation({
    Key? key,
    required this.asset,
  }) : super(key: key);

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var assetName = "Ethereum";
    if (asset.isTrx) {
      assetName = "Tron";
    }
    final sideshiftOrder = ref.watch(pendingOrderProvider);

    final sectionTitleStyle = useMemoized(() {
      return Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          );
    });
    final sectionContentStyle = useMemoized(() {
      return Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onBackground,
          );
    });

    String networkFee = '---';
    if (sideshiftOrder is SideshiftVariableOrderResponse) {
      if (sideshiftOrder.settleCoinNetworkFee != null) {
        double fee =
            double.tryParse(sideshiftOrder.settleCoinNetworkFee!) ?? 0.0;
        networkFee = fee.toStringAsFixed(2);
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //ANCHOR - Amount Range Panel
          const AssetAmountRangePanel(),
          SizedBox(height: 21.h),
          if (sideshiftOrder != null) ...[
            //ANCHOR - Expiry Row
            BoxShadowCard(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              bordered: true,
              borderColor: Theme.of(context).colors.cardOutlineColor,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //ANCHOR - Section Title
                    Text(
                      AppLocalizations.of(context)!
                          .receiveAssetScreenFeeEstimate,
                      style: sectionTitleStyle,
                    ),
                    SizedBox(height: 12.h),
                    //ANCHOR - Sideshift Fees
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            ref.read(urlLauncherProvider).open(
                                'https://sideshift.ai/?orderId=${sideshiftOrder.id}');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .receiveAssetScreenSideshiftServiceFee,
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                        ),
                        Text(
                          '1%',
                          style: sectionContentStyle,
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    //ANCHOR - Estimated Fees
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .receiveAssetScreenCurrentAssetFee(assetName),
                          style: sectionContentStyle,
                        ),
                        Text(
                          '~\$$networkFee',
                          style: sectionContentStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 25.h),

            //ANCHOR - Shift ID
            BoxShadowCard(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              bordered: true,
              borderColor: Theme.of(context).colors.cardOutlineColor,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Clipboard.setData(
                    ClipboardData(text: sideshiftOrder.id ?? 'N/A'),
                  );
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //ANCHOR - Shift ID Label
                          Text(
                            AppLocalizations.of(context)!
                                .receiveAssetScreenShiftId,
                            style: sectionTitleStyle,
                          ),
                          SizedBox(height: 6.h),
                          //ANCHOR - Shift ID
                          Text(
                            sideshiftOrder.id ?? 'N/A',
                            style: sectionContentStyle,
                          ),
                        ],
                      ),
                      //ANCHOR - Copy Button
                      SvgPicture.asset(
                        Svgs.copy,
                        width: 12.r,
                        height: 12.r,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onBackground,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
