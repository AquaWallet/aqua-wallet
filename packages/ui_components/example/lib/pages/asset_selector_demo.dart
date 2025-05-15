import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';

import '../providers/providers.dart';
import '../shared/shared.dart';

final assets = <AssetUiModel, List<AssetUiModel>>{
  AssetUiModel(
    assetId: AssetIds.btc,
    name: 'Bitcoin',
    subtitle: '',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ): [],
  AssetUiModel(
    assetId: AssetIds.lbtc.first,
    name: 'Liquid Bitcoin',
    subtitle: '',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ): [],
  AssetUiModel(
    assetId: AssetIds.lightning,
    name: 'Bitcoin Lightning',
    subtitle: '',
    amount: '1.94839493',
    amountFiat: '\$204,558.51',
  ): [],
  AssetUiModel(
    assetId: AssetIds.usdtTether,
    name: 'Tether USDt',
    subtitle: '',
    amount: '11,020.00',
    amountFiat: '',
  ): [
    AssetUiModel(
      assetId:
          'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2',
      name: 'Liquid USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtEth,
      name: 'Ethereum USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtTrx,
      name: 'Tron USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtBep,
      name: 'Binance USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtSol,
      name: 'Solana USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtPol,
      name: 'Polygon USDt',
      subtitle: '',
      amount: '',
    ),
    AssetUiModel(
      assetId: AssetIds.usdtTon,
      name: 'Ton USDt',
      subtitle: '',
      amount: '',
    ),
  ],
};

class AssetSelectorDemoPage extends HookConsumerWidget {
  const AssetSelectorDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final selectedAssetId = useState<String?>(null);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 343),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AquaText.subtitleSemiBold(text: 'Receive Asset Selector'),
                const SizedBox(height: 20),
                AquaAssetSelector.receive(
                  assets: assets,
                  selectedAssetId: selectedAssetId.value,
                  colors: theme.colors,
                  onAssetSelected: (assetId) {
                    if (assetId == null) return;
                    if (selectedAssetId.value == assetId) {
                      selectedAssetId.value = null;
                    } else {
                      selectedAssetId.value = assetId;
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 343),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AquaText.subtitleSemiBold(text: 'Send Asset Selector'),
                const SizedBox(height: 20),
                AquaAssetSelector.send(
                  assets: assets,
                  selectedAssetId: selectedAssetId.value,
                  colors: theme.colors,
                  onAssetSelected: (assetId) {
                    if (assetId == null) return;
                    if (selectedAssetId.value == assetId) {
                      selectedAssetId.value = null;
                    } else {
                      selectedAssetId.value = assetId;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
