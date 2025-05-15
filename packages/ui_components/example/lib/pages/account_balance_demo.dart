import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class AccountBalanceDemoPage extends HookConsumerWidget {
  const AccountBalanceDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 343),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AquaAccountBalance(
              asset: AssetUiModel(
                assetId: AssetIds.btc,
                name: 'Bitcoin',
                subtitle: 'BTC',
                amount: '1.94839',
                amountFiat: '\$204,558.51',
              ),
              onTap: (_) {},
              colors: theme.colors,
            ),
            const SizedBox(height: 22),
            AquaAccountBalance(
              title: 'Balance',
              asset: AssetUiModel(
                assetId: AssetIds.layer2,
                name: 'L2 Bitcoin',
                subtitle: 'L2-BTC',
                amount: '1.94839',
                amountFiat: '\$204,558.51',
              ),
              onTap: (_) {},
              colors: theme.colors,
            ),
            const SizedBox(height: 22),
            AquaAccountBalance(
              asset: AssetUiModel(
                assetId: AssetIds.usdtliquid.first,
                name: 'Tether USDt',
                subtitle: 'USDt',
                amount: '11,020.38',
              ),
              onTap: (_) {},
              colors: theme.colors,
            ),
          ],
        ),
      ),
    );
  }
}
