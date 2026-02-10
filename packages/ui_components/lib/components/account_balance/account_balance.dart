import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaAccountBalance extends HookWidget {
  const AquaAccountBalance({
    super.key,
    required this.asset,
    this.title,
    this.amountWidget,
    this.onTap,
    this.colors,
  });

  final AssetUiModel asset;
  final String? title;
  final Widget? amountWidget;
  final Function(String?)? onTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call(asset.assetId))
            : null,
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AquaText.body2SemiBold(
                      text: title ?? 'Balance',
                      color: colors?.textSecondary,
                      height: 0,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        amountWidget ??
                            AquaText.h5SemiBold(
                              text: asset.amount,
                              color: colors?.textPrimary,
                              height: 0,
                            ),
                        const SizedBox(width: 4),
                        AquaText.h5SemiBold(
                          text: asset.subtitle,
                          color: colors?.textTertiary,
                          height: 1.45,
                        ),
                      ],
                    ),
                    if (asset.amountFiat != null) ...[
                      const SizedBox(height: 2),
                      AquaText.body2Medium(
                        text: asset.amountFiat!,
                        color: colors?.textSecondary,
                        height: 0,
                      ),
                    ],
                  ],
                ),
              ),
              switch (asset.assetId) {
                AssetIds.btc => AquaAssetIcon.bitcoin(size: 40),
                _ when (AssetIds.lbtc.contains(asset.assetId)) =>
                  AquaAssetIcon.liquidBitcoin(size: 40),
                AssetIds.lightning => AquaAssetIcon.lightningBtc(size: 40),
                AssetIds.usdtEth => AquaAssetIcon.usdtTether(size: 40),
                _ when (AssetIds.usdtliquid.contains(asset.assetId)) =>
                  AquaAssetIcon.usdtLiquid(size: 40),
                AssetIds.usdtTrx => AquaAssetIcon.usdtTron(size: 40),
                AssetIds.usdtBep => AquaAssetIcon.usdtBinance(size: 40),
                AssetIds.usdtSol => AquaAssetIcon.usdtSolana(size: 40),
                AssetIds.usdtTon => AquaAssetIcon.usdtTon(size: 40),
                AssetIds.layer2 => AquaAssetIcon.l2Bitcoin(size: 40),
                _ => const SizedBox.shrink(),
              }
            ],
          ),
        ),
      ),
    );
  }
}
