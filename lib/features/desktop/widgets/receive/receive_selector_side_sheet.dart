import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveSelectorSideSheet extends HookWidget {
  const ReceiveSelectorSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    final selectedAssetId = useState<String?>(null);
    final assetsWithSubtitles = receiveAssets.withSelectorSubtitles(
      context,
      AquaAssetSelectorType.receive,
    );
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.receive,
      showBackButton: false,
      children: [
        AquaAssetSelector.receive(
          assets: assetsWithSubtitles,
          selectedAssetId: selectedAssetId.value,
          colors: aquaColors,
          tapForOptionsText: loc.tapForOptions,
          onAssetSelected: (assetId) {
            debugPrint(assetId);
            if (assetId == null) return;
            if (selectedAssetId.value == assetId) {
              selectedAssetId.value = null;
            } else {
              if (assetId != AssetIds.usdtTether) {
                var nameOfAsset = '';
                nameOfAsset = assetsWithSubtitles.keys
                        .firstWhereOrNull((key) => key.assetId == assetId)
                        ?.name ??
                    '';
                if (selectedAssetId.value == AssetIds.usdtTether) {
                  nameOfAsset = assetsWithSubtitles.entries
                          .firstWhereOrNull((element) =>
                              element.key.assetId == selectedAssetId.value)
                          ?.value
                          .firstWhereOrNull((name) => name.assetId == assetId)
                          ?.name ??
                      '';
                }
                if (assetId == AssetIds.lightning) {
                  ReceiveSetAmountSideSheet.show(
                    context: context,
                    aquaColors: aquaColors,
                    loc: loc,
                    assetId: assetId,
                    nameOfAsset: nameOfAsset,
                  );
                } else if (AssetIds.usdtliquid.contains(assetId) ||
                    assetId == AssetIds.btc ||
                    AssetIds.lbtc.contains(assetId)) {
                  ReceiveFlowSideSheet.show(
                    assetId: assetId,
                    context: context,
                    aquaColors: aquaColors,
                    loc: loc,
                    nameOfAsset: nameOfAsset,
                  );
                } else {
                  ReceiveSpecialUsdtSideSheet.show(
                    context: context,
                    aquaColors: aquaColors,
                    loc: loc,
                    assetId: assetId,
                    nameOfAsset: nameOfAsset,
                  );
                }
              }
              selectedAssetId.value = assetId;
            }
          },
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: ReceiveSelectorSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
