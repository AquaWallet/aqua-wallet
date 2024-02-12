import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aqua/features/settings/manage_assets/models/assets.dart';

class ReceiveAssetAddressLabel extends HookWidget {
  const ReceiveAssetAddressLabel({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    var assetName = asset.name;
    if (asset.isEth) {
      assetName = "Ethereum USDt";
    } else if (asset.isTrx) {
      assetName = "Tron USDt";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: assetName, style: Theme.of(context).richTextStyleBold),
          TextSpan(
            text: " address",
            style: Theme.of(context).richTextStyleNormal,
          )
        ]),
        textAlign: TextAlign.center,
      ),
    );
  }
}
