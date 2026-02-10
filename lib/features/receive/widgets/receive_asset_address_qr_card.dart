import 'dart:io';
import 'dart:ui' as ui;

import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_components/ui_components.dart';

class CopyButton extends StatelessWidget {
  const CopyButton({super.key, required this.onPressed, required this.label});

  final void Function() onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          side: BorderSide(
            color: context.colors.swapButtonForeground,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Let the Row take up only the space needed
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
                color: context.colors.swapButtonForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

shareWidgetAsImage(GlobalKey widgetKey) async {
  RenderRepaintBoundary boundary =
      widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

  final image = await boundary.toImage(pixelRatio: 3.0);

  // Create a new image with white background
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(image.width.toDouble(), image.height.toDouble());

  // Fill with white background
  final paint = Paint()..color = const Color(0xFFFFFFFF);
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

  // Draw the captured image on top
  canvas.drawImage(image, Offset.zero, Paint());

  // Convert to image
  final picture = recorder.endRecording();
  final finalImage =
      await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Save to temporary file
  final tempDir = await getTemporaryDirectory();
  final file = await File('${tempDir.path}/share_widget_img.png').create();
  await file.writeAsBytes(bytes);

  // Share the file
  await Share.shareXFiles([XFile(file.path)]);
}

class ReceiveAssetAddressQrCard extends HookWidget {
  const ReceiveAssetAddressQrCard({
    super.key,
    this.isDirectPegIn = false,
    this.swapOrder,
    this.swapPair,
    required this.asset,
    required this.address,
  });

  final Asset asset;
  final String address;
  final bool isDirectPegIn;
  final SwapOrder? swapOrder;
  final SwapPair? swapPair;

  @override
  Widget build(BuildContext context) {
    return AquaCard.glass(
      width: double.maxFinite,
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.copyToClipboard(address),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (swapPair != null && asset.isAnyUsdt) ...[
            const SizedBox(height: 24),
            //ANCHOR - Warning Chip
            AltUsdtNetworkWarningChip(asset: asset),
            const SizedBox(height: 14),
            //ANCHOR - Single Use Address with expiry
            if (swapOrder != null) ...[
              const SingleUseReceiveAddressLabel(),
              //ANCHOR - Expiry date (only if expiresAt is set)
              if (swapOrder!.expiresAt != null) ...[
                const SizedBox(height: 4),
                AquaText.caption1Medium(
                  text: context.loc.exp(swapOrder!.expiresAt!.yMMMd()),
                  textAlign: TextAlign.center,
                  color: context.aquaColors.textSecondary,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ] else ...[
            const SizedBox(height: 24),
          ],
          //ANCHOR - QR Code
          ReceiveAssetQrCode(
            assetAddress: address,
            asset: asset,
          ),
          const SizedBox(height: 16),
          //ANCHOR - Address field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 38),
            child: AquaColoredText(
              text: address,
              colorType: ColoredTextEnum.coloredIntegers,
              textAlign: TextAlign.center,
              style: AquaAddressTypography.body2.copyWith(
                color: context.colors.onBackground,
              ),
              shouldWrap: asset.isLightning,
            ),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }
}
