import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PegReviewInfoCard extends HookConsumerWidget {
  const PegReviewInfoCard({
    super.key,
    required this.data,
    required this.input,
  });

  final SwapPegReviewModel data;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = useMemoized(() => input.deliverAsset!);
    final receiveAmountDisplay = useMemoized(() {
      return ref.read(formatterProvider).formatAssetAmountDirect(
            amount: data.receiveAmount,
            precision: asset.precision,
          );
    });
    final cryptoAmountInSats = useMemoized(() {
      return ref.read(formatterProvider).parseAssetAmountDirect(
            amount: input.deliverAmount,
            precision: asset.precision,
          );
    }, [input.deliverAmount]);

    return BoxShadowCard(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      color: Theme.of(context).colors.altScreenSurface,
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
                      amount: cryptoAmountInSats.toString(),
                      asset: asset,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36.0),
            //ANCHOR - Receive amount
            LabelCopyableTextView(
              label: context.loc.youWillReceive,
              value: "$receiveAmountDisplay ${input.receiveAsset!.ticker}",
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
              value: data.order.orderId,
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
