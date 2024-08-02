import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InternalSendSwapReviewAmountsCard extends HookConsumerWidget {
  const InternalSendSwapReviewAmountsCard({
    super.key,
    required this.arguments,
  });

  final InternalSendArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final input = ref.read(sideswapInputStateProvider);

    final receiveAmount = useMemoized(() {
      final orderReceiveAmount = arguments.maybeMap(
        pegReview: (s) => s.peg.receiveAmount,
        swapReview: (s) => s.swap.result!.recvAmount,
        orElse: () => throw Exception('Invalid state'),
      );
      return ref.read(formatterProvider).formatAssetAmountDirect(
            amount: orderReceiveAmount,
            precision: arguments.receiveAsset.precision,
          );
    });

    return BoxShadowCard(
      color: context.colors.addressFieldContainerBackgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      bordered: !darkMode,
      borderColor: context.colors.cardOutlineColor,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Send Amount
            _AssetAmountInfo(
              title: context.loc.internalSendReviewSendAmountTitle,
              asset: arguments.deliverAsset,
              amount: input.deliverAmount,
            ),
            //ANCHOR - Divider
            Divider(
              height: 24.h,
              thickness: 1.h,
              color: context.colors.divider,
            ),
            //ANCHOR - Receive Amount
            _AssetAmountInfo(
              title: context.loc.internalSendReviewReceiveAmountTitle,
              asset: arguments.receiveAsset,
              amount: receiveAmount,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetAmountInfo extends StatelessWidget {
  const _AssetAmountInfo({
    required this.asset,
    required this.title,
    required this.amount,
  });

  final Asset asset;
  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        //ANCHOR - Logo
        InternalSendAssetIcon(
          asset: asset,
          size: 53.r,
          isLayerTwoIcon: asset.isLBTC,
        ),
        SizedBox(width: 20.w),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),
            //ANCHOR - Amount Title
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //ANCHOR - Amount
                Text(
                  amount,
                  style: context.textTheme.headlineSmall,
                ),
                SizedBox(width: 6.w),
                //ANCHOR - Symbol
                Text(
                  asset.ticker,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: AquaColors.graniteGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
