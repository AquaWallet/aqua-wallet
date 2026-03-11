import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/format_provider.dart';
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
    final receiveAsset = useMemoized(() => input.receiveAsset!);
    final receiveDisplayUnit = ref.watch(displayUnitsProvider
        .select((p) => p.getForcedDisplayUnit(receiveAsset)));
    final formatter = ref.read(formatProvider);
    final cryptoAmountInSats = useMemoized(() {
      return ref.read(formatterProvider).parseAssetAmountToSats(
            amount: input.deliverAmount,
            precision: asset.precision,
            asset: asset,
          );
    }, [input.deliverAmount, asset]);

    final formattedReceiveNumber = useMemoized(() {
      return formatter.formatAssetAmount(
        amount: data.receiveAmount,
        asset: receiveAsset,
        displayUnitOverride: receiveDisplayUnit,
      );
    }, [data.receiveAmount, receiveAsset, receiveDisplayUnit]);

    final receiveTicker = useMemoized(() {
      return ref.read(displayUnitsProvider).getAssetDisplayUnit(receiveAsset,
          forcedDisplayUnit: receiveDisplayUnit);
    }, [receiveAsset, receiveDisplayUnit]);

    final receiveValueString = useMemoized(() {
      return "$formattedReceiveNumber $receiveTicker";
    }, [formattedReceiveNumber, receiveTicker]);

    return BoxShadowCard(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      color: Theme.of(context).colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.adaptiveDouble(mobile: 20.0, smallMobile: 10.0),
          vertical: context.adaptiveDouble(mobile: 20.0, smallMobile: 10.0),
        ),
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
            SizedBox(
              height: context.adaptiveDouble(mobile: 36.0, smallMobile: 10.0),
            ),
            //ANCHOR - Receive amount
            LabelCopyableTextView(
              label: context.loc.youWillReceive,
              value: receiveValueString,
            ),
            //ANCHOR - Divider
            DashedDivider(
              height: context.adaptiveDouble(mobile: 32.0, smallMobile: 10.0),
              thickness: 2.0,
              color: Theme.of(context).colors.divider,
            ),
            //ANCHOR - Order ID
            LabelCopyableTextView(
              label: context.loc.orderId,
              value: data.order.orderId,
            ),
            SizedBox(
              height: context.adaptiveDouble(mobile: 16.0, smallMobile: 10.0),
            ),
          ],
        ),
      ),
    );
  }
}
