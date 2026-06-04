import 'package:aqua/features/shared/shared.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_components/ui_components.dart';

class DepixPixQrView extends StatelessWidget {
  const DepixPixQrView({
    super.key,
    required this.payload,
    required this.repaintKey,
    this.size = 244,
  });

  final String payload;
  final GlobalKey repaintKey;
  final double size;

  static const _badgeSize = 56.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: RepaintBoundary(
        key: repaintKey,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              QrImageView(
                data: payload,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                size: size,
                backgroundColor: Colors.white,
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AquaColors.lightColors.textPrimary,
                ),
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AquaColors.lightColors.textPrimary,
                ),
              ),
              Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(4),
                child: UiAssets.marketplace.dePixTile.svg(
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
