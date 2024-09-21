import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAssetAddressQrCard extends HookWidget {
  const ReceiveAssetAddressQrCard({
    super.key,
    this.isDirectPegIn = false,
    this.sideshiftOrder,
    required this.asset,
    required this.address,
  });

  final Asset asset;
  final String address;
  final bool isDirectPegIn;
  final SideshiftOrder? sideshiftOrder;

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
      elevation: 4.h,
      color: Theme.of(context).colors.addressFieldContainerBackgroundColor,
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      borderRadius: BorderRadius.circular(12.r),
      bordered: true,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR - Description
            SizedBox(height: 20.h),
            ReceiveAssetAddressLabel(
              asset: asset,
              isDirectPegIn: isDirectPegIn,
            ),
            SizedBox(height: 20.h),
            //ANCHOR - QR Code
            ReceiveAssetQrCode(
                assetAddress: address,
                assetId: asset.id,
                assetIconUrl: asset.logoUrl),
            SizedBox(height: 21.h),
            //ANCHOR - Copy Address Button
            CopyAddressButton(
              address: rawAddress,
            ),
            SizedBox(height: 20.h),
            //ANCHOR - Shift min and max
            if (asset.isSideshift) ...[
              //ANCHOR - Expiry
              ReceiveSideshiftOrderExpireLabel(order: sideshiftOrder),
              SizedBox(height: 14.h),
              //ANCHOR - Min-Max Bound
              SideshiftMinMaxPanel(asset: asset),
              SizedBox(height: 20.h),
            ],
          ],
        ),
      ),
    );
  }
}
