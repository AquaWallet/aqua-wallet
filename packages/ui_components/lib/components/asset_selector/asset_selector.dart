import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

enum AquaAssetSelectorType {
  send,
  receive,
}

class AquaAssetSelector extends HookWidget {
  const AquaAssetSelector.send({
    super.key,
    this.type = AquaAssetSelectorType.send,
    required this.assets,
    this.onAssetSelected,
    this.selectedAssetId,
    this.colors,
    this.trailingWidget,
    this.tapForOptionsText,
  });

  const AquaAssetSelector.receive({
    super.key,
    this.type = AquaAssetSelectorType.receive,
    required this.assets,
    this.onAssetSelected,
    this.selectedAssetId,
    this.colors,
    this.trailingWidget,
    this.tapForOptionsText,
  });

  final AquaAssetSelectorType type;
  final Map<AssetUiModel, List<AssetUiModel>> assets;
  final Function(String?)? onAssetSelected;
  final String? selectedAssetId;
  final AquaColors? colors;
  final Widget? trailingWidget;
  final String? tapForOptionsText;

  @override
  Widget build(BuildContext context) {
    final expandedStates = useState<Set<String>>({});

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final parentAsset = assets.keys.elementAt(index);
          final childAssets = assets[parentAsset] ?? [];
          final isExpanded = expandedStates.value.contains(parentAsset.assetId);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AquaAccountItem(
                    asset: parentAsset.copyWith(
                      subtitle: childAssets.isNotEmpty
                          ? (tapForOptionsText ?? parentAsset.subtitle)
                          : parentAsset.subtitle,
                    ),
                    showBalance: trailingWidget != null ||
                        type == AquaAssetSelectorType.send,
                    cryptoAmountItem: trailingWidget,
                    shape: const ContinuousRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    selected: childAssets.isNotEmpty
                        ? (childAssets.isNotEmpty && isExpanded)
                        : null,
                    colors: colors,
                    onTap: (assetId) {
                      if (childAssets.isNotEmpty) {
                        // For parent items with children, toggle expansion and selection
                        if (isExpanded) {
                          expandedStates.value = Set.from(expandedStates.value)
                            ..remove(parentAsset.assetId);
                          onAssetSelected?.call(null);
                        } else {
                          expandedStates.value = Set.from(expandedStates.value)
                            ..add(parentAsset.assetId);
                          onAssetSelected?.call(parentAsset.assetId);
                        }
                      } else {
                        // For parent items without children, collapse any expanded items
                        expandedStates.value = {};
                        onAssetSelected?.call(parentAsset.assetId);
                      }
                    },
                  ),
                  if (childAssets.isNotEmpty) ...{
                    _ExpandableChildList(
                      isExpanded: isExpanded,
                      childAssets: childAssets,
                      type: type,
                      colors: colors,
                      onAssetSelected: onAssetSelected,
                      trailingWidget: trailingWidget,
                    ),
                  },
                ],
              ),
              if (index < assets.length - 1) ...{
                const SizedBox(height: 1),
              },
            ],
          );
        },
      ),
    );
  }
}

class _ExpandableChildList extends HookWidget {
  const _ExpandableChildList({
    required this.isExpanded,
    required this.childAssets,
    required this.type,
    this.colors,
    this.onAssetSelected,
    this.trailingWidget,
  });

  final bool isExpanded;
  final List<AssetUiModel> childAssets;
  final AquaAssetSelectorType type;
  final AquaColors? colors;
  final Function(String?)? onAssetSelected;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 250),
    );

    useEffect(() {
      if (isExpanded) {
        controller.forward();
      } else {
        controller.reverse();
      }
      return null;
    }, [isExpanded]);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    return ClipRect(
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: childAssets
              .mapIndexed((index, asset) => _ChildAssetListItem(
                    asset: asset,
                    colors: colors,
                    index: index,
                    type: type,
                    length: childAssets.length,
                    trailingWidget: trailingWidget,
                    onTap: (assetId) {
                      onAssetSelected?.call(assetId);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ChildAssetListItem extends StatelessWidget {
  const _ChildAssetListItem({
    required this.asset,
    required this.index,
    required this.length,
    required this.type,
    this.colors,
    this.onTap,
    this.trailingWidget,
  });

  final AssetUiModel asset;
  final AquaColors? colors;
  final Function(String?)? onTap;
  final AquaAssetSelectorType type;
  final int index;
  final int length;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final subtitle = (asset.subtitle ?? '').trim();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const ContinuousRectangleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call(asset.assetId))
            : null,
        splashFactory: InkRipple.splashFactory,
        highlightColor: Theme.of(context).highlightColor,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 64,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 1,
                        color: index == 0
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(4),
                      child: AquaAssetIcon.fromAssetId(
                        assetId: asset.assetId,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 1,
                        color: index == length - 1
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 🔥 Force the text block to fill the same height and center its contents
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AquaText.body2SemiBold(
                            text: asset.name,
                            color: colors?.textPrimary,
                          ),
                          if (asset.standard != null) ...[
                            const SizedBox(width: 4),
                            AquaText.caption2SemiBold(
                              text: "(${asset.standard!})",
                              color: colors?.textSecondary,
                            ),
                          ]
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AquaText.caption1Medium(
                          text: subtitle,
                          color: colors?.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailingWidget != null) trailingWidget!,
            ],
          ),
        ),
      ),
    );
  }
}