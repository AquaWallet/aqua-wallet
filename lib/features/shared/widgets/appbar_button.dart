import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

class AppbarButton extends HookWidget {
  const AppbarButton({
    super.key,
    required this.svgAssetName,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.outlineColor,
    this.elevated = false,
  });

  final String svgAssetName;
  final VoidCallback onPressed;
  final Color foreground;
  final Color background;
  final Color outlineColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final content = useMemoized(() {
      return SvgPicture.asset(
        svgAssetName,
        width: 40.w,
        height: 40.w,
        fit: BoxFit.scaleDown,
        colorFilter: ColorFilter.mode(
          foreground,
          BlendMode.srcIn,
        ),
      );
    }, [svgAssetName]);

    return SizedBox.square(
      dimension: 40.w,
      child: elevated
          ? BoxShadowElevatedButton(
              onPressed: onPressed,
              child: content,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: BorderSide(
                    color: outlineColor,
                    width: 2.w,
                  ),
                ),
                backgroundColor: background,
                foregroundColor: foreground,
                textStyle: Theme.of(context).textTheme.titleSmall,
              ),
              child: content,
            ),
    );
  }
}
