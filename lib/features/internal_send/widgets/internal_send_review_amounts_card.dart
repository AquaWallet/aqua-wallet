import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
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
      borderRadius: BorderRadius.circular(12.0),
      bordered: !darkMode,
      borderColor: context.colors.cardOutlineColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
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
              height: 24.0,
              thickness: 1.0,
              color: context.colors.divider,
            ),
            //ANCHOR - Receive Amount
            _AssetAmountInfo(
              title: context.loc.youWillReceive,
              asset: arguments.receiveAsset,
              amount: receiveAmount,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetAmountInfo extends HookConsumerWidget {
  const _AssetAmountInfo({
    required this.asset,
    required this.title,
    required this.amount,
  });

  final Asset asset;
  final String title;
  final String amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cryptoAmountInSats = useMemoized(() {
      return ref.read(formatterProvider).parseAssetAmountDirect(
            amount: amount,
            precision: asset.precision,
          );
    }, [amount]);
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getForcedDisplayUnit(asset)));
    return Row(
      children: [
        //ANCHOR - Logo
        InternalSendAssetIcon(
          asset: asset,
          size: 53.0,
          isLayerTwoIcon: asset.isLBTC,
        ),
        const SizedBox(width: 20.0),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2.0),
            //ANCHOR - Amount Title
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8.0),
            AssetCryptoAmount(
              forceVisible: true,
              amount: cryptoAmountInSats.toString(),
              asset: asset,
              style: context.textTheme.headlineSmall,
              forceDisplayUnit: displayUnit,
            ),
          ],
        ),
      ],
    );
  }
}
