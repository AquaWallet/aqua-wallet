import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/shared/shared.dart';
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
  });

  const AquaAssetSelector.receive({
    super.key,
    this.type = AquaAssetSelectorType.receive,
    required this.assets,
    this.onAssetSelected,
    this.selectedAssetId,
    this.colors,
  });

  final AquaAssetSelectorType type;
  final Map<AssetUiModel, List<AssetUiModel>> assets;
  final Function(String?)? onAssetSelected;
  final String? selectedAssetId;
  final AquaColors? colors;

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
                          ? context.loc.tapForOptions
                          : parentAsset._getSubtitle(context, type),
                    ),
                    showBalance: type == AquaAssetSelectorType.send,
                    shape: const ContinuousRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
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
                  if (childAssets.isNotEmpty)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        height: isExpanded ? null : 0,
                        child: AnimatedOpacity(
                          opacity: isExpanded ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: childAssets
                                .mapIndexed(
                                    (index, asset) => _ChildAssetListItem(
                                          asset: asset,
                                          colors: colors,
                                          index: index,
                                          type: type,
                                          length: childAssets.length,
                                          onTap: (assetId) {
                                            onAssetSelected?.call(assetId);
                                          },
                                        ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (index < assets.length - 1) ...{
                Divider(
                  height: 1,
                  color: colors?.surfaceBorderSecondary,
                )
              },
            ],
          );
        },
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
  });

  final AssetUiModel asset;
  final AquaColors? colors;
  final Function(String?)? onTap;
  final AquaAssetSelectorType type;
  final int index;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const ContinuousRectangleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () => onTap?.call(asset.assetId),
        splashFactory: NoSplash.splashFactory,
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
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AquaText.body2SemiBold(
                      text: asset.name,
                      color: colors?.textPrimary,
                    ),
                    const SizedBox(height: 2),
                    AquaText.caption1Medium(
                      text: asset._getSubtitle(context, type),
                      color: colors?.textSecondary,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AquaText.body2SemiBold(
                    text: asset.amount,
                    color: colors?.textPrimary,
                  ),
                  const SizedBox(height: 2),
                  AquaText.caption1Medium(
                    text: asset.amountFiat ?? '',
                    color: colors?.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on AssetUiModel {
  String _getSubtitle(BuildContext context, AquaAssetSelectorType type) {
    return switch (assetId) {
      AssetIds.btc => context.loc.onChain,
      AssetIds.lightning => context.loc.swappedToLBtc,
      AssetIds.lightning when (type == AquaAssetSelectorType.send) =>
        context.loc.swappedFromLBtc,
      _ when (AssetIds.usdtliquid.contains(assetId)) => context.loc.lUsdt,
      _ when (AssetIds.lbtc.contains(assetId)) => context.loc.lBtc,
      _ when (type == AquaAssetSelectorType.receive) =>
        context.loc.swappedToLUsdt,
      _ => context.loc.swappedFromLUsdt,
    };
  }
}
