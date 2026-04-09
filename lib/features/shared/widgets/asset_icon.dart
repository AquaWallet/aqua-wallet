import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

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
      case kLayer2BitcoinId:
        localAsset = UiAssets.assetIcons.layerTwoSingle.path;
        break;
      case 'btc':
        localAsset = UiAssets.assetIcons.btc.path;
        break;
      case 'lightning':
        localAsset = UiAssets.assetIcons.l2.path;
        break;
      case 'LiquidBitcoin':
        localAsset = UiAssets.assetIcons.liquid.path;
      case 'trx-usdt':
        localAsset = UiAssets.assetIcons.tronusdt.path;
        break;
      case 'eth-usdt':
        localAsset = UiAssets.assetIcons.ethusdt.path;
        break;
      case 'bep-usdt':
        localAsset = UiAssets.assetIcons.bepusdt.path;
        break;
      case 'sol-usdt':
        localAsset = UiAssets.assetIcons.solusdt.path;
        break;
      case 'pol-usdt':
        localAsset = UiAssets.assetIcons.polusdt.path;
        break;
      case 'ton-usdt':
        localAsset = UiAssets.assetIcons.tonusdt.path;
        break;
      default:
        // liquid assetIds
        if (assetId == liquidProviderRef.usdtId) {
          localAsset = UiAssets.assetIcons.usdt.path;
        } else if (assetId == liquidProviderRef.lbtcId) {
          localAsset = UiAssets.assetIcons.liquid.path;
        } else if (assetId == liquidProviderRef.mexasId) {
          localAsset = UiAssets.assetIcons.mex.path;
        } else if (assetId == liquidProviderRef.depixId) {
          localAsset = UiAssets.assetIcons.dePix.path;
        }
        break;
    }

    // get from either local or network
    if (localAsset != null) {
      return SvgPicture.asset(
        localAsset,
        fit: fit ?? BoxFit.fitWidth,
        width: size ?? 40.0,
        height: size ?? 40.0,
      );
    } else {
      return VectorGraphic(
        loader: SvgNetworkLoader(assetLogoUrl),
        fit: fit ?? BoxFit.fitWidth,
        width: size ?? 40.0,
        height: size ?? 40.0,
        placeholderBuilder: (_) => const SizedBox.shrink(),
        errorBuilder: (_, __, ___) => SvgPicture.asset(
          UiAssets.assetIcons.assetUnknown.path,
          fit: fit ?? BoxFit.fitWidth,
          width: size ?? 40.0,
          height: size ?? 40.0,
        ),
      );
    }
  }
}
