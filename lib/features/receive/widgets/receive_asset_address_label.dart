import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/models/send_asset_extensions.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAssetAddressLabel extends HookWidget {
  const ReceiveAssetAddressLabel({
    super.key,
    this.isDirectPegIn = false,
    required this.asset,
  });

  final Asset asset;
  final bool isDirectPegIn;

  @override
  Widget build(BuildContext context) {
    String getAddressTitle(Asset asset) {
      if (isDirectPegIn) {
        return AppLocalizations.of(context)!
            .receiveAssetScreenDirectPegInDescription;
      }

      if (asset.isUsdtLiquid) {
        return AppLocalizations.of(context)!
            .receiveAssetScreenDescriptionUsdt(asset.network);
      }

      if (asset.isTrx) {
        return AppLocalizations.of(context)!.receiveAssetScreenDescriptionUsdt(
            AppLocalizations.of(context)!.tron);
      }

      if (asset.isEth) {
        return AppLocalizations.of(context)!.receiveAssetScreenDescriptionUsdt(
            AppLocalizations.of(context)!.eth);
      }

      if (asset.isLightning) {
        return AppLocalizations.of(context)!.receiveAssetScreenDescriptionLn;
      }

      return AppLocalizations.of(context)!
          .receiveAssetScreenDescriptionAll(asset.name);
    }

    final addressTitle = getAddressTitle(asset);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      child: Text(
        addressTitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).richTextStyleBold,
      ),
    );
  }
}
