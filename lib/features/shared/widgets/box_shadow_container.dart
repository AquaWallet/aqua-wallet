import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class BoxShadowContainer extends Container {
  BoxShadowContainer({
    super.key,
    super.child,
    this.width,
    this.height,
    this.borderRadius,
    this.elevation = 0,
    super.alignment,
    super.padding,
    super.color,
    super.decoration,
    super.foregroundDecoration,
    super.constraints,
    super.margin,
    super.transform,
    super.transformAlignment,
    super.clipBehavior,
    this.error = false,
    this.bordered = false,
    this.borderColor,
  }) : super(
          width: width,
          height: height,
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
