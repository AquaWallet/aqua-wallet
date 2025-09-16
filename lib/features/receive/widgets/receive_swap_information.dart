import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReceiveSwapInformation extends HookConsumerWidget {
  const ReceiveSwapInformation({
    super.key,
    required this.order,
    required this.deliverAssetNetwork,
  });

  final SwapOrder? order;
  final String deliverAssetNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionTitleStyle = useMemoized(() {
      return Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
          );
    });
    final sectionContentStyle = useMemoized(() {
      return Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colors.onBackground,
          );
    });

    final networkFee = order == null
        ? '---'
        : order!.hasNetworkFee
            ? '~\$${order!.displayNetworkFeeForUSDt}'
            : context.loc.noFee;
    final serviceFee = order?.serviceFee.value == Decimal.zero
        ? context.loc.noFee
        : order?.serviceFee.displayFee() ?? '---';
    final serviceType = order?.serviceType;
    final serviceUrl = serviceType?.serviceUrl(orderId: order?.id);

    if (order == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            bordered: true,
            borderColor: Theme.of(context).colors.cardOutlineColor,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.feeEstimate,
                    style: sectionTitleStyle,
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => ref
                                .read(urlLauncherProvider)
                                .open(serviceUrl ?? ''),
                          text: context.loc.receiveAssetScreenSwapServiceFee,
                          style: sectionContentStyle?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        serviceFee,
                        style: sectionContentStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.receiveAssetScreenCurrentAssetFee(
                            deliverAssetNetwork),
                        style: sectionContentStyle,
                      ),
                      Text(
                        networkFee,
                        style: sectionContentStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25.0),
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            bordered: true,
            borderColor: Theme.of(context).colors.cardOutlineColor,
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                await context.copyToClipboard(order?.id ?? '');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.loc.swapId,
                          style: sectionTitleStyle,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          order?.id ?? '',
                          style: sectionContentStyle,
                        ),
                      ],
                    ),
                    SvgPicture.asset(
                      Svgs.copy,
                      width: 12.0,
                      height: 12.0,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colors.onBackground,
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
