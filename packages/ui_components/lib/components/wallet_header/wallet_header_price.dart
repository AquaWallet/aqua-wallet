import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class AquaWalletHeaderBitcoinPrice extends StatelessWidget {
  const AquaWalletHeaderBitcoinPrice({
    super.key,
    required this.currencySymbol,
    required this.bitcoinPrice,
    required this.isNegative,
    required this.showChart,
    required this.isCached,
    required this.trendPercent,
    required this.trendAmount,
    this.bitcoinPriceText = 'Bitcoin Price',
    this.colors,
    this.isSymbolLeading,
  });

  final String? currencySymbol;
  final String? bitcoinPrice;
  final bool isNegative;
  final bool showChart;
  final bool isCached;
  final String? trendPercent;
  final String? trendAmount;
  final AquaColors? colors;
  final bool? isSymbolLeading;
  final String bitcoinPriceText;

  @override
  Widget build(BuildContext context) {
    final isTrendDataAvailable = trendPercent != null || trendAmount != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //ANCHOR - Price label
                if (!showChart && isTrendDataAvailable) ...{
                  AquaText.caption1SemiBold(
                    text: bitcoinPriceText,
                    color: colors?.textSecondary,
                  ),
                } else ...{
                  AquaText.body2SemiBold(
                    text: bitcoinPriceText,
                    color: colors?.textSecondary,
                  ),
                },
                SizedBox(height: !showChart && isTrendDataAvailable ? 2 : 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //ANCHOR - Price
                    Skeletonizer(
                      enabled: bitcoinPrice == null,
                      child: Skeleton.unite(
                        borderRadius: BorderRadius.circular(8),
                        child: Opacity(
                          opacity: isCached ? 0.5 : 1,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (isSymbolLeading == true)
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
                                if (isSymbolLeading != true)
                                  TextSpan(
                                    text: ' ${currencySymbol ?? ''}',
                                    style: AquaTypography.h5SemiBold.copyWith(
                                      color: colors?.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    //ANCHOR - Trend
                    if (isTrendDataAvailable) ...[
                      const SizedBox(width: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AquaText.caption1SemiBold(
                            text: trendAmount!,
                            color: isNegative
                                ? colors?.accentDanger
                                : colors?.accentSuccess,
                          ),
                          const SizedBox(width: 2),
                          AquaText.caption1SemiBold(
                            text: '(${trendPercent!})',
                            color: isNegative
                                ? colors?.accentDanger
                                : colors?.accentSuccess,
                          ),
                        ],
                      )
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
