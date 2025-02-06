import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aqua/utils/utils.dart';

class ReceiveAssetAddressQrCard extends HookWidget {
  const ReceiveAssetAddressQrCard({
    super.key,
    this.isDirectPegIn = false,
    this.swapOrder,
    this.swapPair,
    this.onRegenerate,
    required this.asset,
    required this.address,
  });

  final Asset asset;
  final String address;
  final bool isDirectPegIn;
  final SwapOrder? swapOrder;
  final SwapPair? swapPair;
  final Function? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final rawAddress = useMemoized(() {
      // extract the raw address
      if (address.contains("liquidnetwork")) {
        return address
            .split('?')[0]
            .replaceAll("liquidnetwork:", "")
            .replaceAll("/", "");
      }
      if (address.contains("bitcoin")) {
        return address
            .split('?')[0]
            .replaceAll("bitcoin:", "")
            .replaceAll("/", "");
      }
      return address;
    }, [address]);

    return BoxShadowCard(
      elevation: 4.0,
      color: context.colors.addressFieldContainerBackgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 28.0),
      borderRadius: BorderRadius.circular(12.0),
      bordered: true,
      borderColor: context.colors.cardOutlineColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR - Description
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9.0),
              child: Text(
                getAddressTitle(asset, isDirectPegIn, context),
                textAlign: TextAlign.center,
                style: Theme.of(context).richTextStyleBold,
              ),
            ),
            const SizedBox(height: 20.0),
            //ANCHOR - QR Code
            ReceiveAssetQrCode(
                assetAddress: address,
                assetId: asset.id,
                assetIconUrl: asset.logoUrl),
            const SizedBox(height: 21.0),
            //ANCHOR - Copy Address Button
            CopyAddressButton(
              address: rawAddress,
            ),
            const SizedBox(height: 20.0),
            // ANCHOR - Regenerate address
            if (onRegenerate != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 30.0,
                    child: OutlinedButton(
                      onPressed: () => onRegenerate!(),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        side: BorderSide(
                          color: context.colors.swapButtonForeground,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize
                            .min, // Let the Row take up only the space needed
                        children: [
                          SvgPicture.asset(
                            Svgs.refreshIcon,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              context.colors.onBackground,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            context.loc.receiveAssetScreenGenerateNewAddress,
                            style: TextStyle(
                              fontSize: 14.0,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w700,
                              color: context.colors.swapButtonForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0)
            ],
            //ANCHOR - Shift min and max
            if (asset.isAltUsdt && swapPair != null) ...[
              //ANCHOR - Expiry
              ReceiveSwapOrderExpireLabel(order: swapOrder),
              const SizedBox(height: 14.0),
              //ANCHOR - Min-Max Bound
              USDtSwapMinMaxPanel(swapPair: swapPair!),
              const SizedBox(height: 20.0),
            ],
          ],
        ),
      ),
    );
  }
}

String getAddressTitle(Asset asset, bool isDirectPegIn, BuildContext context) {
  if (isDirectPegIn) {
    return AppLocalizations.of(context)!
        .receiveAssetScreenDirectPegInDescription;
  }

  if (asset.isUsdtLiquid) {
    return AppLocalizations.of(context)!
        .receiveAssetScreenDescriptionUsdt(asset.network);
  }

  if (asset.isTrx) {
    return AppLocalizations.of(context)!
        .receiveAssetScreenDescriptionUsdt(AppLocalizations.of(context)!.tron);
  }

  if (asset.isEth) {
    return AppLocalizations.of(context)!
        .receiveAssetScreenDescriptionUsdt(AppLocalizations.of(context)!.eth);
  }

  if (asset.isLightning) {
    return AppLocalizations.of(context)!.lightningInvoice;
  }

  return AppLocalizations.of(context)!
      .receiveAssetScreenDescriptionAll(asset.name);
}
