import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

class AccountItemDemoPage extends HookConsumerWidget {
  const AccountItemDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final selectedAssetIds = useState<List<String>>([]);
    final onAssetSelected = useCallback((String? assetId) {
      if (selectedAssetIds.value.contains(assetId)) {
        selectedAssetIds.value =
            selectedAssetIds.value.where((id) => id != assetId).toList();
      } else {
        selectedAssetIds.value = [...selectedAssetIds.value, assetId!];
      }
    }, [selectedAssetIds]);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 343),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AquaText.h4SemiBold(
                  text: 'Normal Tap',
                ),
                const SizedBox(height: 20),
                AquaAccountItem(
                  asset: AssetUiModel(
                    assetId: AssetIds.btc,
                    name: 'Bitcoin',
                    subtitle: 'BTC',
                    amount: '1.94839493',
                    amountFiat: '\$204,558.51',
                  ),
                  textColorTitle: theme.colors.textPrimary,
                  textColorSubtitle: theme.colors.textSecondary,
                  onTap: (_) {},
                  colors: theme.colors,
                ),
                const SizedBox(height: 20),
                AquaAccountItem(
                  asset: AssetUiModel(
                    assetId: AssetIds.lbtc.first,
                    name: 'L2 Bitcoin',
                    subtitle: 'L-BTC',
                    amount: '0.00489438',
                    amountFiat: '\$4,379.68',
                  ),
                  textColorTitle: theme.colors.textPrimary,
                  textColorSubtitle: theme.colors.textSecondary,
                  onTap: (_) {},
                  colors: theme.colors,
                ),
                const SizedBox(height: 20),
                AquaAccountItem(
                  asset: AssetUiModel(
                    assetId: AssetIds.usdtliquid.first,
                    name: 'Tether USDt',
                    subtitle: 'Liquid USDt',
                    amount: '11,020.00',
                    amountFiat: '',
                  ),
                  textColorTitle: theme.colors.textPrimary,
                  textColorSubtitle: theme.colors.textSecondary,
                  onTap: (_) {},
                  colors: theme.colors,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 343),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AquaText.h4SemiBold(
                  text: 'Selectable',
                ),
                const SizedBox(height: 20),
                AquaAccountItem(
                  asset: AssetUiModel(
                    assetId: AssetIds.btc,
                    name: 'Bitcoin',
                    subtitle: 'BTC',
                    amount: '1.94839493',
                    amountFiat: '\$204,558.51',
                  ),
                  textColorTitle: theme.colors.textPrimary,
                  textColorSubtitle: theme.colors.textSecondary,
                  selected: selectedAssetIds.value.contains(AssetIds.btc),
                  onTap: onAssetSelected,
                  colors: theme.colors,
                ),
                const SizedBox(height: 20),
                AquaAccountItem(
                  asset: AssetUiModel(
                    assetId: AssetIds.layer2,
                    name: 'L2 Bitcoin',
                    subtitle: 'L-BTC',
                    amount: '0.00489438',
                    amountFiat: '\$4,379.68',
                  ),
                  textColorTitle: theme.colors.textPrimary,
                  textColorSubtitle: theme.colors.textSecondary,
                  selected: selectedAssetIds.value.contains(AssetIds.layer2),
                  onTap: onAssetSelected,
                  colors: theme.colors,
                ),
                const SizedBox(height: 20),
                AquaAccountItem(
                  asset: AssetUiModel(
                    assetId: AssetIds.usdtliquid.first,
                    name: 'Tether USDt',
                    subtitle: 'Liquid USDt',
                    amount: '11,020.00',
                    amountFiat: '',
                  ),
                  textColorTitle: theme.colors.textPrimary,
                  textColorSubtitle: theme.colors.textSecondary,
                  selected: selectedAssetIds.value
                      .contains(AssetIds.usdtliquid.first),
                  onTap: onAssetSelected,
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
