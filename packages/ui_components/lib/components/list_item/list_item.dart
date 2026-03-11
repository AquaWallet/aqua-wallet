import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaListItem extends StatelessWidget {
  const AquaListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.contentWidget,
    this.titleTrailing,
    this.subtitleTrailing,
    this.iconLeading,
    this.iconTrailing,
    this.iconSecondaryTrailing,
    this.titleColor,
    this.subtitleColor,
    this.titleTrailingColor,
    this.subtitleTrailingColor,
    this.backgroundColor,
    this.selected,
    this.onTap,
    this.colors,
    this.titleMaxLines = 2,
    this.subtitleMaxLines = 3,
  });

  final String title;
  final String? subtitle;
  final Widget? contentWidget;
  final String? titleTrailing;
  final String? subtitleTrailing;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? titleTrailingColor;
  final Color? subtitleTrailingColor;
  final Color? backgroundColor;
  final Widget? iconLeading;
  final Widget? iconTrailing;
  final Widget? iconSecondaryTrailing;
  final bool? selected;
  final VoidCallback? onTap;
  final int titleMaxLines;
  final int subtitleMaxLines;
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
        splashFactory: InkRipple.splashFactory,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        maxLines: titleMaxLines,
                        height: 1.3,
                      ),
                      if (contentWidget != null) ...{
                        contentWidget!,
                      } else if (subtitle != null && subtitle!.isNotEmpty) ...{
                        AquaText.body2Medium(
                          text: subtitle!,
                          color: subtitleColor,
                          height: 0,
                          maxLines: subtitleMaxLines,
                        ),
                      },
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (titleTrailing != null && titleTrailing!.isNotEmpty) ...{
                      AquaText.body1SemiBold(
                        text: titleTrailing!,
                        color: titleTrailingColor,
                        height: 1.3,
                      ),
                    },
                    if (subtitleTrailing != null &&
                        subtitleTrailing!.isNotEmpty) ...{
                      AquaText.body2Medium(
                        text: subtitleTrailing!,
                        color: subtitleTrailingColor,
                        height: 0,
                      ),
                    },
                  ],
                ),
                if (iconSecondaryTrailing != null) ...{
                  const SizedBox(width: 14),
                  iconSecondaryTrailing!,
                },
                if (iconTrailing != null) ...{
                  SizedBox(width: iconSecondaryTrailing != null ? 10 : 16),
                  iconTrailing!,
                }
              ],
            ),
          ),
        ),
      ),
    );
  }
}
