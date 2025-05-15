import 'package:flutter/material.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class AquaWalletHeaderBitcoinPrice extends StatelessWidget {
  const AquaWalletHeaderBitcoinPrice({
    super.key,
    required this.currencySymbol,
    required this.bitcoinPrice,
    required this.isNegative,
    required this.trendPercent,
    required this.trendAmount,
    this.priceChartData,
    this.colors,
  });

  final String currencySymbol;
  final String bitcoinPrice;
  final bool isNegative;
  final List<ChartDataItem>? priceChartData;
  final String? trendPercent;
  final String? trendAmount;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AquaText.body2SemiBold(
                text: context.loc.bitcoinPrice,
                color: colors?.textSecondary,
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: currencySymbol,
                      style: AquaTypography.h5SemiBold.copyWith(
                        color: colors?.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: bitcoinPrice,
                      style: AquaTypography.h5SemiBold,
                    ),
                  ],
                ),
              ),
              if (trendPercent != null || trendAmount != null) ...[
                const SizedBox(height: 6),
                AquaWalletHeaderPriceTrend(
                  isNegative: isNegative,
                  trendPercent: trendPercent!,
                  trendAmount: trendAmount!,
                  currencySymbol: currencySymbol,
                  colors: colors,
                ),
              ],
            ],
          ),
        ),
        if (priceChartData != null) ...{
          const SizedBox(width: 8),
          AquaWalletPriceChart(
            data: priceChartData!,
            isNegative: isNegative,
            colors: colors,
          ),
        },
      ],
    );
  }
}
