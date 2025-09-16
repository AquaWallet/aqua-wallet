import 'package:coin_cz/features/receive/keys/receive_screen_keys.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:qr_flutter/qr_flutter.dart';

const kPlaceholderQrUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
const kAssetIconSize =
    50.0; // Reduced icon size for less interference with QR code

class ReceiveAssetQrCode extends StatelessWidget {
  const ReceiveAssetQrCode({
    super.key,
    required this.assetAddress,
    required this.assetId,
    required this.assetIconUrl,
  });

  final String assetAddress;
  final String assetId;
  final String assetIconUrl;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = assetAddress.isEmpty;
    return Container(
      key: ReceiveAssetKeys.receiveAssetQrCodeContainer,
      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: SizedBox.square(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: isPlaceholder ? 0.3 : 1,
              child: QrImageView(
                key: ReceiveAssetKeys.receiveAssetQrCode,
                data: isPlaceholder ? kPlaceholderQrUrl : assetAddress,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel
                    .M, // Medium error correction for better scanning
                embeddedImage: null,
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size.square(kAssetIconSize),
                ),
              ),
            ),
            if (isPlaceholder) ...{
              const CircularProgressIndicator()
            } else ...{
              QrAssetIcon(
                assetId: assetId,
                assetLogoUrl: assetIconUrl,
                size: kAssetIconSize,
              ),
            },
          ],
        ),
      ),
    );
  }
}
