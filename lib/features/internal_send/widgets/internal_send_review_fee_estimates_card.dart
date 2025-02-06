import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/config/config.dart';

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
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.feeEstimate,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colors.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0,
                    // height: 1.5.0,
                  ),
            ),
            const SizedBox(height: 6.0),
            if (sideswapServiceFeePercent != null) ...[
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewSideswapServiceFee,
                value: '$sideswapServiceFeePercent%',
              ),
              const SizedBox(height: 14.0),
            ],
            _FeeBreakdownItem(
              title: context.loc.networkFees,
              value: '$feeAmount BTC',
            ),
            if (rate != null) ...[
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewCurrentRate,
                value: rate,
              ),
            ],
            const SizedBox(height: 6.0),
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
                color: Theme.of(context).colors.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                letterSpacing: .5,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colors.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                letterSpacing: .5,
              ),
        ),
      ],
    );
  }
}
