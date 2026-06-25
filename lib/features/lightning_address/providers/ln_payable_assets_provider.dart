import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';

typedef LnPayableAssetData = ({
  Asset asset,
  String amountCrypto,
  String? amountFiat,
  String displayUnit,
});

final lnPayableAssetsProvider =
    Provider.autoDispose<List<LnPayableAssetData>>((ref) {
  final userAssets = ref.watch(assetsProvider).valueOrNull ?? [];
  final displayUnit =
      ref.read(displayUnitsProvider.select((p) => p.currentDisplayUnit));

  return userAssets
      .where((a) => a.isLBTC || a.isUsdtLiquid)
      .map((asset) => (
            asset: asset,
            amountCrypto: ref.read(formatProvider).formatAssetAmount(
                  amount: asset.amount,
                  asset: asset,
                  removeTrailingZeros: false,
                  displayUnitOverride: displayUnit,
                  decimalPlacesOverride: asset.isAnyUsdt
                      ? kUsdtDisplayPrecision
                      : asset.precision.clamp(0, kMaxAssetDisplayPrecision),
                ),
            amountFiat: ref
                .read(conversionProvider((asset, asset.amount)))
                ?.formattedWithCurrency,
            displayUnit: displayUnit.value,
          ))
      .toList();
});
