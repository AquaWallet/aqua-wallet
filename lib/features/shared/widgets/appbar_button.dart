import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
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
    final buttonSize = context.adaptiveDouble(smallMobile: 36, mobile: 40);
    final content = useMemoized(() {
      return SvgPicture.asset(
        svgAssetName,
        width: buttonSize,
        height: buttonSize,
        fit: BoxFit.scaleDown,
        colorFilter: ColorFilter.mode(
          foreground,
          BlendMode.srcIn,
        ),
      );
    }, [svgAssetName, foreground]);

    return SizedBox.square(
      dimension: buttonSize,
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
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(
                    color: outlineColor,
                    width: 2.0,
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
