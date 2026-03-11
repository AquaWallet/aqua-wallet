import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/components/wallet_header/wallet_header_text.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

const kCurrencySymbol = '\$';
const kBitcoinPrice = '109,493.32';

class WalletPriceBalanceDemoPage extends HookConsumerWidget {
  const WalletPriceBalanceDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(
              maxWidth: 343,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaWalletHeader(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  bitcoinPrice: kBitcoinPrice,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  text: _getWalletHeaderText(),
                ),
                const SizedBox(height: 20),
                AquaWalletHeader(
                  colors: theme.colors,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  text: _getWalletHeaderText(),
                ),
                const SizedBox(height: 20),
                AquaWalletTile(
                  onWalletPressed: () {},
                  colors: theme.colors,
                  walletName: 'Wallet 1',
                  walletBalance: '\$222,475.48',
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
                AquaWalletHeader(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  bitcoinPrice: kBitcoinPrice,
                  showChart: true,
                  priceChartData: BtcPriceHistoryUiModel(
                    isCached: false,
                    priceChartData: kFakeChartData,
                    trendPercent: '+10.46%',
                    trendAmount: '+4,831.52',
                    isNegative: false,
                  ),
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  text: _getWalletHeaderText(),
                ),
                const SizedBox(height: 20),
                AquaWalletHeader(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  bitcoinPrice: kBitcoinPrice,
                  showChart: true,
                  priceChartData: BtcPriceHistoryUiModel(
                    isCached: false,
                    priceChartData: kFakeChartData,
                    trendPercent: '-10.46%',
                    trendAmount: '-4,831.52',
                    isNegative: true,
                  ),
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  text: _getWalletHeaderText(),
                ),
                const SizedBox(height: 20),
                AquaWalletHeader(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  bitcoinPrice: kBitcoinPrice,
                  showChart: true,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  text: _getWalletHeaderText(),
                ),
                const SizedBox(height: 20),
                AquaWalletHeader(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  showChart: true,
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  text: _getWalletHeaderText(),
                ),
                const SizedBox(height: 20),
                AquaWalletHeader(
                  colors: theme.colors,
                  currencySymbol: kCurrencySymbol,
                  showChart: true,
                  priceChartData: BtcPriceHistoryUiModel(
                    isCached: false,
                    priceChartData: kFakeChartData,
                    trendPercent: '-10.46%',
                    trendAmount: '-4,831.52',
                    isNegative: true,
                  ),
                  onSend: () {},
                  onReceive: () {},
                  onScan: () {},
                  text: _getWalletHeaderText(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            constraints: const BoxConstraints(
              maxWidth: 544,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaText.body1SemiBold(
                  text: 'Desktop Balance Tile',
                  color: theme.colors.textPrimary,
                ),
                const SizedBox(height: 8),
                AquaDesktopWalletTile(
                  colors: theme.colors,
                  walletName: 'Wallet 1',
                  symbol: kCurrencySymbol,
                  walletBalance: '222,475.48',
                ),
                const SizedBox(height: 20),
                AquaText.body1SemiBold(
                  text: 'Desktop BTC Price Tile',
                  color: theme.colors.textPrimary,
                ),
                const SizedBox(height: 8),
                AquaDesktopBitcoinPriceTile(
                  bitcoinPrice: kBitcoinPrice,
                  currencySymbol: kCurrencySymbol,
                  priceChartData: kFakeChartData,
                  trendAmount: '+4,831.52',
                  trendPercent: '+10.46%',
                  isNegative: false,
                  colors: theme.colors,
                  bitcoinPriceText: 'Bitcoin Price',
                ),
                const SizedBox(height: 20),
                AquaDesktopBitcoinPriceTile(
                  bitcoinPrice: kBitcoinPrice,
                  currencySymbol: kCurrencySymbol,
                  trendAmount: '+4,831.52',
                  trendPercent: '+10.46%',
                  isNegative: false,
                  isCached: true,
                  colors: theme.colors,
                  bitcoinPriceText: 'Bitcoin Price',
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 343,
                  ),
                  child: AquaDesktopBitcoinPriceTile(
                    bitcoinPrice: kBitcoinPrice,
                    currencySymbol: kCurrencySymbol,
                    priceChartData: kFakeChartData,
                    trendAmount: '+4,831.52',
                    trendPercent: '+10.46%',
                    isNegative: false,
                    colors: theme.colors,
                    bitcoinPriceText: 'Bitcoin Price',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

WalletHeaderText _getWalletHeaderText() {
  return const WalletHeaderText(
    receive: 'Receive',
    send: 'Send',
    scan: 'Scan',
    bitcoinPrice: 'Bitcoin Price',
  );
}
