import 'package:aqua/features/shared/shared.dart';

class PasscodeInputPaintWidget extends StatelessWidget {
  const PasscodeInputPaintWidget({
    super.key,
    this.size = 16.0,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * (16 / 14)), // Maintain aspect ratio (14:16)
      painter: _PasscodeInputPainter(color: color),
    );
  }
}

class _PasscodeInputPainter extends CustomPainter {
  const _PasscodeInputPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    final scaleX = size.width / 15.0;
    final scaleY = size.height / 16.0;

    path.moveTo(14.5 * scaleX, 8.88889 * scaleY);

    path.cubicTo(
      14.5 * scaleX,
      12.8162 * scaleY,
      11.366 * scaleX,
      16 * scaleY,
      7.5 * scaleX,
      16 * scaleY,
    );

    path.cubicTo(
      3.63401 * scaleX,
      16 * scaleY,
      0.5 * scaleX,
      12.8162 * scaleY,
      0.5 * scaleX,
      8.88889 * scaleY,
    );

    path.cubicTo(
      0.5 * scaleX,
      4.96153 * scaleY,
      7.13401 * scaleX,
      0 * scaleY,
      7.5 * scaleX,
      0 * scaleY,
    );

    path.cubicTo(
      7.86599 * scaleX,
      0 * scaleY,
      14.5 * scaleX,
      4.96153 * scaleY,
      14.5 * scaleX,
      8.88889 * scaleY,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _PasscodeInputPainter && oldDelegate.color != color;
  }
}
