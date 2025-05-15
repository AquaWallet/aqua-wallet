import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaAssetSelectorContent extends StatelessWidget {
  const AquaAssetSelectorContent({
    super.key,
    required this.selectedAssetId,
    required this.assets,
    required this.renderBox,
    required this.availableHeight,
    required this.onAssetSelected,
    required this.overlayEntry,
    required this.colors,
  });

  final String selectedAssetId;
  final List<AssetUiModel> assets;
  final RenderBox renderBox;
  final double availableHeight;
  final Function(String assetId)? onAssetSelected;
  final ValueNotifier<OverlayEntry?> overlayEntry;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: renderBox.size.width,
          maxHeight: availableHeight - 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, asset) in assets.indexed) ...{
              AquaAccountItem(
                asset: asset,
                colors: colors,
                selected: selectedAssetId == asset.assetId,
                onTap: (assetId) {
                  if (assetId == null) return;
                  onAssetSelected?.call(assetId);
                  overlayEntry.value?.remove();
                  overlayEntry.value = null;
                },
              ),
              if (index != assets.length - 1) ...{
                Divider(
                  height: 1,
                  color: colors?.surfaceSecondary,
                ),
              },
            }
          ],
        ),
      ),
    );
  }
}
