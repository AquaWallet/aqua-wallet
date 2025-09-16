import 'package:coin_cz/features/shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AssetSelectorFieldCutOutShape extends ShapeBorder {
  final double radius;
  final Color borderColor;

  const AssetSelectorFieldCutOutShape({
    required this.borderColor,
    required this.radius,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final subRect = Rect.fromLTRB(rect.left, rect.top, rect.right, 20.0);
    return Path.combine(
      PathOperation.difference,
      Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
        ..close(),
      Path()
        ..addRRect(
            RRect.fromRectAndRadius(subRect, const Radius.circular(24.0)))
        ..close(),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Path outerPath = getOuterPath(rect, textDirection: textDirection);

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(outerPath, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return AssetSelectorFieldCutOutShape(
      borderColor: borderColor,
      radius: radius * t,
    );
  }
}
