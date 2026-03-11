import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaMarketplaceTile extends StatelessWidget {
  const AquaMarketplaceTile({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.subtitleWidget,
    required this.icon,
    this.size = 164,
    this.isEnabled = true,
    this.colors,
    this.onTap,
  })  : assert(title == null || titleWidget == null,
            'Only one of title or titleWidget should be provided'),
        assert(subtitle == null || subtitleWidget == null,
            'Only one of subtitle or subtitleWidget should be provided');

  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? subtitleWidget;
  final double size;
  final Widget icon;
  final bool isEnabled;
  final VoidCallback? onTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: colors?.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: AquaPrimitiveColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        shadowColor: null,
        type: MaterialType.canvas,
        child: InkWell(
          onTap: isEnabled && onTap != null
              ? () => WidgetsBinding.instance
                  .addPostFrameCallback((_) => onTap?.call())
              : null,
          borderRadius: BorderRadius.circular(8),
          splashFactory: InkRipple.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((state) {
            if (state.isHovered) {
              return Colors.transparent;
            }
            return null;
          }),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.5,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: colors?.surfaceSecondary,
                          border: Border.all(
                            color: colors?.surfaceBorderSecondary ??
                                Colors.transparent,
                            width: 1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: icon,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title != null
                          ? AquaText.body1SemiBold(
                              text: title!,
                              color: colors?.textPrimary,
                            )
                          : titleWidget ?? const SizedBox.shrink(),
                      const SizedBox(height: 4),
                      subtitle != null
                          ? AquaText.caption1Medium(
                              text: subtitle!,
                              color: colors?.textSecondary,
                            )
                          : subtitleWidget ?? const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
