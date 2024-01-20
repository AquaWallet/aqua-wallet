import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class BoxShadowContainer extends Container {
  BoxShadowContainer({
    super.key,
    Widget? child,
    this.width,
    this.height,
    this.borderRadius,
    this.elevation = 0,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Clip clipBehavior = Clip.none,
    this.error = false,
    this.bordered = false,
    this.borderColor,
  }) : super(
          alignment: alignment,
          padding: padding,
          color: color,
          decoration: decoration,
          foregroundDecoration: foregroundDecoration,
          width: width,
          height: height,
          constraints: constraints,
          margin: margin,
          transform: transform,
          transformAlignment: transformAlignment,
          clipBehavior: clipBehavior,
          child: child,
        );

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int elevation;
  final bool error;
  final bool bordered;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: super.padding,
      margin: super.margin,
      decoration: decoration ??
          BoxDecoration(
            color: color ?? Theme.of(context).colorScheme.surface,
            border: bordered
                ? Border.all(
                    color: borderColor ??
                        Theme.of(context).colorScheme.onBackground,
                    width: 2.r,
                  )
                : null,
            borderRadius: borderRadius ?? BorderRadius.circular(12.r),
            boxShadow: [Theme.of(context).shadow],
          ),
      child: super.child,
    );
  }
}
