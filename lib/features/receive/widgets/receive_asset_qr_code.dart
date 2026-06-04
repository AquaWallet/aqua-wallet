import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveAssetQrCode extends StatelessWidget {
  const ReceiveAssetQrCode({
    super.key,
    required this.assetAddress,
    required this.asset,
  });

  final String assetAddress;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final iconUrl = asset.toUiModel().isRemoteIcon ? asset.logoUrl : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AquaAssetQRCode(
        content: assetAddress,
        assetId: asset.id,
        iconUrl: iconUrl,
        size: kAquaAssetQrShareSize,
        iconSize: kAquaAssetQrShareIconSize,
      ),
    );
  }
}
