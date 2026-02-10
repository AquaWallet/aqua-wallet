import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/config/config.dart';

class AquaToggle extends HookWidget {
  const AquaToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.trackColor,
    this.thumbColor,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? trackColor;
  final Color? thumbColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
      initialValue: value ? 1.0 : 0.0,
    );

    final position = useAnimation(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      ),
    );

    useEffect(() {
      if (value) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [value]);

    final activeColorValue =
        activeColor ?? Theme.of(context).colorScheme.primary;
    final trackColorValue =
        trackColor ?? Theme.of(context).colorScheme.outlineVariant;
    final thumbColorValue = thumbColor ?? Colors.white;

    return GestureDetector(
      onTap: enabled
          ? onChanged == null
              ? null
              : () => onChanged!(!value)
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: 40,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Color.lerp(trackColorValue, activeColorValue, position),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 2.0,
                left: 2.0 + position * 16.0,
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: thumbColorValue,
                    boxShadow: [
                      BoxShadow(
                        color: AquaPrimitiveColors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, position * 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
