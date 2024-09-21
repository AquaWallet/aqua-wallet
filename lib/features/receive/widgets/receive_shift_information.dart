import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

const kSideshiftUrl = 'https://sideshift.ai/?orderId=';

class ReceiveShiftInformation extends HookConsumerWidget {
  const ReceiveShiftInformation({
    super.key,
    required this.order,
    required this.assetNetwork,
  });

  final SideshiftOrder? order;
  final String assetNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    if (order is SideshiftVariableOrderResponse) {
      final variableOrder = order as SideshiftVariableOrderResponse;
      if (variableOrder.settleCoinNetworkFee != null) {
        double fee =
            double.tryParse(variableOrder.settleCoinNetworkFee!) ?? 0.0;
        networkFee = fee.toStringAsFixed(2);
      }
    }

    if (order == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                    context.loc.receiveAssetScreenFeeEstimate,
                    style: sectionTitleStyle,
                  ),
                  SizedBox(height: 12.h),
                  //ANCHOR - Sideshift Fees
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => ref
                                .read(urlLauncherProvider)
                                .open('$kSideshiftUrl${order?.id}'),
                          text:
                              context.loc.receiveAssetScreenSideshiftServiceFee,
                          style: sectionContentStyle?.copyWith(
                            decoration: TextDecoration.underline,
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
                        context.loc
                            .receiveAssetScreenCurrentAssetFee(assetNetwork),
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
                await context.copyToClipboard(order?.id ?? 'N/A');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //ANCHOR - Shift ID Label
                        Text(
                          context.loc.receiveAssetScreenShiftId,
                          style: sectionTitleStyle,
                        ),
                        SizedBox(height: 6.h),
                        //ANCHOR - Shift ID
                        Text(
                          order?.id ?? 'N/A',
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
      ),
    );
  }
}
