import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class AquaWalletPriceBalance extends HookWidget {
  const AquaWalletPriceBalance({
    super.key,
    required this.balance,
    required this.bitcoinPrice,
    required this.currencySymbol,
    required this.displayMode,
    this.isBalanceVisible = true,
    this.priceChartData,
    this.isNegative = false,
    this.trendPercent,
    this.trendAmount,
    required this.onSend,
    required this.onReceive,
    required this.onScan,
    required this.onDisplayModeChanged,
    required this.onBalanceVisibleChanged,
    this.colors,
  });

  final String balance;
  final String bitcoinPrice;
  final String currencySymbol;
  final List<ChartDataItem>? priceChartData;
  final bool isNegative;
  final String? trendPercent;
  final String? trendAmount;
  final bool isBalanceVisible;
  final WalletHeaderDisplay displayMode;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onScan;
  final Function(WalletHeaderDisplay mode) onDisplayModeChanged;
  final Function(bool visible) onBalanceVisibleChanged;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    final isBalanceMode = displayMode == WalletHeaderDisplay.balance;

    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: colors?.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => onDisplayModeChanged(
                displayMode == WalletHeaderDisplay.balance
                    ? WalletHeaderDisplay.price
                    : WalletHeaderDisplay.balance,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        //ANCHOR - Bitcoin Price
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isBalanceMode ? 1 : 0,
                          child: AquaWalletHeaderBitcoinPrice(
                            bitcoinPrice: bitcoinPrice,
                            currencySymbol: currencySymbol,
                            isNegative: isNegative,
                            trendPercent: trendPercent,
                            trendAmount: trendAmount,
                            priceChartData: priceChartData,
                            colors: colors,
                          ),
                        ),
                        //ANCHOR - Balance
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: !isBalanceMode ? 1 : 0,
                          child: AquaWalletHeaderBalance(
                            colors: colors,
                            isBalanceVisible: isBalanceVisible,
                            balance: balance,
                            currencySymbol: currencySymbol,
                            isNegative: isNegative,
                            trendPercent: trendPercent,
                            trendAmount: trendAmount,
                            onBalanceVisibleChanged: (visible) =>
                                onBalanceVisibleChanged(visible),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
            AquaQuickActionsGroup(
              items: [
                AquaQuickActionItem.icon(
                  label: context.loc.receive,
                  icon: AquaIcon.arrowDownLeft(
                    color: colors?.textPrimary,
                  ),
                  onTap: onReceive,
                ),
                AquaQuickActionItem.icon(
                  label: context.loc.send,
                  icon: AquaIcon.arrowUpRight(
                    color: colors?.textPrimary,
                  ),
                  onTap: onSend,
                ),
                AquaQuickActionItem.icon(
                  label: context.loc.scan,
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
