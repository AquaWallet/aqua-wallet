import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/models/models.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

final kDate = DateTime(2025, 2, 11);

class TransactionItemDemoPage extends HookConsumerWidget {
  const TransactionItemDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AquaTransactionIcon.receive(
                colors: theme.colors,
              ),
              const SizedBox(width: 20),
              AquaTransactionIcon.send(
                colors: theme.colors,
              ),
              const SizedBox(width: 20),
              AquaTransactionIcon.swap(
                colors: theme.colors,
              ),
              const SizedBox(width: 20),
              AquaTransactionIcon.receive(
                colors: theme.colors,
                isFailed: true,
              ),
              const SizedBox(width: 20),
              AquaTransactionIcon.send(
                colors: theme.colors,
                isFailed: true,
              ),
              const SizedBox(width: 20),
              AquaTransactionIcon.swap(
                colors: theme.colors,
                isFailed: true,
              ),
            ],
          ),
          const SizedBox(height: 40),
          _AssetTransactionsDemoSection(
            theme: theme,
            title: 'Bitcoin',
            assetTicker: 'BTC',
            includeUsdt: false,
          ),
          _AssetTransactionsDemoSection(
            theme: theme,
            title: 'L2-BTC',
            assetTicker: 'L-BTC',
            assetId: AssetIds.lightning,
          ),
          _AssetTransactionsDemoSection(
            theme: theme,
            title: 'USDt',
            assetTicker: 'USDt',
            assetId: AssetIds.usdtTrx,
            includeUsdt: false,
          ),
        ],
      ),
    );
  }
}

class _AssetTransactionsDemoSection extends StatelessWidget {
  const _AssetTransactionsDemoSection({
    required this.theme,
    required this.title,
    required this.assetTicker,
    this.assetId,
    this.includeUsdt = true,
  });

  final AppTheme theme;
  final String? assetId;
  final String title;
  final String assetTicker;
  final bool includeUsdt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: AquaText.body1SemiBold(text: title),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TransactionItemDemoSection(
                  title: 'Confirmed',
                  assetTicker: assetTicker,
                  theme: theme,
                  includeUsdt: includeUsdt,
                  assetId: assetId,
                ),
                const SizedBox(width: 20),
                _TransactionItemDemoSection(
                  title: 'Pending',
                  assetTicker: assetTicker,
                  theme: theme,
                  includeUsdt: includeUsdt,
                  assetId: assetId,
                  isPending: true,
                ),
                const SizedBox(width: 20),
                _TransactionItemDemoSection(
                  title: 'Failed',
                  assetTicker: assetTicker,
                  theme: theme,
                  includeUsdt: includeUsdt,
                  assetId: assetId,
                  isPending: false,
                  isFailed: true,
                ),
                const SizedBox(width: 20),
                _SingleTransactionSection(
                  title: 'Refund',
                  assetTicker: assetTicker,
                  isRefund: true,
                  theme: theme,
                ),
                const SizedBox(width: 20),
                _SingleTransactionSection(
                  title: 'Insufficient Funds',
                  assetTicker: assetTicker,
                  theme: theme,
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionItemDemoSection extends StatelessWidget {
  const _TransactionItemDemoSection({
    required this.theme,
    required this.title,
    required this.assetTicker,
    this.isPending = false,
    this.isFailed = false,
    this.includeUsdt = true,
    this.assetId,
  });

  final AppTheme theme;
  final String title;
  final String assetTicker;
  final bool isPending;
  final bool isFailed;
  final bool includeUsdt;
  final String? assetId;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaText.body1SemiBold(text: title),
          const SizedBox(height: 20),
          AquaTransactionItem.receive(
            isPending: isPending,
            isFailed: isFailed,
            colors: theme.colors,
            timestamp: kDate,
            amountCrypto: '0.04738384',
            amountFiat: '\$4,558.51',
            onTap: () => debugPrint('Transaction item tapped'),
          ),
          const SizedBox(height: 20),
          AquaTransactionItem.send(
            isPending: isPending,
            isFailed: isFailed,
            colors: theme.colors,
            timestamp: kDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            onTap: () => debugPrint('Transaction item tapped'),
          ),
          const SizedBox(height: 20),
          AquaTransactionItem.swap(
            isPending: isPending,
            isFailed: isFailed,
            colors: theme.colors,
            fromAssetTicker: assetTicker == 'L-BTC' ? 'BTC' : 'L-BTC',
            toAssetTicker: assetTicker,
            timestamp: kDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            onTap: () => debugPrint('Transaction item tapped'),
          ),
          const SizedBox(height: 20),
          AquaTransactionItem.swap(
            isPending: isPending,
            isFailed: isFailed,
            colors: theme.colors,
            fromAssetTicker: assetTicker,
            toAssetTicker: assetTicker == 'L-BTC' ? 'BTC' : 'L-BTC',
            timestamp: kDate,
            amountCrypto: '-0.04738384',
            amountFiat: '-\$4,558.51',
            onTap: () => debugPrint('Transaction item tapped'),
          ),
          if (includeUsdt) ...[
            const SizedBox(height: 20),
            AquaTransactionItem.swap(
              isPending: isPending,
              isFailed: isFailed,
              colors: theme.colors,
              fromAssetTicker: 'USDt',
              toAssetTicker: assetTicker,
              timestamp: kDate,
              amountCrypto: '-0.04738384',
              amountFiat: '-\$4,558.51',
              onTap: () => debugPrint('Transaction item tapped'),
            ),
            const SizedBox(height: 20),
            AquaTransactionItem.swap(
              isPending: isPending,
              isFailed: isFailed,
              colors: theme.colors,
              fromAssetTicker: assetTicker,
              toAssetTicker: 'USDt',
              timestamp: kDate,
              amountCrypto: '-0.04738384',
              amountFiat: '-\$4,558.51',
              onTap: () => debugPrint('Transaction item tapped'),
            ),
          ],
          if (assetId != null) ...[
            const SizedBox(height: 20),
            AquaTransactionItem.receive(
              assetId: assetId,
              isPending: isPending,
              isFailed: isFailed,
              colors: theme.colors,
              timestamp: kDate,
              amountCrypto: '-0.04738384',
              amountFiat: '-\$4,558.51',
              onTap: () => debugPrint('Transaction item tapped'),
            ),
            const SizedBox(height: 20),
            AquaTransactionItem.send(
              assetId: assetId,
              isPending: isPending,
              isFailed: isFailed,
              colors: theme.colors,
              timestamp: kDate,
              amountCrypto: '-0.04738384',
              amountFiat: '-\$4,558.51',
              onTap: () => debugPrint('Transaction item tapped'),
            ),
          ]
        ],
      ),
    );
  }
}

class _SingleTransactionSection extends StatelessWidget {
  const _SingleTransactionSection({
    required this.theme,
    required this.title,
    required this.assetTicker,
    this.isRefund = false,
  });

  final AppTheme theme;
  final String title;
  final String assetTicker;
  final bool isRefund;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaText.body1SemiBold(
            text: isRefund ? 'Refund' : 'Insufficient Funds',
          ),
          const SizedBox(height: 20),
          if (isRefund) ...{
            AquaTransactionItem.refund(
              colors: theme.colors,
              timestamp: kDate,
              amountCrypto: '0.04738384',
              amountFiat: '\$4,558.51',
              onTap: () => debugPrint('Transaction item tapped'),
            ),
          } else ...{
            AquaTransactionItem.insufficientFunds(
              colors: theme.colors,
              timestamp: kDate,
              amountCrypto: '0.04738384',
              amountFiat: '\$4,558.51',
              onTap: () => debugPrint('Transaction item tapped'),
            ),
          }
        ],
      ),
    );
  }
}
