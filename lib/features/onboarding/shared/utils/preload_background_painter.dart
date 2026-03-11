import 'dart:async';
import 'dart:ui' as ui;

import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart' as ui_lib;

class PreloadBackgroundPainter extends CustomPainter {
  PreloadBackgroundPainter({
    required this.isBotevMode,
    this.splashImage,
  });

  final bool isBotevMode;
  final ui.Image? splashImage;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;

    if (isBotevMode) {
      paint.color = Colors.black;
      canvas.drawRect(rect, paint);
    } else {
      // Paint the splash background color
      paint.color = ui_lib.AquaPrimitiveColors.aquaBlue300;
      // paint.color = ui_lib.AquaPrimitiveColors.vermillion;
      canvas.drawRect(rect, paint);

      // Draw splash image if loaded
      if (splashImage != null) {
        final availableWidth = size.width;
        final availableHeight = size.height;

        // Calculate scale to fit within available space while maintaining aspect ratio
        final imageAspectRatio = splashImage!.width / splashImage!.height;
        final availableAspectRatio = availableWidth / availableHeight;

        double drawWidth;
        double drawHeight;

        if (imageAspectRatio > availableAspectRatio) {
          // Image is wider, fit to width
          drawWidth = availableWidth;
          drawHeight = availableWidth / imageAspectRatio;
        } else {
          // Image is taller, fit to height
          drawHeight = availableHeight;
          drawWidth = availableHeight * imageAspectRatio;
        }

        // Center the image
        final left = (size.width - drawWidth) / 2;
        final top = (size.height - drawHeight) / 2;

        final srcRect = Rect.fromLTWH(
          0,
          0,
          splashImage!.width.toDouble(),
          splashImage!.height.toDouble(),
        );
        final dstRect = Rect.fromLTWH(left, top, drawWidth, drawHeight);

        canvas.drawImageRect(splashImage!, srcRect, dstRect, Paint());
      }
    }
  }

  @override
  bool shouldRepaint(PreloadBackgroundPainter oldDelegate) {
    return oldDelegate.splashImage != splashImage ||
        oldDelegate.isBotevMode != isBotevMode;
  }

  static Future<ui.Image> loadSplashImage() async {
    final data = await rootBundle.load(UiAssets.icon.splash.path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Precache the splash image to prevent flicker on first frame
  /// This ensures the image is render-ready in Flutter's pipeline
  static Future<void> precacheSplashImage() async {
    final imageProvider = UiAssets.icon.splash.provider();
    final imageStream = imageProvider.resolve(const ImageConfiguration());
    final completer = Completer<void>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        imageStream.removeListener(listener);
        completer.complete();
      },
      onError: (exception, stackTrace) {
        imageStream.removeListener(listener);
        completer.completeError(exception, stackTrace);
      },
    );
    imageStream.addListener(listener);
    await completer.future;
  }

  static Future<void> precacheAquaLogo() async {
    final asset = AquaUiAssets.svgs.aquaLogo;
    // Load the SVG bytes and cache using the same loader path as the widget
    final byteData = await rootBundle.load(asset.path);
    final bytes = byteData.buffer.asUint8List();
    final loader = svg.SvgBytesLoader(bytes);
    // Preload into flutter_svg cache
    await svg.vg.loadPicture(loader, null);
  }
}
