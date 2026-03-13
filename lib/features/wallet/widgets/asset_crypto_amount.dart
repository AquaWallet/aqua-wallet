import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AssetCryptoAmount extends HookConsumerWidget {
  const AssetCryptoAmount({
    super.key,
    this.asset,
    this.style,
    this.unitStyle,
    this.amount,
    this.isLoading = false,
    this.showUnit = true,
    this.forceDisplayUnit,
    this.forceVisible = false,
    this.usdtPrecisionOverride = kUsdtDisplayPrecision,
  });

  final Asset? asset;
  final TextStyle? style;
  final TextStyle? unitStyle;
  final String? amount;
  final bool isLoading;
  final bool showUnit;
  final SupportedDisplayUnits? forceDisplayUnit;
  final bool forceVisible;
  final int usdtPrecisionOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsset = asset;
    final isBalanceHidden = forceVisible == true
        ? false
        : ref.watch(prefsProvider.select((p) => p.isBalanceHidden));

    final defaultStyle = style ??
        Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.bold);

    // Handle loading state
    if (isLoading) {
      return Text('-', textAlign: TextAlign.end, style: defaultStyle);
    }

    // Handle hidden balance
    if (isBalanceHidden) {
      return Opacity(
        opacity: 0.5,
        child: Text(
          hiddenBalancePlaceholder,
          textAlign: TextAlign.end,
          style: style ??
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
        ),
      );
    }

    // Handle fiat display mode (no asset)
    if (currentAsset == null) {
      return Text(
        amount ?? 'Err',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        textDirection: TextDirection.ltr,
        style: defaultStyle,
      );
    }

    // Get display unit and precision for crypto asset
    final shownDisplayUnit = forceDisplayUnit ??
        ref.watch(displayUnitsProvider.select((p) => p.currentDisplayUnit));

    final assetPrecision = useMemoized(() {
      return currentAsset.isNonSatsAsset || currentAsset.isLightning
          ? currentAsset.precision
          : currentAsset.precision - shownDisplayUnit!.logDiffToBtc;
    }, [currentAsset, shownDisplayUnit]);

    final formatter = ref.read(formatProvider);

    // Format the amount using the formatter provider
    final formattedAmount = formatter.formatAssetAmount(
      amount: int.tryParse(amount ?? '') ?? currentAsset.amount,
      decimalPlacesOverride: currentAsset.isNonSatsAsset
          ? (usdtPrecisionOverride)
          : assetPrecision.clamp(0, 8),
      removeTrailingZeros: false,
      asset: currentAsset,
      displayUnitOverride: forceDisplayUnit,
    );

    // Build the rich text display with unit if needed
    return Text.rich(
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      TextSpan(
        children: [
          TextSpan(
            text: formattedAmount,
            style: defaultStyle,
          ),
          if (showUnit) ...[
            TextSpan(
              text:
                  ' ${ref.watch(displayUnitsProvider.select((p) => p.getAssetDisplayUnit(currentAsset, forcedDisplayUnit: forceDisplayUnit)))}',
              style: unitStyle ??
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AquaColors.dimMarble,
                      ),
            )
          ],
        ],
      ),
    );
  }
}
