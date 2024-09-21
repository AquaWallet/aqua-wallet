import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InternalSendReviewFeeEstimatesCard extends HookConsumerWidget {
  const InternalSendReviewFeeEstimatesCard({
    super.key,
    required this.arguments,
  });

  final InternalSendArguments arguments;

  @override
  Widget build(BuildContext context, ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final input = ref.watch(sideswapInputStateProvider);
    final rate = ref.watch(sideswapConversionRateAmountProvider);
    final status = ref.watch(sideswapStatusStreamResultStateProvider);

    final sideswapServiceFeePercent = useMemoized(() {
      return input.isPegIn
          ? status?.serverFeePercentPegIn
          : status?.serverFeePercentPegOut;
    }, [status, input.isPegIn]);

    final feeAmount = useMemoized(() {
      final orderFeeAmount = arguments.maybeMap(
        pegReview: (s) => s.peg.feeAmount,
        orElse: () => 0,
      );
      return ref.read(formatterProvider).formatAssetAmountDirect(
            amount: orderFeeAmount,
            precision: arguments.deliverAsset.precision,
          );
    });

    return BoxShadowCard(
      color: context.colors.addressFieldContainerBackgroundColor,
      bordered: !darkMode,
      borderColor: context.colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 15.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.internalSendReviewFeeEstimate,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                    // height: 1.5.h,
                  ),
            ),
            SizedBox(height: 6.h),
            if (sideswapServiceFeePercent != null) ...[
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewSideswapServiceFee,
                value: '$sideswapServiceFeePercent%',
              ),
              SizedBox(height: 14.h),
            ],
            _FeeBreakdownItem(
              title: context.loc.internalSendReviewNetworkFees,
              value: '$feeAmount BTC',
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
