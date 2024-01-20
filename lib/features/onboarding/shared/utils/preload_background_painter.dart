import 'package:aqua/config/config.dart';
import 'package:flutter/material.dart';

class PreloadBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    var rect = Offset.zero & size;

    paint.shader = AppStyle.backgroundGradient.createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
