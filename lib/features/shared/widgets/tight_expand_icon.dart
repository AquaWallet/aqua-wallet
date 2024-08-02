import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// The default [ExpandIcon] from material package has a lot of padding around
/// it with no way to configure it. This is a 1:1 copy of it with the excess
/// paddings removed and added nicety of Hooks.

class TightExpandIcon extends HookWidget {
  const TightExpandIcon({
    super.key,
    this.isExpanded = false,
    this.size = 24.0,
    required this.onPressed,
    this.padding = const EdgeInsets.all(8.0),
    this.color,
    this.disabledColor,
    this.expandedColor,
  });

  final bool isExpanded;
  final double size;
  final ValueChanged<bool>? onPressed;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? disabledColor;
  final Color? expandedColor;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: kThemeAnimationDuration,
      initialValue: isExpanded ? math.pi : 0,
    );
    final iconTurnsAnimation = useMemoized(() {
      final tween = Tween<double>(begin: 0.0, end: 0.5)
          .chain(CurveTween(curve: Curves.fastOutSlowIn));
      return controller.drive(tween);
    });

    final handlePressed = useCallback(() {
      onPressed?.call(isExpanded);
    });

    useEffect(() {
      if (isExpanded) {
        controller.forward();
      } else {
        controller.reverse();
      }
      return null;
    }, [isExpanded]);

    return IconButton(
      padding: padding,
      iconSize: size,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tight(Size.square(size)),
      disabledColor: disabledColor,
      onPressed: onPressed == null ? null : handlePressed,
      icon: RotationTransition(
        turns: iconTurnsAnimation,
        child: const Icon(Icons.expand_more),
      ),
    );
  }
}
