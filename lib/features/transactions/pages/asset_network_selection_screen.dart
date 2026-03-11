import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart' hide AssetIds;

class AssetNetworkSelectionScreen extends HookConsumerWidget {
  static const routeName = '/assetNetworkSelectionScreen';

  const AssetNetworkSelectionScreen({
    super.key,
    this.filterAsset,
  });

  final Asset? filterAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flatAssets = ref.watch(filteredFlatAssetsProvider(filterAsset));
    final selectedAsset = ref.watch(selectedAssetProvider);
    final isNonLiquidUsdtWarningDisplayed = ref
        .watch(prefsProvider.select((p) => p.isNonLiquidUsdtWarningDisplayed));
    final isLightningWarningDisplayed =
        ref.watch(prefsProvider.select((p) => p.isLightningWarningDisplayed));

    final onAssetSelected = useCallback((Asset asset) => context.push(
          ReceiveAssetScreen.routeName,
          extra: ReceiveArguments.fromAsset(asset),
        ));
    final showAssetSwapWarning = useCallback((Asset asset) {
      // We only want to show the warning if the user has not already seen it
      AquaModalSheet.show(
        context,
        title: asset.isLightning
            ? context.loc.lightningWillBeSwapped
            : context.loc.usdtWillBeSwapped,
        message: asset.isLightning
            ? context.loc.lightningAutoSwapToLUsdtDescription
            : context.loc.usdAutoSwapToLUsdtDescription,
        primaryButtonText: context.loc.commonGotIt,
        onPrimaryButtonTap: () {
          if (asset.isLightning) {
            ref.read(prefsProvider.notifier).markLightningWarningDisplayed();
          }
          if (asset.isAltUsdt) {
            ref
                .read(prefsProvider.notifier)
                .markNonLiquidUsdtWarningDisplayed();
          }
          context.pop();
          onAssetSelected(asset);
        },
        //TODO: Enable Learn More when the link is available
        // secondaryButtonText: context.loc.learnMore,
        // onSecondaryButtonTap: () {
        //   context.pop();
        // },
        iconVariant: AquaRingedIconVariant.info,
        icon: AquaIcon.swap(
          size: 56,
          color: Colors.white,
        ),
        colors: context.aquaColors,
        copiedToClipboardText: context.loc.copiedToClipboard,
      );
    });

    ref.listen(selectedAssetProvider, (_, asset) {
      if (asset == null) return;
      Future.microtask(() {
        final isUsdtWarningPending = asset.isAnyUsdt &&
            !asset.isLiquid &&
            !isNonLiquidUsdtWarningDisplayed;
        final isLightningWarningPending =
            asset.isLightning && !isLightningWarningDisplayed;
        if (isUsdtWarningPending || isLightningWarningPending) {
          showAssetSwapWarning(asset);
        } else {
          onAssetSelected(asset);
        }
      });
    });

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: context.loc.network,
        colors: context.aquaColors,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: AquaAssetSelector.receive(
          assets: flatAssets.withSelectorSubtitles(
              context, AquaAssetSelectorType.receive),
          colors: context.aquaColors,
          type: AquaAssetSelectorType.receive,
          selectedAssetId: selectedAsset?.id,
          onAssetSelected: ref.read(selectedAssetProvider.notifier).selectAsset,
          tapForOptionsText: context.loc.tapForOptions,
        ),
      ),
    );
  }
}
