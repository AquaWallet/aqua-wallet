import 'package:coin_cz/data/models/gdk_models.dart';
import 'package:coin_cz/data/provider/bitcoin_provider.dart';
import 'package:coin_cz/data/provider/liquid_provider.dart';
import 'package:coin_cz/data/provider/network_frontend.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/models/shared_subaccount.dart';
import 'package:coin_cz/features/wallet/models/subaccount.dart';
import 'package:coin_cz/features/wallet/utils/derivation_path_utils.dart';
import 'package:coin_cz/features/wallet/providers/subaccounts_provider.dart';

final currentSharedSubaccountProvider =
    StateNotifierProvider<CurrentSharedSubaccountNotifier, SharedSubaccount?>(
        (ref) {
  return CurrentSharedSubaccountNotifier(ref);
});

class CurrentSharedSubaccountNotifier extends StateNotifier<SharedSubaccount?> {
  final Ref _ref;

  CurrentSharedSubaccountNotifier(this._ref) : super(null);

  /// Sets the current subaccount for both Bitcoin and Liquid at the same time
  /// The subaccount can be either for Bitcoin or Liquid, but the current subaccount will be set for both networks
  Future<void> setCurrentSharedSubaccount(Subaccount subaccount) async {
    final purpose = DerivationPathUtils.getPurposeFromUserPath(
        subaccount.subaccount.userPath ?? []);
    final account = DerivationPathUtils.getAccountFromUserPath(
        subaccount.subaccount.userPath ?? []);

    state = SharedSubaccount(purpose: purpose, account: account);

    final gdkSubaccountType = subaccount.subaccount.type;

    await _setSubaccountForNetwork(
      NetworkType.bitcoin,
      gdkSubaccountType!,
      account,
    );

    await _setSubaccountForNetwork(
      NetworkType.liquid,
      gdkSubaccountType,
      account,
    );

    await _ref.read(subaccountsProvider.notifier).loadSubaccounts();
  }

  Future<void> _setSubaccountForNetwork(NetworkType networkType,
      GdkSubaccountTypeEnum subaccountType, int account) async {
    final provider = networkType == NetworkType.bitcoin
        ? _ref.read(bitcoinProvider)
        : _ref.read(liquidProvider);

    final coinType = DerivationPathUtils.getCoinTypeForNetwork(networkType);

    final userPath = [
      DerivationPathUtils.hardenIndex(
          DerivationPathUtils.getPurposeForSubaccountType(subaccountType)),
      DerivationPathUtils.hardenIndex(coinType),
      DerivationPathUtils.hardenIndex(account),
    ];

    final subaccount = Subaccount(
      subaccount: GdkSubaccount(
        type: subaccountType,
        userPath: userPath,
      ),
      networkType: networkType,
    );

    await provider.setCurrentSubaccount(subaccount);
  }
}
