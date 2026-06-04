import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_components/components/icon/icon.dart';
import 'package:ui_components/config/config.dart';

import 'asset_qr_code.dart';

const kAquaAssetQrShareSize = 244.0;
const kAquaAssetQrShareIconSize = 50.0;

class AquaAssetQrEncoder {
  AquaAssetQrEncoder._();

  static Future<Uint8List> encodePng({
    required String content,
    String? assetId,
    String? iconUrl,
    double size = kAquaAssetQrShareSize,
    double iconSize = kAquaAssetQrShareIconSize,
  }) async {
    final moduleColor = AquaColors.lightColors.textPrimary;
    final painter = QrPainter(
      data: content,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: moduleColor,
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: moduleColor,
      ),
    );

    final qrByteData = await painter.toImageData(
      size,
      format: ui.ImageByteFormat.png,
    );
    if (qrByteData == null) {
      throw StateError('Failed to encode QR image');
    }

    if (assetId == null && (iconUrl == null || iconUrl.isEmpty)) {
      return qrByteData.buffer.asUint8List();
    }

    final codec = await ui.instantiateImageCodec(qrByteData.buffer.asUint8List());
    final qrFrame = await codec.getNextFrame();
    final iconImage = await _renderCenterIcon(
      assetId: assetId,
      iconUrl: iconUrl,
      iconSize: iconSize,
    );
    if (iconImage == null) {
      return qrByteData.buffer.asUint8List();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Rect.fromLTWH(0, 0, size, size);
    canvas.drawRect(bounds, Paint()..color = Colors.white);
    canvas.drawImage(qrFrame.image, Offset.zero, Paint());

    final iconDimension = iconSize + (kIconPadding * 2);
    final iconOffset = Offset(
      (size - iconDimension) / 2,
      (size - iconDimension) / 2,
    );
    canvas.drawImageRect(
      iconImage,
      Rect.fromLTWH(
        0,
        0,
        iconImage.width.toDouble(),
        iconImage.height.toDouble(),
      ),
      Rect.fromLTWH(
        iconOffset.dx,
        iconOffset.dy,
        iconDimension,
        iconDimension,
      ),
      Paint(),
    );

    final picture = recorder.endRecording();
    final composite = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await composite.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  static Future<ui.Image?> _renderCenterIcon({
    required String? assetId,
    required String? iconUrl,
    required double iconSize,
  }) async {
    final dimension = iconSize + (kIconPadding * 2);
    final widget = SizedBox(
      width: dimension,
      height: dimension,
      child: AquaAssetIconEncoding.overlay(
        assetId: assetId,
        iconUrl: iconUrl,
        iconSize: iconSize,
      ),
    );

    return _widgetToImage(widget, Size.square(dimension));
  }

  static Future<ui.Image?> _widgetToImage(Widget widget, Size size) async {
    try {
      final repaintBoundary = RenderRepaintBoundary();
      final view = ui.PlatformDispatcher.instance.views.first;
      const pixelRatio = 3.0;

      final renderView = RenderView(
        view: view,
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          physicalConstraints: BoxConstraints.tight(size * pixelRatio),
          logicalConstraints: BoxConstraints.tight(size),
          devicePixelRatio: pixelRatio,
        ),
      );

      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(focusManager: FocusManager());
      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: DefaultAssetBundle(
          bundle: rootBundle,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(size: size),
              child: widget,
            ),
          ),
        ),
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      final binding = WidgetsBinding.instance;
      for (var i = 0; i < 4; i++) {
        binding.scheduleFrame();
        await binding.endOfFrame;
      }

      return repaintBoundary.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      return null;
    }
  }
}
