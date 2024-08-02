import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class DashedDivider extends StatelessWidget {
  const DashedDivider({
    super.key,
    this.height = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.thickness = 1,
    this.color,
  });

  final double height;
  final double dashWidth;
  final Color? color;
  final double dashSpace;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: height,
      child: CustomPaint(
        painter: DashedLineHorizontalPainter(
          color: color ?? Theme.of(context).colors.dottedDivider,
          height: height,
          thickness: thickness,
          dashWidth: dashWidth,
          dashSpace: dashSpace,
        ),
      ),
    );
  }
}

class DashedLineHorizontalPainter extends CustomPainter {
  DashedLineHorizontalPainter({
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.thickness = 1,
    this.height = 2,
    this.color = Colors.black,
  });

  final double dashWidth;
  final double dashSpace;
  final double thickness;
  final double height;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    double startY = height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + dashWidth, startY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
