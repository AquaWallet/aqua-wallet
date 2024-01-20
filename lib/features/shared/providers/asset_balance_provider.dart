import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'asset_balance_provider.g.dart';

// Future Providers
@riverpod
Future<int> getBalance(GetBalanceRef ref, Asset asset) async {
  return await ref.read(balanceProvider).getBalance(asset);
}

@riverpod
Future<int> getLBTCBalance(GetLBTCBalanceRef ref) async {
  return await ref.read(balanceProvider).getBalance(Asset.liquid());
}

@riverpod
Future<int> getBitcoinBalance(GetBitcoinBalanceRef ref) async {
  return await ref.read(balanceProvider).getBalance(Asset.btc());
}

// Main Provider
final balanceProvider = Provider.autoDispose((ref) => BalanceService(ref));

class BalanceService {
  final ProviderRef _ref;

  BalanceService(this._ref);

  Future<int> getBalance(Asset asset) async {
    if (asset.isBTC) {
      return getBitcoinBalance();
    }

    if (asset.isLightning || asset.isLBTC) {
      return getLBTCBalance();
    }

    final balances = await _ref.read(liquidProvider).getBalance();

    if (asset == Asset.usdtEth() || asset == Asset.usdtTrx()) {
      return balances?[_ref.read(liquidProvider).usdtId] as int? ?? 0;
    }

    return balances?[asset.id] as int? ?? 0;
  }

  Future<int> getLBTCBalance() async {
    final balances = await _ref.read(liquidProvider).getBalance();
    final lbtcId = _ref.read(liquidProvider).lbtcId;
    return balances?[lbtcId] as int? ?? 0;
  }

  Future<int> getBitcoinBalance() async {
    final balances = await _ref.read(bitcoinProvider).getBalance();
    return balances?['btc'] as int? ?? 0;
  }
}
