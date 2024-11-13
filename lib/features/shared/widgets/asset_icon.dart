import 'package:aqua/config/constants/constants.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AssetIcon extends ConsumerWidget {
  const AssetIcon({
    super.key,
    this.size,
    this.fit,
    required this.assetLogoUrl,
    required this.assetId,
  });

  final double? size;
  final String assetId;
  final String assetLogoUrl;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? localAsset;
    final liquidProviderRef = ref.read(liquidProvider);

    // local hardcoded cases
    switch (assetId) {
      case 'Layer2Bitcoin':
        localAsset = Svgs.layerTwoSingle;
        break;
      case 'btc':
        localAsset = Svgs.btcAsset;
        break;
      case 'lightning':
        localAsset = Svgs.lightningAsset;
        break;
      case 'trx-usdt':
        localAsset = Svgs.tronUsdtAsset;
        break;
      case 'eth-usdt':
        localAsset = Svgs.ethUsdtAsset;
        break;
      default:
        // liquid assetIds
        if (assetId == liquidProviderRef.usdtId) {
          localAsset = Svgs.usdtAsset;
        } else if (assetId == liquidProviderRef.lbtcId) {
          localAsset = Svgs.liquidAsset;
        } else if (assetId == liquidProviderRef.mexasId) {
          localAsset = Svgs.mexasAsset;
        } else if (assetId == liquidProviderRef.depixId) {
          localAsset = Svgs.depixAsset;
        }
        break;
    }

    // get from either local or network
    if (localAsset != null) {
      return SvgPicture.asset(
        localAsset,
        fit: fit ?? BoxFit.fitWidth,
        width: size ?? 40.r,
        height: size ?? 40.r,
      );
    } else {
      return SvgPicture.network(
        assetLogoUrl,
        fit: fit ?? BoxFit.fitWidth,
        width: size ?? 40.r,
        height: size ?? 40.r,
      );
    }
  }
}
