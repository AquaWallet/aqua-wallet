import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareWidgetAsImage(GlobalKey widgetKey) async {
  final ctx = widgetKey.currentContext;
  if (ctx == null) return;
  final boundary = ctx.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3.0);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(image.width.toDouble(), image.height.toDouble());
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, size.height),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.drawImage(image, Offset.zero, Paint());

  final picture = recorder.endRecording();
  final finalImage =
      await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final origin = boundary.localToGlobal(Offset.zero) & boundary.size;
  await Share.shareXFiles(
    [XFile.fromData(bytes, mimeType: 'image/png', name: 'qr_code.png')],
    sharePositionOrigin: origin,
  );
}
