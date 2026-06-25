import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/settings/settings.dart' hide AssetIds;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LnAddressPayWithPage extends HookConsumerWidget {
  const LnAddressPayWithPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payableData = ref.watch(lnPayableAssetsProvider);

    final payableAssets = useMemoized(() {
      final result = <AssetUiModel, List<AssetUiModel>>{};
      for (final (:asset, :amountCrypto, :amountFiat, :displayUnit)
          in payableData) {
        var uiModel = asset.toUiModel(
          name: asset.isLBTC ? context.loc.l2Bitcoin : asset.name,
          amountCrypto: amountCrypto,
          amountFiat: amountFiat,
          displayUnit: displayUnit,
        );
        if (asset.isLBTC) {
          uiModel = uiModel.copyWith(assetId: AssetIds.layer2, iconUrl: '');
        }
        result[uiModel] = <AssetUiModel>[];
      }
      return result.withSelectorSubtitles(context, AquaAssetSelectorType.send);
    }, [payableData]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AquaAssetSelector.send(
              assets: payableAssets,
              colors: context.aquaColors,
              type: AquaAssetSelectorType.send,
              onAssetSelected: (assetId) {
                if (assetId == null) return;
                final asset = payableData.map((d) => d.asset).firstWhereOrNull(
                      (a) =>
                          a.id == assetId ||
                          (a.isLBTC && assetId == AssetIds.layer2),
                    );
                if (asset != null) {
                  ref
                      .read(lnAddressEditInputProvider.notifier)
                      .setSelectedAsset(asset);
                }
                ref
                    .read(lnAddressEditStepProvider.notifier)
                    .setStep(LnAddressEditStep.confirm);
              },
              tapForOptionsText: context.loc.tapForOptions,
            ),
          ),
        ],
      ),
    );
  }
}
