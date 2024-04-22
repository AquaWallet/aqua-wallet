import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class RoundedIconButton extends StatelessWidget {
  const RoundedIconButton({
    super.key,
    this.onPressed,
    required this.svgAssetName,
    this.size,
    this.iconSize,
    this.radius,
    this.elevation,
    this.background,
    this.foreground,
  });

  final VoidCallback? onPressed;
  final String svgAssetName;
  final double? size;
  final double? iconSize;
  final double? radius;
  final int? elevation;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size ?? 74.r,
      child: BoxShadowElevatedButton(
        onPressed: onPressed,
        elevation: elevation ?? 4,
        background: background ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(radius ?? 18.r),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.w,
        ),
        child: SvgPicture.asset(
          svgAssetName,
          width: iconSize ?? 16.r,
          height: iconSize ?? 16.r,
          fit: BoxFit.scaleDown,
          colorFilter: foreground != null
              ? ColorFilter.mode(
                  Theme.of(context).colorScheme.onBackground, BlendMode.srcIn)
              : null,
        ),
      ),
    );
  }
}
