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
      dimension: 267.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          //ANCHOR: Pokerchip frame
          SvgPicture.asset(
            Svgs.pokerchipFrameLight,
            width: 267.r,
            height: 267.r,
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onBackground, BlendMode.srcIn),
          ),
          //ANCHOR: Asset Icon
          if (asset.isBTC || asset.isUnknown) ...{
            SvgPicture.asset(
              asset.logoUrl,
              width: 100.r,
              height: 100.r,
            ),
          } else ...{
            SvgPicture.network(
              asset.logoUrl,
              width: 100.r,
              height: 100.r,
            ),
          },
        ],
      ),
    );
  }
}
