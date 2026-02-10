import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

enum AquaToastVariant {
  normal,
  warning,
  error,
}

class AquaToastAction {
  const AquaToastAction({
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;
}

class AquaToast extends HookWidget {
  const AquaToast._({
    super.key,
    required this.title,
    required this.description,
    required this.variant,
    required this.aquaColors,
    this.onClose,
    this.actions,
    this.duration,
    this.onDismiss,
  });

  factory AquaToast({
    Key? key,
    required String title,
    required String description,
    required AquaToastVariant variant,
    required AquaColors aquaColors,
    VoidCallback? onClose,
    List<AquaToastAction>? actions,
  }) {
    return AquaToast._(
      key: key,
      title: title,
      description: description,
      variant: variant,
      aquaColors: aquaColors,
      onClose: onClose,
      actions: actions,
    );
  }

  factory AquaToast.timed({
    Key? key,
    required String title,
    required String description,
    required AquaToastVariant variant,
    required AquaColors aquaColors,
    required Duration duration,
    required VoidCallback onDismiss,
    VoidCallback? onClose,
    List<AquaToastAction>? actions,
  }) {
    return AquaToast._(
      key: key,
      title: title,
      description: description,
      variant: variant,
      aquaColors: aquaColors,
      onClose: onClose,
      actions: actions,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  final String title;
  final String description;
  final AquaToastVariant variant;
  final AquaColors aquaColors;
  final VoidCallback? onClose;
  final List<AquaToastAction>? actions;
  final Duration? duration;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: duration ?? const Duration(seconds: 5),
    );

    final progress = useAnimation(
      Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      ),
    );

    useEffect(() {
      if (duration != null) {
        controller.forward().whenComplete(() {
          if (context.mounted) {
            onDismiss?.call();
          }
        });
      }
      return null;
    }, []);

    final icon = switch (variant) {
      AquaToastVariant.normal => AquaIcon.infoCircle(
          color: aquaColors.textPrimary,
          size: 18,
        ),
      AquaToastVariant.warning => AquaIcon.warning(
          color: aquaColors.accentWarning,
          size: 18,
        ),
      AquaToastVariant.error => AquaIcon.danger(
          color: aquaColors.accentDanger,
          size: 18,
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: aquaColors.surfacePrimary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          if (duration != null) ...[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 4,
                    color: aquaColors.surfaceTertiary,
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: switch (variant) {
                          AquaToastVariant.normal => aquaColors.accentBrand,
                          AquaToastVariant.warning => aquaColors.accentWarning,
                          AquaToastVariant.error => aquaColors.accentDanger,
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(
                top: 16.0, left: 16.0, right: 16.0, bottom: 0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AquaText.body1SemiBold(
                            text: title,
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 4.0),
                          AquaText.body1(
                            text: description,
                            textAlign: TextAlign.left,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    if (onClose != null) ...[
                      const SizedBox(width: 16.0),
                      AquaIcon.close(
                        color: aquaColors.textSecondary,
                        size: 18,
                        onTap: onClose,
                      ),
                    ],
                  ],
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 12.0),
                  _ActionButtons(
                    actions: actions!,
                    aquaColors: aquaColors,
                  ),
                ] else ...[
                  const SizedBox(height: 16.0),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.actions, required this.aquaColors});

  final List<AquaToastAction> actions;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final reversedActions = actions.reversed.toList();
    return Row(
      children: reversedActions.asMap().entries.map((entry) {
        final index = entry.key;
        final isFirst = index == 0;
        final isLast = index == reversedActions.length - 1;
        final textColor =
            index.isEven ? aquaColors.textSecondary : aquaColors.textPrimary;

        return Expanded(
          child: _CustomActionButton(
            text: entry.value.title,
            onPressed: entry.value.onPressed,
            textColor: textColor,
            aquaColors: aquaColors,
            hasTopBorder: true,
            hasLeftBorder: !isFirst,
            hasRightBorder: !isLast,
          ),
        );
      }).toList(),
    );
  }
}

class _CustomActionButton extends StatelessWidget {
  const _CustomActionButton({
    required this.text,
    required this.onPressed,
    required this.textColor,
    required this.aquaColors,
    required this.hasTopBorder,
    required this.hasLeftBorder,
    required this.hasRightBorder,
  });

  final String text;
  final VoidCallback onPressed;
  final Color textColor;
  final AquaColors aquaColors;
  final bool hasTopBorder;
  final bool hasLeftBorder;
  final bool hasRightBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: hasTopBorder
              ? BorderSide(
                  color: aquaColors.surfaceBorderPrimary,
                  width: 1,
                )
              : BorderSide.none,
          left: hasLeftBorder
              ? BorderSide(
                  color: aquaColors.surfaceBorderPrimary,
                  width: 1,
                )
              : BorderSide.none,
          right: hasRightBorder
              ? BorderSide(
                  color: aquaColors.surfaceBorderPrimary,
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: AquaText.body2SemiBold(
                text: text,
                color: textColor,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
