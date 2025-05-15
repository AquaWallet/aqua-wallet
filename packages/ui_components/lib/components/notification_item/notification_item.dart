import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:ui_components/ui_components.dart';

class AquaNotificationItem extends HookWidget {
  const AquaNotificationItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.icon,
    this.onTap,
    this.colors,
    this.isRead = false,
  });

  final String title;
  final String subtitle;
  final Widget? icon;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final AquaColors? colors;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      shape: const ContinuousRectangleBorder(),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Opacity(
          opacity: isRead ? 0.5 : 1,
          child: Ink(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...{
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
                      child: icon!,
                    ),
                    const SizedBox(width: 16),
                  },
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AquaText.body1SemiBold(
                                text: title,
                                color: colors?.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            AquaText.caption2SemiBold(
                              text: timestamp
                                  .toMoment()
                                  .fromNow(form: Abbreviation.semi),
                              color: colors?.textTertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AquaText.body2Medium(
                          text: subtitle,
                          color: colors?.textSecondary,
                        ),
                      ],
                    ),
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
