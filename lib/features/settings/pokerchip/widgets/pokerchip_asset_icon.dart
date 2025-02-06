import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class PokerchipAssetIcon extends StatelessWidget {
  const PokerchipAssetIcon(this.asset, {super.key});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 267.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          //ANCHOR: Pokerchip frame
          SvgPicture.asset(
            Svgs.pokerchipFrameLight,
            width: 267.0,
            height: 267.0,
            colorFilter: ColorFilter.mode(
                Theme.of(context).colors.onBackground, BlendMode.srcIn),
          ),
          //ANCHOR: Asset Icon
          if (asset.isBTC || asset.isUnknown) ...{
            SvgPicture.asset(
              asset.logoUrl,
              width: 100.0,
              height: 100.0,
            ),
          } else ...{
            SvgPicture.network(
              asset.logoUrl,
              width: 100.0,
              height: 100.0,
            ),
          },
        ],
      ),
    );
  }
}
