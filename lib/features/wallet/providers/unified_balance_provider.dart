import 'dart:async';

import 'package:aqua/common/common.dart';
import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

final _logger = CustomLogger(FeatureFlag.unifiedBalance);

class WalletHeaderViewPrefKeys {
  static const walletHeaderView = 'wallet_header_view';
}

enum WalletHeaderView {
  price,
  balance;
}

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

final showUnifiedBalanceProvider =
    AsyncNotifierProvider<ShowUnifiedBalanceProvider, bool?>(
        ShowUnifiedBalanceProvider.new);

class ShowUnifiedBalanceProvider extends AsyncNotifier<bool?> {
  Timer? _timer;
  final completer = Completer<bool>();
  @override
  Future<bool?> build() async {
    if (completer.isCompleted) {
      return state.value;
    }

    final lastSavedView = ref
        .read(sharedPreferencesProvider)
        .getString(WalletHeaderViewPrefKeys.walletHeaderView);

    if (lastSavedView == WalletHeaderView.price.name) {
      completer.complete(false);
      return false;
    }

    // Set up 15 second timeout
    // if unified balance not available by then default to false
    _timer ??= Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    state = const AsyncValue.loading();

    final balance = ref.watch(unifiedBalanceProvider);

    if (balance != null) {
      final hasBalance = balance.decimal > Decimal.zero;
      _logger.debug("balance (${balance.decimal}) complete with $hasBalance");
      completer.complete(hasBalance);
    }

    return completer.future;
  }

  void show() {
    ref.read(sharedPreferencesProvider).setString(
          WalletHeaderViewPrefKeys.walletHeaderView,
          WalletHeaderView.balance.name,
        );
    state = const AsyncValue.data(true);
  }

  void hide() {
    ref.read(sharedPreferencesProvider).setString(
          WalletHeaderViewPrefKeys.walletHeaderView,
          WalletHeaderView.price.name,
        );
    state = const AsyncValue.data(false);
  }

  void toggle() {
    state.value == true ? hide() : show();
  }
}
