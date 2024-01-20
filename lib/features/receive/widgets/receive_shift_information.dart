import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/send/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class ReceiveShiftInformation extends ConsumerWidget {
  const ReceiveShiftInformation({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideshiftOrder = ref.watch(pendingOrderProvider);

    final formattedExpiresDate = sideshiftOrder?.expiresAt != null
        ? DateFormat('MMMM d, y').format(sideshiftOrder!.expiresAt!)
        : '---';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.receiveAssetScreenVariableShift,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                ),
                Text(
                  AppLocalizations.of(context)!
                      .receiveAssetScreenExpiresOn(formattedExpiresDate),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
            SizedBox(height: 25.h),

            //ANCHOR - Shift ID
            BoxShadowElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Clipboard.setData(
                    ClipboardData(text: sideshiftOrder.id ?? 'N/A'));
              },
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //ANCHOR - Shift ID Label
                      Text(
                        AppLocalizations.of(context)!.receiveAssetScreenShiftId,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      SizedBox(height: 6.h),
                      //ANCHOR - Shift ID
                      Text(
                        sideshiftOrder.id ?? 'N/A',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                      ),
                    ],
                  ),
                  //ANCHOR - Copy Button
                  SvgPicture.asset(Svgs.copy,
                      width: 12.r,
                      height: 12.r,
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onBackground,
                          BlendMode.srcIn)),
                ],
              ),
            ),

            //ANCHOR - Fees Notice
            SizedBox(height: 5.h),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () {
                  ref.read(urlLauncherProvider).open(
                      'https://sideshift.ai/?orderId=${sideshiftOrder.id}');
                },
                child: Text(AppLocalizations.of(context)!.sideshiftFeesNotice),
              ),
            )
          ],
        ],
      ),
    );
  }
}
