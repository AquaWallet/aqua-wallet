import 'dart:math';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class InternalSendFeeBreakdownCard extends HookConsumerWidget {
  const InternalSendFeeBreakdownCard({
    super.key,
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context, ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final input = ref.watch(sideswapInputStateProvider);
    final rate = ref.watch(sideswapConversionRateAmountProvider);

    return BoxShadowCard(
      color: context.colors.addressFieldContainerBackgroundColor,
      bordered: !darkMode,
      borderColor: context.colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //ANCHOR - Title
                Text(
                  context.loc.internalSendSuccessFeeTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        // height: 1.5.h,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  width: 2.w,
                  color: context.colors.cardOutlineColor,
                ),
              ),
              child: Column(
                children: [
                  _FeeBreakdownItem(
                    title: context.loc.internalSendReviewSideswapServiceFee,
                    value: '0.1%',
                  ),
                  SizedBox(height: 14.h),
                  _FeeBreakdownItem(
                    title: context.loc.internalSendReviewNetworkFee(
                      input.isPegIn
                          ? context.loc.internalSendReviewBitcoin
                          : context.loc.internalSendReviewLiquid,
                    ),
                    value: uiModel.networkFee,
                  ),
                  if (rate != null) ...[
                    SizedBox(height: 14.h),
                    _FeeBreakdownItem(
                      title: context.loc.internalSendReviewCurrentRate,
                      value: rate,
                    ),
                  ],
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeBreakdownItem extends StatelessWidget {
  const _FeeBreakdownItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                letterSpacing: .5,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                letterSpacing: .5,
              ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _RefreshButton extends ConsumerWidget {
  const _RefreshButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.square(
      dimension: 32.r,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            width: 14.r,
            height: 14.r,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4.r),
              border: Theme.of(context).isLight
                  ? Border.all(
                      color: Theme.of(context).colors.divider,
                      width: 2.r,
                    )
                  : null,
            ),
            child: Transform.rotate(
              angle: pi / 2,
              child: SvgPicture.asset(
                Svgs.walletExchange,
                fit: BoxFit.scaleDown,
                width: 14.r,
                height: 14.r,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onBackground,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
