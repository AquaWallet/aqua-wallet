import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_components/ui_components.dart';

Future<void> shareReceiveQrImage({
  required String data,
  required Asset asset,
  Rect? sharePositionOrigin,
}) async {
  if (data.isEmpty) return;

  final iconUrl = asset.toUiModel().isRemoteIcon ? asset.logoUrl : null;
  final bytes = await AquaAssetQrEncoder.encodePng(
    content: data,
    assetId: asset.id,
    iconUrl: iconUrl,
    size: kAquaAssetQrShareSize,
    iconSize: kAquaAssetQrShareIconSize,
  );

  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: 'image/png', name: 'qr_code.png')],
    sharePositionOrigin: sharePositionOrigin,
  );
}
