import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/models/models.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class TileDemoPage extends HookConsumerWidget {
  const TileDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AquaText.h3(text: 'Fee Tile'),
          const SizedBox(height: 20),
          Row(
            children: [
              _FeeTilesPanel(
                title: 'Default',
                theme: theme,
                onPressed: () {},
              ),
              const SizedBox(width: 20),
              _FeeTilesPanel(
                title: 'Selected',
                theme: theme,
                isSelected: true,
                onPressed: () {},
              ),
              const SizedBox(width: 20),
              _FeeTilesPanel(
                title: 'Disabled',
                theme: theme,
                isEnabled: false,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),
          const AquaText.h3(text: 'Marketplace'),
          const SizedBox(height: 20),
          Row(
            children: [
              _MarketplaceTilesPanel(
                title: 'Default',
                theme: theme,
                onPressed: () {},
              ),
              const SizedBox(width: 20),
              _MarketplaceTilesPanel(
                title: 'Disabled',
                isEnabled: false,
                theme: theme,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeTilesPanel extends StatelessWidget {
  const _FeeTilesPanel({
    required this.title,
    required this.theme,
    this.onPressed,
    this.isEnabled = true,
    this.isSelected = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final AppTheme theme;
  final bool isEnabled;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AquaText.subtitleSemiBold(text: title),
        const SizedBox(height: 20),
        AquaFeeTile(
          title: 'Standard',
          amountCrypto: '25 sats/vbyte',
          amountFiat: '≈ \$1.9662',
          colors: theme.colors,
          isSelected: isSelected,
          isEnabled: isEnabled,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        AquaFeeTile(
          title: 'L2-BTC',
          amountCrypto: '0.00000493 BTC',
          amountFiat: '≈ \$0.04',
          icon: AquaAssetIcon.l2Bitcoin(size: 18),
          colors: theme.colors,
          isSelected: isSelected,
          isEnabled: isEnabled,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        AquaFeeTile(
          title: 'USDt',
          amountCrypto: '~0.08 USDt',
          icon: AquaAssetIcon.usdtLiquid(size: 18),
          colors: theme.colors,
          isSelected: isSelected,
          isEnabled: isEnabled,
          onTap: () {},
        ),
      ],
    );
  }
}

class _MarketplaceTilesPanel extends StatelessWidget {
  const _MarketplaceTilesPanel({
    required this.title,
    required this.theme,
    this.onPressed,
    this.isEnabled = true,
  });

  final String title;
  final VoidCallback? onPressed;
  final AppTheme theme;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AquaText.subtitleSemiBold(text: title),
        const SizedBox(height: 20),
        AquaMarketplaceTile(
          title: 'Market Tile',
          subtitle: 'Market item description goes here and continues here.',
          icon: AquaIcon.creditCard(
            size: 18,
            color: theme.colors.textSecondary,
          ),
          colors: theme.colors,
          isEnabled: isEnabled,
          onTap: onPressed,
        ),
      ],
    );
  }
}
