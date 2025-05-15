import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

const kCurrencySymbol = '\$';
const kBalance = '222,475.48';
const kBitcoinPrice = '109,493.32';

// Sample data for positive trend
final kPositiveChartData = [
  const ChartDataItem(0, 20),
  const ChartDataItem(1, 25),
  const ChartDataItem(2, 22),
  const ChartDataItem(3, 28),
  const ChartDataItem(4, 24),
  const ChartDataItem(5, 30),
  const ChartDataItem(6, 27),
  const ChartDataItem(7, 32),
];

// Sample data for negative trend
final kNegativeChartData = [
  const ChartDataItem(0, 32),
  const ChartDataItem(1, 30),
  const ChartDataItem(2, 28),
  const ChartDataItem(3, 25),
  const ChartDataItem(4, 27),
  const ChartDataItem(5, 24),
  const ChartDataItem(6, 22),
  const ChartDataItem(7, 20),
];

class WalletPriceBalanceDemoPage extends HookConsumerWidget {
  const WalletPriceBalanceDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final balance = useState(kBalance);
    final isBalanceVisible = useState(true);
    final displayMode = useState(WalletHeaderDisplay.balance);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(
              maxWidth: 343,
            ),
            child: Column(
              children: [
                AquaWalletPriceBalance(
                  colors: theme.colors,
                  displayMode: displayMode.value,
                  currencySymbol: kCurrencySymbol,
                  balance: balance.value,
                  bitcoinPrice: kBitcoinPrice,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  isBalanceVisible: isBalanceVisible.value,
                  onBalanceVisibleChanged: (visible) =>
                      isBalanceVisible.value = visible,
                  onDisplayModeChanged: (mode) => displayMode.value = mode,
                ),
                const SizedBox(height: 51),
                AquaWalletPriceBalance(
                  colors: theme.colors,
                  displayMode: displayMode.value,
                  currencySymbol: kCurrencySymbol,
                  balance: balance.value,
                  bitcoinPrice: kBitcoinPrice,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  isBalanceVisible: isBalanceVisible.value,
                  onBalanceVisibleChanged: (visible) =>
                      isBalanceVisible.value = visible,
                  onDisplayModeChanged: (mode) => displayMode.value = mode,
                ),
                const SizedBox(height: 51),
                AquaWalletPriceBalance(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  balance: balance.value,
                  bitcoinPrice: kBitcoinPrice,
                  displayMode: displayMode.value,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  isBalanceVisible: isBalanceVisible.value,
                  onBalanceVisibleChanged: (visible) =>
                      isBalanceVisible.value = visible,
                  onDisplayModeChanged: (mode) => displayMode.value = mode,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            constraints: const BoxConstraints(
              maxWidth: 343,
            ),
            child: Column(
              children: [
                AquaWalletPriceBalance(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  displayMode: displayMode.value,
                  balance: balance.value,
                  bitcoinPrice: kBitcoinPrice,
                  priceChartData: kPositiveChartData,
                  trendPercent: '+10.46%',
                  trendAmount: '+${kCurrencySymbol}4,831.52',
                  isNegative: false,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  isBalanceVisible: isBalanceVisible.value,
                  onBalanceVisibleChanged: (visible) =>
                      isBalanceVisible.value = visible,
                  onDisplayModeChanged: (mode) => displayMode.value = mode,
                ),
                const SizedBox(height: 20),
                AquaWalletPriceBalance(
                  colors: theme.colors,
                  displayMode: displayMode.value,
                  currencySymbol: kCurrencySymbol,
                  balance: balance.value,
                  bitcoinPrice: kBitcoinPrice,
                  priceChartData: kNegativeChartData,
                  trendPercent: '-10.46%',
                  trendAmount: '-${kCurrencySymbol}4,831.52',
                  isNegative: true,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  isBalanceVisible: isBalanceVisible.value,
                  onBalanceVisibleChanged: (visible) =>
                      isBalanceVisible.value = visible,
                  onDisplayModeChanged: (mode) => displayMode.value = mode,
                ),
                const SizedBox(height: 20),
                AquaWalletPriceBalance(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  balance: balance.value,
                  bitcoinPrice: kBitcoinPrice,
                  displayMode: displayMode.value,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  isBalanceVisible: isBalanceVisible.value,
                  onBalanceVisibleChanged: (visible) =>
                      isBalanceVisible.value = visible,
                  onDisplayModeChanged: (mode) => displayMode.value = mode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
