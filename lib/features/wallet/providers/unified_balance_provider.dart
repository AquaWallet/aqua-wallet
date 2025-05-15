import 'package:aqua/common/common.dart';
import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

class UnifiedBalanceResult {
  final Decimal decimal;
  final String formatted;

  UnifiedBalanceResult({required this.decimal, required this.formatted});
}

final unifiedBalanceProvider = Provider<UnifiedBalanceResult?>((ref) {
  final fiatRates = ref.watch(fiatRatesProvider).asData?.value;
  final allAssets = ref.watch(assetsProvider).asData?.value;

  if (fiatRates == null || allAssets == null) {
    return null;
  }

  final referenceCurrency = ref
      .watch(exchangeRatesProvider.select((p) => p.currentCurrency))
      .currency
      .value;

  final convertedBalances = allAssets
      .where((asset) => asset.isBTC || asset.isLBTC)
      .map((asset) =>
          ref.watch(conversionProvider((asset, asset.amount)))?.decimal);

  if (!convertedBalances.any((el) => el != null)) {
    return null;
  }

  final usdtBalanceInDecimal =
      allAssets.where((asset) => asset.isUSDt).map((asset) {
    return (Decimal.fromInt(asset.amount) /
        DecimalExt.fromAssetPrecision(asset.precision));
  }).firstOrNull;
  final usdRate =
      fiatRates.firstWhereOrNull((element) => element.code == 'USD')?.rate;

  final usdtBalanceInSats = usdRate != null && usdtBalanceInDecimal != null
      ? (usdtBalanceInDecimal.toDouble() / usdRate) * satsPerBtc
      : 0;

  final usdtBalanceInSelectedCurrency = referenceCurrency ==
          FiatCurrency.usd.value
      ? usdtBalanceInDecimal?.toDecimal()
      : ref
          .watch(conversionProvider((Asset.btc(), usdtBalanceInSats.toInt())))
          ?.decimal;

  final unifiedBalance = [...convertedBalances, usdtBalanceInSelectedCurrency]
      .where((e) => e != null)
      .fold(Decimal.zero, (val, el) => val + el!);

  return UnifiedBalanceResult(
      decimal: unifiedBalance,
      formatted: ref.read(fiatProvider).formattedFiat(unifiedBalance));
});
