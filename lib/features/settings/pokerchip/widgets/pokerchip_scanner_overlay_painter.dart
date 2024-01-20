import 'package:aqua/features/shared/shared.dart';

class PokerchipScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;

  PokerchipScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sh = size.height;
    final sw = size.width;
    final cornerSide = borderRadius + 40;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.r
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(cornerSide, 0)
      ..quadraticBezierTo(0, 0, 0, cornerSide)
      ..moveTo(0, sh - cornerSide)
      ..quadraticBezierTo(0, sh, cornerSide, sh)
      ..moveTo(sw - cornerSide, sh)
      ..quadraticBezierTo(sw, sh, sw, sh - cornerSide)
      ..moveTo(sw, cornerSide)
      ..quadraticBezierTo(sw, 0, sw - cornerSide, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
