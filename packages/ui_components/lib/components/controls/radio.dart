import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaRadio<T> extends StatelessWidget {
  const AquaRadio({
    super.key,
    required this.value,
    this.onChanged,
    this.groupValue,
    this.enabled = true,
    this.colors,
  }) : size = AquaControlSize.large;

  const AquaRadio.small({
    super.key,
    required this.value,
    this.onChanged,
    this.groupValue,
    this.colors,
    this.enabled = true,
  }) : size = AquaControlSize.small;

  final T value;
  final T? groupValue;
  final AquaControlSize size;
  final ValueChanged<T>? onChanged;
  final AquaColors? colors;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashFactory: InkRipple.splashFactory,
        onTap: enabled && onChanged != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onChanged!(value))
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            width: size == AquaControlSize.large ? 24 : 18,
            height: size == AquaControlSize.large ? 24 : 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (colors?.accentBrand ?? Colors.transparent)
                    : (colors?.surfaceBorderSecondary ?? Colors.transparent),
                width: isSelected
                    ? size == AquaControlSize.large
                        ? 7
                        : 5.25
                    : size == AquaControlSize.large
                        ? 2
                        : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
