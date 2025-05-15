import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaQuickActionItem extends StatelessWidget {
  const AquaQuickActionItem({
    super.key,
    required this.label,
    this.icon,
    this.padding,
    this.foregroundColor,
    this.onTap,
  });

  const AquaQuickActionItem.icon({
    super.key,
    required this.icon,
    required this.label,
    this.padding,
    this.foregroundColor,
    this.onTap,
  });

  final Widget? icon;
  final String label;
  final EdgeInsets? padding;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Ink(
          padding: padding ?? const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                SizedBox.square(
                  dimension: 18,
                  child: icon!,
                ),
                const SizedBox(width: 4),
              ],
              AquaText.body2SemiBold(
                text: label,
                color: foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
