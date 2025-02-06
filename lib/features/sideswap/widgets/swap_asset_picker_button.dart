import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SwapAssetPickerButton extends HookConsumerWidget {
  const SwapAssetPickerButton({
    super.key,
    required this.isReceive,
    required this.selectedAsset,
    required this.counterAsset,
    required this.onAssetSelected,
  });

  final bool isReceive;
  final Asset? selectedAsset;
  final Asset? counterAsset;
  final Function(Asset) onAssetSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(swapLoadingIndicatorStateProvider);
    final isLoading = value == const SwapProgressState.connecting() ||
        value == const SwapProgressState.waiting();
    // If receive, limit assets to only assets swappable with send asset
    final swappableAssets = isReceive
        ? ref.read(swapAssetsProvider).swappableAssets(counterAsset)
        : ref.read(swapAssetsProvider.select((p) => p.assets));

    return PopupMenuButton(
      position: PopupMenuPosition.under,
      offset: const Offset(2.0,
          -18.0), // Use radius values to make offsets to match the shape cutout
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      shape: AssetSelectorFieldCutOutShape(
        radius: 12.0,
        borderColor:
            Theme.of(context).colors.popUpMenuButtonSwapScreenBorderColor,
      ),
      shadowColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width - 56.0,
        maxWidth: MediaQuery.of(context).size.width - 56.0,
      ),
      color: Theme.of(context).colors.addressFieldContainerBackgroundColor,
      onSelected: (index) =>
          Future.microtask(() => onAssetSelected(swappableAssets[index])),
      itemBuilder: (context) => swappableAssets
          .mapIndexed((index, asset) => PopupMenuItem(
                value: index,
                padding: index == 0
                    ? const EdgeInsets.only(top: 16.0)
                    : EdgeInsets.zero,
                child: AssetSelectionDropDownItem(asset),
              ))
          .toList(),
      child: SizedBox(
        height: 62.0,
        child: selectedAsset == null
            ? const SizedBox.shrink()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //ANCHOR - Asset Logo
                  Skeleton.ignore(
                    ignore: isLoading,
                    child: AssetIcon(
                      assetId: selectedAsset!.isLBTC
                          ? kLayer2BitcoinId
                          : selectedAsset!.id,
                      assetLogoUrl: selectedAsset!.logoUrl,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  //ANCHOR - Asset Symbol
                  Text(
                    selectedAsset!.ticker,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 4.0),
                  //ANCHOR - Expand Icon
                  Skeleton.ignore(
                    ignore: isLoading,
                    child: Icon(
                      Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 13.0),
                ],
              ),
      ),
    );
  }
}
