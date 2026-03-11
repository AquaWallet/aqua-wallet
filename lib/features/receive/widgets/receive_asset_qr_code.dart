import 'package:aqua/features/receive/keys/receive_screen_keys.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

const kPlaceholderQrUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

// Reduced icon size for less interference with QR code
const kAssetIconSize = 50.0;

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
    final isPlaceholder = assetAddress.isEmpty;
    return ClipRRect(
      key: ReceiveAssetKeys.receiveAssetQrCodeContainer,
      borderRadius: BorderRadius.circular(6),
      child: Opacity(
        opacity: isPlaceholder ? 0.3 : 1,
        child: AquaAssetQRCode(
          key: ReceiveAssetKeys.receiveAssetQrCode,
          assetId: asset.id,
          iconUrl: asset.toUiModel().isRemoteIcon ? asset.logoUrl : null,
          content: isPlaceholder ? kPlaceholderQrUrl : assetAddress,
          size: 244,
          iconSize: kAssetIconSize,
        ),
      ),
    );
  }
}
