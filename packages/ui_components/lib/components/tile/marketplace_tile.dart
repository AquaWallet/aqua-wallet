import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaMarketplaceTile extends StatelessWidget {
  const AquaMarketplaceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.size = 164,
    this.isEnabled = true,
    this.colors,
    this.onTap,
  });

  final String title;
  final String subtitle;
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
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
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          splashFactory: NoSplash.splashFactory,
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
                      AquaText.body1SemiBold(
                        text: title,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 4),
                      AquaText.caption1Medium(
                        text: subtitle,
                        color: colors?.textSecondary,
                      ),
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
