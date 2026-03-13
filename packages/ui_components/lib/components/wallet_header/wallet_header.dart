import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/components/wallet_header/wallet_header_text.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components/shared/constants/keys.dart';

export 'desktop_btc_price_tile.dart';
export 'desktop_wallet_tile.dart';
export 'wallet_header_price.dart';
export 'wallet_tile.dart';

class AquaWalletHeader extends HookWidget {
  const AquaWalletHeader({
    super.key,
    this.bitcoinPrice,
    this.currencySymbol,
    this.priceChartData,
    this.showChart = false,
    required this.onSend,
    required this.onReceive,
    required this.onScan,
    this.colors,
    this.isSymbolLeading,
    required this.text,
  });

  final String? bitcoinPrice;
  final String? currencySymbol;
  final bool showChart;
  final BtcPriceHistoryUiModel? priceChartData;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onScan;
  final AquaColors? colors;
  final bool? isSymbolLeading;
  final WalletHeaderText text;

  @override
  Widget build(BuildContext context) {
    final chartKey = useMemoized(GlobalKey.new);
    final isSkeletonChart = priceChartData == null || priceChartData!.isCached;

    return Container(
      width: double.maxFinite,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AquaWalletHeaderBitcoinPrice(
              bitcoinPrice: bitcoinPrice,
              currencySymbol: currencySymbol,
              isNegative: priceChartData?.isNegative ?? false,
              showChart: showChart,
              isCached: priceChartData?.isCached ?? false,
              trendPercent: priceChartData?.trendPercent,
              trendAmount: priceChartData?.trendAmount,
              colors: colors,
              isSymbolLeading: isSymbolLeading,
              bitcoinPriceText: text.bitcoinPrice,
            ),
            if (showChart) ...{
              Skeletonizer(
                enabled: isSkeletonChart,
                child: Skeleton.shade(
                  child: AquaBtcPriceChart(
                    key: chartKey,
                    isSkeleton: isSkeletonChart,
                    data: priceChartData?.priceChartData,
                  ),
                ),
              ),
            },
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
            AquaQuickActionsGroup(
              items: [
                AquaQuickActionItem.icon(
                  key: AquaWalletHeaderKeys.homeScreenReceiveButton,
                  label: text.receive,
                  icon: AquaIcon.arrowDownLeft(
                    color: colors?.textPrimary,
                  ),
                  onTap: onReceive,
                ),
                AquaQuickActionItem.icon(
                  label: text.send,
                  icon: AquaIcon.arrowUpRight(
                    color: colors?.textPrimary,
                  ),
                  onTap: onSend,
                ),
                AquaQuickActionItem.icon(
                  label: text.scan,
                  icon: AquaIcon.scan(
                    color: colors?.textPrimary,
                  ),
                  onTap: onScan,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
