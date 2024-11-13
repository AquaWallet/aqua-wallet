import 'package:aqua/config/constants/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QrAssetIcon extends ConsumerWidget {
  const QrAssetIcon(
      {super.key,
      this.size,
      required this.assetLogoUrl,
      required this.assetId});

  final double? size;
  final String assetId;
  final String assetLogoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? localAsset;

    // local hardcoded cases
    switch (assetId) {
      case 'Layer2Bitcoin':
        localAsset = Svgs.layerTwoSingle;
        break;
      case 'btc':
        localAsset = Svgs.qrIconBitcoin;
        break;
      case 'lightning':
        localAsset = Svgs.qrIconLightning;
        break;
      case 'trx-usdt':
        localAsset = Svgs.qrIconTronUsdt;
        break;
      case 'eth-usdt':
        localAsset = Svgs.qrIconEthUsdt;
        break;
      case 'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2':
        // TODO: the asset id should not be hardcoded here
        localAsset = Svgs.qrIconTetherUsdt;
      case '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d':
        // TODO: the asset id should not be hardcoded here
        localAsset = Svgs.qrIconLiquidBitcoin;

      default:
        break;
    }

    // get from either local or network
    if (localAsset != null) {
      return SvgPicture.asset(
        localAsset,
        fit: BoxFit.fitWidth,
        width: size ?? 40.r,
        height: size ?? 40.r,
      );
    } else {
      return SvgPicture.network(
        assetLogoUrl,
        fit: BoxFit.fitWidth,
        width: size ?? 40.r,
        height: size ?? 40.r,
      );
    }
  }
}
