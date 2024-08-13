import 'dart:async';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

const liquidNetwork = 'liquid';
const bitcoinNetwork = 'bitcoin';
const btcId = 'btc-bitcoin';
const lbtcId = 'btc-liquid';
const usdtId = 'usdt-liquid';

final walletBalanceProvider = Provider.autoDispose(WalletBalanceProvider.new);

class WalletBalanceProvider {
  final AutoDisposeProviderRef ref;

  WalletBalanceProvider(this.ref);

  /// Fetches user balance for an asset
  Future<Decimal?> getWalletBalance(SideshiftAsset shiftAsset) async {
    final asset = _getAssetFor(shiftAsset);
    logger.d('[SideShift] Wallet Balance: ${asset?.amount} ${asset?.ticker}');

    if (asset == null) {
      return null;
    }

    final balance = DecimalExt.satsToDecimal(asset.amount, asset.precision);
    logger.d('[SideShift] wallet balance provider - Asset ($balance)');
    return balance;
  }

  _getAssetFor(SideshiftAsset shiftAsset) {
    final assets = ref.read(assetsProvider).asData?.value ?? [];
    return assets.firstWhereOrNull((e) {
      final isLbtc = e.isLBTC && shiftAsset.id == lbtcId;
      final isBtc = e.isBTC && shiftAsset.id == btcId;
      final isUsdt = e.isUSDt && shiftAsset.id == usdtId;
      return e.id == shiftAsset.coin || isLbtc || isBtc || isUsdt;
    });
  }
}
