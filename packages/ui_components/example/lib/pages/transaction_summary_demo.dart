import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class TransactionSummaryDemoPage extends HookConsumerWidget {
  const TransactionSummaryDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _SendReceiveSummarySection(
                  assetId: AssetIds.btc,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.lbtc.first,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.lightning,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.usdtliquid.first,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.usdtEth,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.usdtTrx,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.usdtBep,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.usdtSol,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.usdtPol,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SendReceiveSummarySection(
                  assetId: AssetIds.usdtTon,
                  colors: theme.colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _SwapSummarySection(
                  assetId: AssetIds.btc,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SwapSummarySection(
                  assetId: AssetIds.lbtc.first,
                  colors: theme.colors,
                ),
                const SizedBox(width: 20),
                _SwapSummarySection(
                  assetId: AssetIds.usdtliquid.first,
                  colors: theme.colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SendReceiveSummarySection extends StatelessWidget {
  const _SendReceiveSummarySection({
    required this.assetId,
    required this.colors,
  });

  final String assetId;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaTransactionSummary.receive(
            assetId: assetId,
            assetTicker: _getAssetTicker(assetId),
            amountCrypto: '0.49584475',
            amountFiat: '\$4,558.51',
            colors: colors,
          ),
          const SizedBox(height: 20),
          AquaTransactionSummary.send(
            assetId: assetId,
            amountCrypto: '-0.49584475',
            amountFiat: '\$4,558.51',
            assetTicker: _getAssetTicker(assetId),
            colors: colors,
          ),
          const SizedBox(height: 20),
          AquaTransactionSummary.receive(
            assetId: assetId,
            amountCrypto: '0.49584475',
            amountFiat: '\$4,558.51',
            assetTicker: _getAssetTicker(assetId),
            isPending: true,
            colors: colors,
          ),
          const SizedBox(height: 20),
          AquaTransactionSummary.send(
            assetId: assetId,
            amountCrypto: '-0.49584475',
            amountFiat: '\$4,558.51',
            assetTicker: _getAssetTicker(assetId),
            isPending: true,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _SwapSummarySection extends StatelessWidget {
  const _SwapSummarySection({
    required this.assetId,
    required this.colors,
  });

  final String assetId;
  final AquaColors colors;

  static const _cryptoValue = '0.49584475';
  static const _fiatValue = '48,227.87';

  @override
  Widget build(BuildContext context) {
    final swapAssets = [
      AssetIds.btc,
      AssetIds.lbtc.first,
      AssetIds.usdtliquid.first
    ];
    final otherPairs = swapAssets.where((e) => e != assetId).toList();
    final otherAssetId1 = otherPairs.last;
    final otherAssetId2 = otherPairs.first;
    final fromAmount =
        '-${AssetIds.isAnyUsdt(assetId) ? _fiatValue : _cryptoValue}';
    final toAmount =
        '+${AssetIds.isAnyUsdt(assetId) ? _cryptoValue : _fiatValue}';

    return Container(
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaSwapTransactionSummary(
            fromAssetId: assetId,
            toAssetId: otherAssetId1,
            fromAssetTicker: _getAssetTicker(assetId),
            toAssetTicker: _getAssetTicker(otherAssetId1),
            fromAmountCrypto: fromAmount,
            toAmountCrypto: toAmount,
            colors: colors,
          ),
          const SizedBox(height: 20),
          AquaSwapTransactionSummary(
            fromAssetId: assetId,
            toAssetId: otherAssetId2,
            fromAssetTicker: _getAssetTicker(assetId),
            toAssetTicker: _getAssetTicker(otherAssetId2),
            fromAmountCrypto: fromAmount,
            toAmountCrypto: toAmount,
            colors: colors,
          ),
          const SizedBox(height: 20),
          AquaSwapTransactionSummary(
            fromAssetId: assetId,
            toAssetId: otherAssetId1,
            fromAssetTicker: _getAssetTicker(assetId),
            toAssetTicker: _getAssetTicker(otherAssetId1),
            fromAmountCrypto: fromAmount,
            toAmountCrypto: toAmount,
            isPending: true,
            colors: colors,
          ),
          const SizedBox(height: 20),
          AquaSwapTransactionSummary(
            fromAssetId: assetId,
            toAssetId: otherAssetId2,
            fromAssetTicker: _getAssetTicker(assetId),
            toAssetTicker: _getAssetTicker(otherAssetId2),
            fromAmountCrypto: fromAmount,
            toAmountCrypto: toAmount,
            isPending: true,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

String _getAssetTicker(String assetId) => switch (assetId) {
      AssetIds.btc => 'BTC',
      _ when (AssetIds.lbtc.contains(assetId)) => 'L-BTC',
      _ when (AssetIds.isAnyUsdt(assetId)) => 'USDt',
      AssetIds.lightning => 'Lightning',
      _ => throw UnimplementedError(),
    };
