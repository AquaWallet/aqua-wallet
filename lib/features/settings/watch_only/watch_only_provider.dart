import 'package:coin_cz/data/models/gdk_models.dart';
import 'package:coin_cz/data/provider/bitcoin_provider.dart';
import 'package:coin_cz/data/provider/liquid_provider.dart';
import 'package:coin_cz/data/provider/network_frontend.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/models/subaccount.dart';

class WatchOnlyNotifier extends AsyncNotifier<List<Subaccount>> {
  @override
  Future<List<Subaccount>> build() async {
    final bitcoinSubaccounts =
        await ref.read(bitcoinProvider.select((p) => p.getSubaccounts()));
    final liquidSubaccounts =
        await ref.read(liquidProvider.select((p) => p.getSubaccounts()));

    // TODO: Fix for new subaccounts feature
    final filteredBitcoinSubaccounts = bitcoinSubaccounts
            ?.where((subaccount) =>
                subaccount.type == GdkSubaccountTypeEnum.type_p2wpkh)
            .map((subaccount) => Subaccount(
                subaccount: subaccount, networkType: NetworkType.bitcoin))
            .toList() ??
        [];

    final filteredLiquidSubaccounts = liquidSubaccounts
            ?.where((subaccount) =>
                subaccount.type == GdkSubaccountTypeEnum.type_p2sh_p2wpkh)
            .map((subaccount) => Subaccount(
                subaccount: subaccount, networkType: NetworkType.liquid))
            .toList() ??
        [];

    return [...filteredBitcoinSubaccounts, ...filteredLiquidSubaccounts];
  }
}

final watchOnlyProvider =
    AsyncNotifierProvider<WatchOnlyNotifier, List<Subaccount>>(() {
  return WatchOnlyNotifier();
});
