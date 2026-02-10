import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ManageAssetsSettings extends HookWidget {
  const ManageAssetsSettings({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final usdtliquidEnabled = useState(true);
    final usdtEthEnabled = useState(false);
    final usdtTrxEnabled = useState(false);
    final usdtBepEnabled = useState(false);
    final usdtSolEnabled = useState(false);
    final usdtPolEnabled = useState(false);
    final usdtTonEnabled = useState(false);

    return OutlineContainer(
      aquaColors: aquaColors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.lbtc.first,
              name: 'L2-Bitcoin',
              subtitle: 'Liquid & Lightning',
              amount: '0',
            ),
            colors: aquaColors,
            value: true,
            toggleable: false,
          ),
          const Divider(height: 0),
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtliquid.first,
              name: 'Tether USDt',
              subtitle: 'Liquid USDt',
              amount: '0',
            ),
            colors: aquaColors,
            value: usdtliquidEnabled.value,
            onChange: (value) => usdtliquidEnabled.value = value,
          ),
          const Divider(height: 0),
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtEth,
              name: 'Ethereum USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: aquaColors,
            value: usdtEthEnabled.value,
            onChange: (value) => usdtEthEnabled.value = value,
          ),
          const Divider(height: 0),
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtTrx,
              name: 'Tron USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: aquaColors,
            value: usdtTrxEnabled.value,
            onChange: (value) => usdtTrxEnabled.value = value,
          ),
          const Divider(height: 0),
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtBep,
              name: 'Binance USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: aquaColors,
            value: usdtBepEnabled.value,
            onChange: (value) => usdtBepEnabled.value = value,
          ),
          const Divider(height: 0),
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtSol,
              name: 'Solana USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: aquaColors,
            value: usdtSolEnabled.value,
            onChange: (value) => usdtSolEnabled.value = value,
          ),
          const Divider(height: 0),
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtPol,
              name: 'Polygon USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: aquaColors,
            value: usdtPolEnabled.value,
            onChange: (value) => usdtPolEnabled.value = value,
          ),
          const Divider(height: 0),
          AquaManageAssetsItem(
            asset: AssetUiModel(
              assetId: AssetIds.usdtTon,
              name: 'Ton USDt',
              subtitle: 'To & From L-USDt',
              amount: '0',
            ),
            colors: aquaColors,
            value: usdtTonEnabled.value,
            onChange: (value) => usdtTonEnabled.value = value,
          ),
        ],
      ),
    );
  }
}
