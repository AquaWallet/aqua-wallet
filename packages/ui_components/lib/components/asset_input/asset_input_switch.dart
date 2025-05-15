import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaAssetInputSwitch extends HookWidget {
  const AquaAssetInputSwitch({
    super.key,
    required this.assetId,
    required this.ticker,
    required this.unit,
    this.showDropdown = true,
    this.colors,
    this.onTap,
  });

  final String assetId;
  final String ticker;
  final AquaAssetInputUnit unit;
  final bool showDropdown;
  final AquaColors? colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLbtc = AssetIds.lbtc.contains(assetId);

    return Card(
      elevation: 0,
      color: colors?.surfaceSecondary,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaAssetIcon.fromAssetId(
                assetId: assetId,
                size: 18,
              ),
              const SizedBox(width: 8),
              AquaText.body2SemiBold(
                text: switch (unit) {
                  AquaAssetInputUnit.sats when (isLbtc) => 'L-Sats',
                  AquaAssetInputUnit.sats => 'Sats',
                  AquaAssetInputUnit.bits when (isLbtc) => 'L-Bits',
                  AquaAssetInputUnit.bits => 'Bits',
                  _ => ticker,
                },
              ),
              if (showDropdown) ...[
                const SizedBox(width: 2),
                AquaIcon.caret(
                  size: 16,
                  color: colors?.textTertiary,
                ),
              ] else ...{
                const SizedBox(width: 8),
              },
            ],
          ),
        ),
      ),
    );
  }
}
