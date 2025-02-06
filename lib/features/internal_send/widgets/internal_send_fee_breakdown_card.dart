import 'dart:math';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
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
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //ANCHOR - Title
                Text(
                  context.loc.fees,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colors.onBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        // height: 1.5.0,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  width: 2.0,
                  color: context.colors.cardOutlineColor,
                ),
              ),
              child: Column(
                children: [
                  _FeeBreakdownItem(
                    title: context.loc.internalSendReviewSideswapServiceFee,
                    value: '0.1%',
                  ),
                  const SizedBox(height: 14.0),
                  _FeeBreakdownItem(
                    title: context.loc.internalSendReviewNetworkFee(
                      input.isPegIn
                          ? context.loc.internalSendReviewBitcoin
                          : context.loc.liquid,
                    ),
                    value: uiModel.networkFee,
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

// ignore: unused_element
class _RefreshButton extends ConsumerWidget {
  const _RefreshButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.square(
      dimension: 32.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            width: 14.0,
            height: 14.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4.0),
              border: Theme.of(context).isLight
                  ? Border.all(
                      color: Theme.of(context).colors.divider,
                      width: 2.0,
                    )
                  : null,
            ),
            child: Transform.rotate(
              angle: pi / 2,
              child: SvgPicture.asset(
                Svgs.walletExchange,
                fit: BoxFit.scaleDown,
                width: 14.0,
                height: 14.0,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colors.onBackground,
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
