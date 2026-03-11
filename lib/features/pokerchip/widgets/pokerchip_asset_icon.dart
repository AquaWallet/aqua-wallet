import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_components/ui_components.dart';

class PokerchipAssetIcon extends StatelessWidget {
  const PokerchipAssetIcon(this.asset, {super.key});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 160.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          //ANCHOR: Pokerchip frame
          SvgPicture.asset(
            Svgs.pokerchipFrameLight,
            width: 160.0,
            height: 160.0,
            colorFilter: ColorFilter.mode(
                Theme.of(context).colors.onBackground, BlendMode.srcIn),
          ),
          //ANCHOR: Asset Icon
          AquaAssetIcon.fromAssetId(
            assetId: asset.id,
            size: 48,
          )
        ],
      ),
    );
  }
}
