import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class PreloadBackgroundPainter extends CustomPainter {
  PreloadBackgroundPainter({required this.isBotevMode});

  final bool isBotevMode;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    var rect = Offset.zero & size;

    if (isBotevMode) {
      paint.color = Colors.black;
    } else {
      paint.shader = AppStyle.backgroundGradient.createShader(rect);
    }

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
