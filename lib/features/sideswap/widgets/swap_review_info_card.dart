import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/provider/formatter_provider.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapReviewInfoCard extends HookConsumerWidget {
  const SwapReviewInfoCard({
    super.key,
    required this.order,
    required this.input,
  });

  final SwapStartWebResult order;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, ref) {
    final asset = useMemoized(() => input.deliverAsset!);
    final receiveAmount = useMemoized(() {
      final asset = input.receiveAsset;
      final receiveAmount = order.recvAmount;
      if (asset != null) {
        final amount = ref.read(formatterProvider).formatAssetAmountDirect(
              amount: receiveAmount,
              precision: asset.precision,
            );
        return "$amount ${input.receiveAsset!.ticker}";
      }
      return '-';
    });
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getForcedDisplayUnit(asset)));
    final cryptoAmountInSats = useMemoized(() {
      return ref.read(formatterProvider).parseAssetAmountDirect(
            amount: input.deliverAmount,
            precision: asset.precision,
          );
    }, [input.deliverAmount]);

    return BoxShadowCard(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      color: Theme.of(context).colors.addressFieldContainerBackgroundColor,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                //ANCHOR - Logo
                AssetIcon(
                  assetId: asset.isLBTC ? kLayer2BitcoinId : asset.id,
                  assetLogoUrl: asset.logoUrl,
                  size: 51.0,
                ),
                const SizedBox(width: 19.0),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2.0),
                    //ANCHOR - Amount Title
                    Text(
                      context.loc.pegOrderReviewTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    //ANCHOR - Amount
                    AssetCryptoAmount(
                      forceVisible: true,
                      asset: asset,
                      amount: cryptoAmountInSats.toString(),
                      style: Theme.of(context).textTheme.headlineSmall,
                      forceDisplayUnit: displayUnit,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36.0),
            //ANCHOR - Receive Amount
            LabelCopyableTextView(
              label: context.loc.youWillReceive,
              value: receiveAmount,
            ),
            //ANCHOR - Divider
            DashedDivider(
              height: 32.0,
              thickness: 2.0,
              color: Theme.of(context).colors.divider,
            ),
            //ANCHOR - Order ID
            LabelCopyableTextView(
              label: context.loc.orderId,
              value: order.orderId,
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
