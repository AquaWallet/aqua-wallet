import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaWalletHeaderPriceTrend extends StatelessWidget {
  const AquaWalletHeaderPriceTrend({
    super.key,
    required this.isNegative,
    required this.trendPercent,
    required this.trendAmount,
    required this.currencySymbol,
    this.colors,
  });

  final bool isNegative;
  final String trendPercent;
  final String trendAmount;
  final String currencySymbol;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isNegative
                ? colors?.accentDangerTransparent
                : colors?.accentSuccessTransparent,
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: AquaText.caption1SemiBold(
            text: trendPercent,
            color: isNegative ? colors?.accentDanger : colors?.accentSuccess,
          ),
        ),
        const SizedBox(width: 8),
        AquaText.caption1SemiBold(
          text: trendAmount,
          color: isNegative ? colors?.accentDanger : colors?.accentSuccess,
        ),
      ],
    );
  }
}
