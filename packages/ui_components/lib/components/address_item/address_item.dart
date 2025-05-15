import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaAddressItem extends HookWidget {
  const AquaAddressItem({
    super.key,
    required this.address,
    this.txnCount,
    this.copyable = true,
    this.onTap,
    this.colors,
  });

  final String address;
  final int? txnCount;
  final bool copyable;
  final Function(String?)? onTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      shape: const ContinuousRectangleBorder(),
      child: InkWell(
        onTap: () => onTap?.call(address),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Ink(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 77),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (txnCount != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: colors?.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            colors?.surfaceBorderPrimary ?? Colors.transparent,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: AquaText.caption1SemiBold(
                      text: '${txnCount}TX',
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: AquaColoredText(
                    text: address,
                    style: AquaAddressTypography.caption1.copyWith(
                      color: colors?.textPrimary,
                    ),
                    colorType: ColoredTextEnum.coloredIntegers,
                  ),
                ),
                const SizedBox(width: 16),
                AquaIcon.copy(
                  size: 18,
                  color: colors?.textPrimary,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
