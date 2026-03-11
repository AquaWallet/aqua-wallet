import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:ui_components/ui_components.dart';

enum AquaNotificationType {
  info,
  success,
  warning,
  danger,
}

class AquaNotificationItem extends HookWidget {
  const AquaNotificationItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.type = AquaNotificationType.info,
    this.onTap,
    this.colors,
    this.isRead = false,
  });

  final String title;
  final String subtitle;
  final DateTime timestamp;
  final VoidCallback? onTap;
  final AquaColors? colors;
  final bool isRead;
  final AquaNotificationType type;

  @override
  Widget build(BuildContext context) {
    Widget? icon;
    Color? backgroundIconColor;
    switch (type) {
      case AquaNotificationType.info:
        icon = AquaIcon.pending(
          size: 18,
          color: colors?.textTertiary,
        );
        backgroundIconColor = colors?.surfaceSecondary;
        break;
      case AquaNotificationType.success:
        icon = AquaIcon.checkCircle(
          size: 18,
          color: colors?.surfacePrimary,
        );
        backgroundIconColor = colors?.accentBrand;
        break;
      case AquaNotificationType.warning:
        icon = AquaIcon.warning(
          size: 18,
          color: colors?.surfacePrimary,
        );
        backgroundIconColor = colors?.accentWarning;
        break;
      case AquaNotificationType.danger:
        icon = AquaIcon.danger(
          size: 18,
          color: colors?.surfacePrimary,
        );
        backgroundIconColor = colors?.accentDanger;
        break;
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      shape: const ContinuousRectangleBorder(),
      child: InkWell(
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call())
            : null,
        splashFactory: InkRipple.splashFactory,
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
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: backgroundIconColor,
                      shape: BoxShape.circle,
                    ),
                    child: icon,
                  ),
                  const SizedBox(width: 16),
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
