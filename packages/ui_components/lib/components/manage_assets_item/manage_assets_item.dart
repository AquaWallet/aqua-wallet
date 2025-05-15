import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaManageAssetsItem extends HookWidget {
  const AquaManageAssetsItem({
    super.key,
    required this.asset,
    this.onChange,
    this.colors,
    this.toggleable = true,
    required this.value,
  });

  final AssetUiModel asset;
  final bool toggleable;
  final bool value;
  final Function(bool selected)? onChange;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const ContinuousRectangleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Ink(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AquaAssetIcon.fromAssetId(
                assetId: asset.assetId,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AquaText.body1SemiBold(
                      text: asset.name,
                      color: colors?.textPrimary,
                    ),
                    const SizedBox(height: 4),
                    AquaText.body2Medium(
                      text: asset.subtitle,
                      color: colors?.textSecondary,
                    ),
                  ],
                ),
              ),
              if (toggleable) ...{
                AquaToggle(
                  value: value,
                  onChanged: onChange,
                ),
              },
              const SizedBox(width: 16),
              AquaIcon.grab(
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
