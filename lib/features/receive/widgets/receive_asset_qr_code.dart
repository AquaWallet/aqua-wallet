import 'package:aqua/features/shared/shared.dart';
import 'package:qr_flutter/qr_flutter.dart';

const kPlaceholderQrUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

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
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SizedBox.square(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: isPlaceholder ? 0.3 : 1,
              child: QrImageView(
                data: isPlaceholder ? kPlaceholderQrUrl : assetAddress,
                version: QrVersions.auto,
                embeddedImage: null,
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size(45.r, 45.r),
                ),
              ),
            ),
            if (isPlaceholder) ...{
              const CircularProgressIndicator()
            } else ...{
              QrAssetIcon(
                assetId: assetId,
                assetLogoUrl: assetIconUrl,
                size: 60.r,
              ),
            },
          ],
        ),
      ),
    );
  }
}
