import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SwapAssetPickerButton extends HookConsumerWidget {
  const SwapAssetPickerButton({
    super.key,
    required this.selectedAsset,
    required this.onAssetSelected,
  });

  final Asset? selectedAsset;
  final Function(Asset) onAssetSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(swapLoadingIndicatorStateProvider);
    final isLoading = value == const SwapProgressState.connecting() ||
        value == const SwapProgressState.waiting();
    final assets = ref.read(swapAssetsProvider.select((p) => p.assets));

    return PopupMenuButton(
      position: PopupMenuPosition.under,
      offset: Offset(2.w, -20.h),
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width - 56.w,
        maxWidth: MediaQuery.of(context).size.width - 56.w,
      ),
      shape: _AssetSelectorFieldCutOutShape(radius: 12.r),
      color: Theme.of(context).colors.swapAssetPickerPopUpItemBackground,
      onSelected: (index) =>
          Future.microtask(() => onAssetSelected(assets[index])),
      itemBuilder: (context) => assets
          .mapIndexed((index, asset) => PopupMenuItem(
                value: index,
                padding:
                    index == 0 ? EdgeInsets.only(top: 16.h) : EdgeInsets.zero,
                child: SwapAssetSelectionItem(asset),
              ))
          .toList(),
      child: SizedBox(
        height: 62.h,
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
                          ? 'Layer2Bitcoin'
                          : selectedAsset!.id,
                      assetLogoUrl: selectedAsset!.logoUrl,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  //ANCHOR - Asset Symbol
                  Text(
                    selectedAsset!.ticker,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(width: 4.w),
                  //ANCHOR - Expand Icon
                  Skeleton.ignore(
                    ignore: isLoading,
                    child: Icon(
                      Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 13.w),
                ],
              ),
      ),
    );
  }
}

class _AssetSelectorFieldCutOutShape extends ShapeBorder {
  final double radius;

  const _AssetSelectorFieldCutOutShape({required this.radius});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final subRect = Rect.fromLTRB(rect.left, rect.top, rect.right, 20.h);
    return Path.combine(
      PathOperation.difference,
      Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
        ..close(),
      Path()
        ..addRRect(RRect.fromRectAndRadius(subRect, Radius.circular(24.r)))
        ..close(),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return _AssetSelectorFieldCutOutShape(radius: radius * t);
  }
}
