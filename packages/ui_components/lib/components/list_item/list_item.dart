import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaListItem extends StatelessWidget {
  const AquaListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.subtitleTrailing,
    this.iconLeading,
    this.iconTrailing,
    this.titleColor,
    this.subtitleColor,
    this.titleTrailingColor,
    this.subtitleTrailingColor,
    this.backgroundColor,
    this.selected,
    this.onTap,
    this.colors,
  });

  final String title;
  final String? subtitle;
  final String? titleTrailing;
  final String? subtitleTrailing;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? titleTrailingColor;
  final Color? subtitleTrailingColor;
  final Color? backgroundColor;
  final Widget? iconLeading;
  final Widget? iconTrailing;
  final bool? selected;
  final VoidCallback? onTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const ContinuousRectangleBorder(),
      borderOnForeground: false,
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: selected == null
            ? Theme.of(context).highlightColor
            : Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected == true ? colors?.surfaceSelected : null,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected == true
                    ? colors?.surfaceBorderSelected ?? Colors.transparent
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (iconLeading != null) ...{
                  iconLeading!,
                  const SizedBox(width: 16),
                },
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AquaText.body1SemiBold(
                        text: title,
                        color: titleColor,
                      ),
                      if (subtitle != null) ...{
                        const SizedBox(height: 4),
                        AquaText.body2Medium(
                          text: subtitle!,
                          color: subtitleColor,
                        ),
                      },
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (titleTrailing != null) ...{
                      AquaText.body1SemiBold(
                        text: titleTrailing!,
                        color: titleTrailingColor,
                      ),
                    },
                    if (subtitleTrailing != null) ...{
                      if (titleTrailing != null) ...{
                        const SizedBox(height: 4),
                      },
                      AquaText.body2Medium(
                        text: subtitleTrailing!,
                        color: subtitleTrailingColor,
                      ),
                    },
                  ],
                ),
                if (iconTrailing != null) ...{
                  const SizedBox(width: 16),
                  iconTrailing!,
                }
              ],
              // style: AquaTypography.body1,
            ),
          ),
        ),
      ),
    );
  }
}
