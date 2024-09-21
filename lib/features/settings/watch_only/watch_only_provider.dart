import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/settings/watch_only/watch_only_wallet.dart';

final watchOnlyProvider = FutureProvider<List<WatchOnlyWallet>>((ref) async {
  final bitcoinSubaccounts =
      await ref.watch(bitcoinProvider.select((p) => p.getSubaccounts()));
  final liquidSubaccounts =
      await ref.watch(liquidProvider.select((p) => p.getSubaccounts()));

  // NOTE: Until we have subaccounts feature, filter for native segwit for bitcoin and nested segwit for liquid
  final filteredBitcoinSubaccounts = bitcoinSubaccounts
          ?.where((subaccount) =>
              subaccount.type == GdkSubaccountTypeEnum.type_p2wpkh)
          .map((subaccount) => WatchOnlyWallet(
              subaccount: subaccount, networkType: NetworkType.bitcoin))
          .toList() ??
      [];

  final filteredLiquidSubaccounts = liquidSubaccounts
          ?.where((subaccount) =>
              subaccount.type == GdkSubaccountTypeEnum.type_p2sh_p2wpkh)
          .map((subaccount) => WatchOnlyWallet(
              subaccount: subaccount, networkType: NetworkType.liquid))
          .toList() ??
      [];

  return [...filteredBitcoinSubaccounts, ...filteredLiquidSubaccounts];
});
