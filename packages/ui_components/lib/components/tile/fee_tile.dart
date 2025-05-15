import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaFeeTile extends StatelessWidget {
  const AquaFeeTile({
    super.key,
    required this.title,
    required this.amountCrypto,
    this.amountFiat,
    this.size = 164,
    this.icon,
    this.isSelected = false,
    this.isEnabled = true,
    this.colors,
    this.onTap,
  });

  final String title;
  final String amountCrypto;
  final String? amountFiat;
  final double size;
  final Widget? icon;
  final bool isSelected;
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
        color: isSelected
            ? colors?.surfaceSelected
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? colors?.surfaceBorderSelected ?? Colors.transparent
              : Colors.transparent,
          width: 2,
        ),
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
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: AquaText.body2Medium(
                          text: title,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : colors?.textSecondary,
                        ),
                      ),
                      AquaRadio.small(
                        groupValue: true,
                        value: isSelected,
                      )
                    ],
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AquaText.body2SemiBold(
                        text: amountCrypto,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      if (amountFiat != null) ...[
                        const SizedBox(height: 4),
                        AquaText.caption1Medium(
                          text: amountFiat!,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : colors?.textSecondary,
                        ),
                      ],
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
