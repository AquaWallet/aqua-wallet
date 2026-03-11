import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/wallet/wallet.dart';

class WatchOnlyNotifier extends AsyncNotifier<List<Subaccount>> {
  @override
  Future<List<Subaccount>> build() async {
    ref.watch(
        storedWalletsProvider.select((s) => s.valueOrNull?.currentWallet));

    final bitcoinSubaccounts = await ref.read(bitcoinProvider).getSubaccounts();
    final liquidSubaccounts = await ref.read(liquidProvider).getSubaccounts();

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
