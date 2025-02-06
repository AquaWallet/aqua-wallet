import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
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
  });

  final Asset? asset;
  final TextStyle? style;
  final TextStyle? unitStyle;
  final String? amount;
  final bool isLoading;
  final bool showUnit;
  final SupportedDisplayUnits? forceDisplayUnit;
  final bool forceVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsset = asset;
    final isBalanceHidden = forceVisible == true
        ? false
        : ref.watch(prefsProvider.select((p) => p.isBalanceHidden));
    if (isLoading) {
      return Text(
        '-',
        textAlign: TextAlign.end,
        style: style ??
            Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
      );
    }
    if (isBalanceHidden) {
      return Text(
        hiddenBalancePlaceholder,
        textAlign: TextAlign.end,
        style: style ??
            Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
      );
    }
    if (currentAsset == null) {
      // Asset is Fiat
      return Text(
        amount ?? 'Err',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: style ??
            Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
      );
    }
    final shownDisplayUnit = forceDisplayUnit ??
        ref.watch(displayUnitsProvider.select((p) => p.currentDisplayUnit));
    final assetPrecision = useMemoized(() {
      return currentAsset.isNonSatsAsset || currentAsset.isLightning
          ? currentAsset.precision
          : currentAsset.precision - shownDisplayUnit!.logDiffToBtc;
    }, [currentAsset, shownDisplayUnit]);
    final amountStr = ref.watch(formatterProvider).formatAssetAmountDirect(
          amount: int.tryParse(amount ?? '') ?? currentAsset.amount,
          precision: assetPrecision,
          roundingOverride: currentAsset.isAnyUsdt
              ? kUsdtDisplayPrecision
              : assetPrecision.clamp(0, 8),
          removeTrailingZeros: false,
        );

    return Text.rich(
      textAlign: TextAlign.end,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      TextSpan(
        children: [
          TextSpan(
            text: amountStr,
            style: style ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
          ),
          if (showUnit) ...[
            TextSpan(
              text:
                  ' ${ref.watch(displayUnitsProvider.select((p) => p.getAssetDisplayUnit(currentAsset, forcedDisplayUnit: forceDisplayUnit)))}',
              style: unitStyle ??
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: AquaColors.dimMarble),
            )
          ],
        ],
      ),
    );
  }
}
