import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaAccountItem extends HookWidget {
  const AquaAccountItem({
    super.key,
    required this.asset,
    this.textColorTitle,
    this.textColorSubtitle,
    this.selected,
    this.padding,
    this.colors,
    this.onTap,
    this.shape,
    this.cryptoAmountItem,
    this.fiatAmountItem,
    this.showBalance = true,
  });

  final AssetUiModel asset;
  final Color? textColorTitle;
  final Color? textColorSubtitle;
  final bool? selected;
  final AquaColors? colors;
  final EdgeInsets? padding;
  final Function(String?)? onTap;
  final ShapeBorder? shape;
  final bool showBalance;
  final Widget? cryptoAmountItem;
  final Widget? fiatAmountItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
      child: InkWell(
        onTap: () => onTap?.call(asset.assetId),
        splashFactory: NoSplash.splashFactory,
        highlightColor: selected == null
            ? Theme.of(context).highlightColor
            : Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(4),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected == true ? colors?.surfaceSelected : null,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: selected == true
                    ? colors?.surfaceBorderSelected ?? Colors.transparent
                    : Colors.transparent,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (asset.isRemoteIcon) ...{
                  AquaAssetIcon.fromUrl(
                    url: asset.iconUrl!,
                    size: 40,
                  )
                } else ...{
                  AquaAssetIcon.fromAssetId(
                    assetId: asset.assetId,
                    size: 40,
                  )
                },
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AquaText.body1SemiBold(
                        text: asset.name,
                        color: textColorTitle ?? colors?.textPrimary,
                      ),
                      const SizedBox(height: 4),
                      AquaText.body2Medium(
                        text: asset.subtitle,
                        color: textColorSubtitle ?? colors?.textSecondary,
                      ),
                    ],
                  ),
                ),
                if (showBalance) ...{
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      cryptoAmountItem ??
                          AquaText.body1SemiBold(
                            text: asset.amount,
                            color: textColorTitle ?? colors?.textPrimary,
                          ),
                      const SizedBox(height: 4),
                      fiatAmountItem ??
                          AquaText.body2Medium(
                            text: asset.amountFiat ?? '',
                            color: textColorSubtitle ?? colors?.textSecondary,
                          ),
                    ],
                  ),
                }
              ],
            ),
          ),
        ),
      ),
    );
  }
}
