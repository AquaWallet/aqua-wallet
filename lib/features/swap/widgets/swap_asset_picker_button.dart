import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
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
      offset: Offset(2.r,
          -18.r), // Use radius values to make offsets to match the shape cutout
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      shape: _AssetSelectorFieldCutOutShape(
        radius: 12.r,
        borderColor:
            Theme.of(context).colors.popUpMenuButtonSwapScreenBorderColor,
      ),
      shadowColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width - 56.w,
        maxWidth: MediaQuery.of(context).size.width - 56.w,
      ),
      color: Theme.of(context).colors.addressFieldContainerBackgroundColor,
      onSelected: (index) =>
          Future.microtask(() => onAssetSelected(swappableAssets[index])),
      itemBuilder: (context) => swappableAssets
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
  final Color borderColor;

  const _AssetSelectorFieldCutOutShape({
    required this.borderColor,
    required this.radius,
  });

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
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Path outerPath = getOuterPath(rect, textDirection: textDirection);

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5.w;

    canvas.drawPath(outerPath, paint);
  }

  @override
  ShapeBorder scale(double t) {
    return _AssetSelectorFieldCutOutShape(
      borderColor: borderColor,
      radius: radius * t,
    );
  }
}
