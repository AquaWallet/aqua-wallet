import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class InternalSendAssetIcon extends StatelessWidget {
  const InternalSendAssetIcon({
    super.key,
    required this.asset,
    this.size,
    required this.isLayerTwoIcon,
  });

  final Asset asset;
  final double? size;
  final bool isLayerTwoIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size ?? 52.0,
      child: isLayerTwoIcon
          ? SvgPicture.asset(
              Svgs.layerTwoSingle,
              width: size,
              height: size,
            )
          : AssetIcon(
              assetId: asset.id,
              assetLogoUrl: asset.logoUrl,
              fit: BoxFit.contain,
              size: size,
            ),
    );
  }
}
