import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaVisibilityToggleButton extends StatelessWidget {
  const AquaVisibilityToggleButton({
    super.key,
    required this.isBalanceVisible,
    required this.colors,
    this.size,
    this.onBalanceVisibilityChanged,
  });

  final double? size;
  final bool isBalanceVisible;
  final Function(bool visible)? onBalanceVisibilityChanged;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBalanceVisibilityChanged != null
          ? () => WidgetsBinding.instance.addPostFrameCallback(
              (_) => onBalanceVisibilityChanged!(!isBalanceVisible))
          : null,
      borderRadius: BorderRadius.circular(100),
      splashFactory: InkRipple.splashFactory,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
        ),
        child: isBalanceVisible
            ? AquaIcon.eyeOpen(
                color: colors.textPrimary,
                size: size ?? 16,
              )
            : AquaIcon.eyeClose(
                color: colors.textPrimary,
                size: size ?? 16,
              ),
      ),
    );
  }
}
