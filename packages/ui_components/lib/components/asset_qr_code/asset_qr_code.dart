import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_components/ui_components.dart';

const kPlaceholderQrUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
const kIconPadding = 8;
const kQrCardSize = 220.0;

class AquaAssetQRCode extends StatelessWidget {
  const AquaAssetQRCode({
    super.key,
    required this.content,
    this.assetId,
    this.size = kQrCardSize,
    this.iconSize = 48,
    this.iconUrl,
  });

  final String content;
  final String? assetId;
  final double size;
  final double iconSize;
  final String? iconUrl;

  static final qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = content.isEmpty;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: isPlaceholder ? 0.3 : 1,
            child: RepaintBoundary(
              key: qrKey,
              child: QrImageView(
                data: isPlaceholder ? kPlaceholderQrUrl : content,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel
                    .M, // Medium error correction for better scanning
                backgroundColor: Colors.white,
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AquaColors.lightColors.textPrimary,
                ),
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AquaColors.lightColors.textPrimary,
                ),
                embeddedImage: null,
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size.square(iconSize + (kIconPadding * 2)),
                ),
              ),
            ),
          ),
          if (isPlaceholder) ...{
            const CircularProgressIndicator()
          } else if (assetId != null) ...{
            Stack(
              alignment: Alignment.center,
              children: [
                if (iconUrl != null) ...{
                  // Outline (slightly larger white icon)
                  AquaAssetIcon.fromUrl(
                    url: iconUrl!,
                    size: iconSize + kIconPadding,
                    color: AquaColors.lightColors.textInverse,
                  ),
                  // Main icon
                  AquaAssetIcon.fromUrl(
                    url: iconUrl!,
                    size: iconSize,
                  ),
                } else ...{
                  // Outline (slightly larger white icon)
                  AquaAssetIcon.fromAssetId(
                    assetId: assetId!,
                    size: iconSize + kIconPadding,
                    color: AquaColors.lightColors.textInverse,
                  ),
                  // Main icon
                  AquaAssetIcon.fromAssetId(
                    assetId: assetId!,
                    size: iconSize,
                  ),
                }
              ],
            ),
          },
        ],
      ),
    );
  }
}
