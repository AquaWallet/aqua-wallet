import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/models/models.dart';
import 'package:ui_components_playground/shared/extensions/extensions.dart';

import '../providers/providers.dart';

class ManageAssetsItemDemoPage extends HookConsumerWidget {
  const ManageAssetsItemDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ManageAssetsItemDemoSection(
            theme: theme,
            separator: const SizedBox(height: 20),
          ),
          const SizedBox(width: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ManageAssetsItemDemoSection(
              theme: theme,
              separator: const Divider(height: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageAssetsItemDemoSection extends HookWidget {
  const _ManageAssetsItemDemoSection({
    required this.theme,
    required this.separator,
  });

  final AppTheme theme;
  final Widget separator;

  @override
  Widget build(BuildContext context) {
    final usdtliquidEnabled = useState(true);
    final usdtEthEnabled = useState(true);
    final usdtTrxEnabled = useState(true);
    final usdtBepEnabled = useState(true);
    final usdtSolEnabled = useState(true);
    final usdtPolEnabled = useState(true);
    final usdtTonEnabled = useState(true);

    return Container(
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.lbtc.first,
              name: 'L2-Bitcoin',
              subtitle: 'Liquid & Lightning',
              amount: '0',
            ),
            colors: theme.colors,
            value: true,
            toggleable: false,
          ),
          separator,
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtliquid.first,
              name: 'Tether USDt',
              subtitle: 'Liquid USDt',
              amount: '0',
            ),
            colors: theme.colors,
            value: usdtliquidEnabled.value,
            onChange: (value) => usdtliquidEnabled.value = value,
          ),
          separator,
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtEth,
              name: 'Ethereum USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: theme.colors,
            value: usdtEthEnabled.value,
            onChange: (value) => usdtEthEnabled.value = value,
          ),
          separator,
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtTrx,
              name: 'Tron USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: theme.colors,
            value: usdtTrxEnabled.value,
            onChange: (value) => usdtTrxEnabled.value = value,
          ),
          separator,
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtBep,
              name: 'Binance USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: theme.colors,
            value: usdtBepEnabled.value,
            onChange: (value) => usdtBepEnabled.value = value,
          ),
          separator,
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtSol,
              name: 'Solana USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: theme.colors,
            value: usdtSolEnabled.value,
            onChange: (value) => usdtSolEnabled.value = value,
          ),
          separator,
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtPol,
              name: 'Polygon USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: theme.colors,
            value: usdtPolEnabled.value,
            onChange: (value) => usdtPolEnabled.value = value,
          ),
          separator,
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtTon,
              name: 'Ton USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: theme.colors,
            value: usdtTonEnabled.value,
            onChange: (value) => usdtTonEnabled.value = value,
          ),
        ],
      ),
    );
  }
}
