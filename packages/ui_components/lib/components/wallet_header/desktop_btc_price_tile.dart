import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class AquaDesktopBitcoinPriceTile extends HookWidget {
  const AquaDesktopBitcoinPriceTile({
    super.key,
    required this.bitcoinPrice,
    required this.currencySymbol,
    this.priceChartData,
    this.isNegative = false,
    this.isCached = false,
    this.trendPercent,
    this.trendAmount,
    this.colors,
    required this.bitcoinPriceText,
  });

  final String bitcoinPrice;
  final String currencySymbol;
  final List<ChartDataItem>? priceChartData;
  final bool isNegative;
  final bool isCached;
  final String? trendPercent;
  final String? trendAmount;
  final AquaColors? colors;
  final String bitcoinPriceText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWideScreen =
          constraints.maxWidth >= ResponsiveBreakpoints.maxMobileViewportWidth;
      return Container(
        decoration: BoxDecoration(
          color: colors?.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: AquaPrimitiveColors.shadow,
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 16,
          left: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BitcoinPrice(
                bitcoinPrice: bitcoinPrice,
                currencySymbol: currencySymbol,
                isNegative: isNegative,
                isCached: isCached,
                trendPercent: trendPercent,
                trendAmount: trendAmount,
                showIcon: true,
                colors: colors,
                bitcoinPriceText: bitcoinPriceText,
              ),
              Expanded(
                child: isWideScreen
                    ? Skeletonizer(
                        enabled: priceChartData == null,
                        child: Container(
                          margin: const EdgeInsets.only(left: 48),
                          child: Skeleton.shade(
                            child: AquaBtcPriceChart(
                              key: const ValueKey('btc_chart'),
                              isSkeleton: priceChartData == null || isCached,
                              data: priceChartData ?? kFakeChartData,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _BitcoinPrice extends StatelessWidget {
  const _BitcoinPrice({
    required this.currencySymbol,
    required this.bitcoinPrice,
    required this.isNegative,
    required this.trendPercent,
    required this.trendAmount,
    required this.isCached,
    this.showIcon = false,
    this.colors,
    this.bitcoinPriceText = 'Bitcoin Price',
  });

  final String currencySymbol;
  final String bitcoinPrice;
  final bool isNegative;
  final bool isCached;
  final bool showIcon;
  final String? trendPercent;
  final String? trendAmount;
  final AquaColors? colors;
  final String bitcoinPriceText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //ANCHOR - Price label
          Row(
            children: [
              if (showIcon) ...[
                AquaAssetIcon.bitcoin(size: 18),
                const SizedBox(width: 8),
              ],
              AquaText.body1SemiBold(
                text: bitcoinPriceText,
                color: colors?.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //ANCHOR - Price
              Opacity(
                opacity: isCached ? 0.5 : 1,
                child: Text.rich(
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
              ),
            ],
          ),
          //ANCHOR - Trend
          if (trendAmount != null && trendPercent != null) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AquaText.caption1SemiBold(
                  text: trendAmount!,
                  color:
                      isNegative ? colors?.accentDanger : colors?.accentSuccess,
                ),
                const SizedBox(width: 2),
                AquaText.caption1SemiBold(
                  text: '(${trendPercent!})',
                  color:
                      isNegative ? colors?.accentDanger : colors?.accentSuccess,
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
}
