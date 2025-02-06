import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/wallet/models/subaccount_exceptions.dart';
import 'package:aqua/features/wallet/utils/derivation_path_utils.dart';
import 'package:aqua/features/wallet/models/subaccount.dart';
import 'package:aqua/features/wallet/models/subaccounts.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

enum SortCriteria { name, balance, type }

final subaccountsProvider =
    AsyncNotifierProvider<SubaccountsNotifier, Subaccounts>(
        SubaccountsNotifier.new);

class SubaccountsNotifier extends AsyncNotifier<Subaccounts> {
  @override
  Future<Subaccounts> build() async {
    logger.debug("[Subaccounts] Initializing SubaccountsNotifier");
    return const Subaccounts();
  }

  //TODO: WARNING: Need to verify how GDK fetches multiple subaccounts. Does it go down the Account path for each CoinType, first looking at Account index 0, checking if first 20 addresses have coins,
  //  and only if yes, then checking Account index 1, and so on?
  Future<void> loadSubaccounts() async {
    logger.debug("[Subaccounts] Loading subaccounts");

    final newState = await AsyncValue.guard(() async {
      final bitcoinSubaccounts =
          await ref.read(bitcoinProvider).getSubaccounts();
      final liquidSubaccounts = await ref.read(liquidProvider).getSubaccounts();

      await _logSubaccountsInfo(bitcoinSubaccounts, liquidSubaccounts);

      final allSubaccounts = [
        ...?bitcoinSubaccounts?.map(
            (s) => Subaccount(subaccount: s, networkType: NetworkType.bitcoin)),
        ...?liquidSubaccounts?.map(
            (s) => Subaccount(subaccount: s, networkType: NetworkType.liquid)),
      ];

      return Subaccounts(subaccounts: allSubaccounts);
    });

    // only update the state if it's different from the current state
    state = state.whenData((currentState) {
      if (newState.hasValue &&
          !_areSubaccountsEqual(
              currentState.subaccounts, newState.value!.subaccounts)) {
        return newState.value!;
      }
      return currentState;
    });
  }

  bool _areSubaccountsEqual(List<Subaccount> list1, List<Subaccount> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].subaccount != list2[i].subaccount ||
          list1[i].networkType != list2[i].networkType) {
        return false;
      }
    }
    return true;
  }

  //TODO: WARNING: We need to think about better ways to safeguard a user creating too many subaccounts.
  //  Maybe we don't let a user create a new subaccount if they already have X subaccounts without transactions?
  Future<void> createSubaccount(
      GdkSubaccount newSubaccount, NetworkType networkType) async {
    logger.debug("[Subaccounts] Creating new subaccount for $networkType");

    final provider = networkType == NetworkType.bitcoin
        ? ref.read(bitcoinProvider)
        : ref.read(liquidProvider);

    await provider.createSubaccount(details: newSubaccount);
    logger.debug("[Subaccounts] Subaccount created, refreshing subaccounts");
    return await _refreshSubaccounts();
  }

  Future<void> updateSubaccount(
      GdkSubaccountUpdate updateDetails, NetworkType networkType) async {
    if (isMainAccount(updateDetails.subaccount, networkType)) {
      throw SubaccountUpdateMainAccountNameException();
    }

    logger.debug(
        "[Subaccounts] Updating subaccount ${updateDetails.subaccount} for $networkType");

    final provider = networkType == NetworkType.bitcoin
        ? ref.read(bitcoinProvider)
        : ref.read(liquidProvider);

    await provider.updateSubaccount(details: updateDetails);
    logger.debug("[Subaccounts] Subaccount updated, refreshing subaccounts");
    return await _refreshSubaccounts();
  }

  void sortSubaccounts(SortCriteria criteria) {
    state = state.whenData((currentState) {
      final sortedSubaccounts = List<Subaccount>.from(currentState.subaccounts);
      switch (criteria) {
        case SortCriteria.name:
          sortedSubaccounts.sort((a, b) {
            final nameA = a.subaccount.name;
            final nameB = b.subaccount.name;
            if (nameA == null && nameB == null) return 0;
            if (nameA == null) return -1;
            if (nameB == null) return 1;
            return nameA.compareTo(nameB);
          });
          break;
        case SortCriteria.balance:
          logger.error("[Subaccounts] Balance sorting not implemented yet");
          break;
        case SortCriteria.type:
          sortedSubaccounts.sort((a, b) => a.subaccount.type
              .toString()
              .compareTo(b.subaccount.type.toString()));
          break;
      }
      return currentState.copyWith(subaccounts: sortedSubaccounts);
    });
  }

  bool isMainAccount(int subaccountPointer, NetworkType networkType) {
    final subaccount = state.value?.subaccounts.firstWhere(
      (s) => s.subaccount.pointer == subaccountPointer,
      orElse: () => throw SubaccountNotFoundException(),
    );

    final isNativeSegwit =
        subaccount!.subaccount.type == GdkSubaccountTypeEnum.type_p2wpkh;
    final isAccountIndexZero = subaccount.subaccount.userPath != null &&
        subaccount.subaccount.userPath!.length > 2 &&
        DerivationPathUtils.unhardenIndex(subaccount.subaccount.userPath![2]) ==
            0;

    return isNativeSegwit && isAccountIndexZero;
  }

  Subaccount? getSubaccountById(int id) {
    final subaccount = state.value?.subaccounts
        .firstWhereOrNull((s) => s.subaccount.pointer == id);
    logger.debug(
        "[Subaccounts] Subaccount ${subaccount != null ? 'found' : 'not found'}");
    return subaccount;
  }

  List<Subaccount> getVisibleSubaccounts() {
    final visibleSubaccounts =
        state.value?.subaccounts.where((s) => !s.subaccount.hidden).toList() ??
            [];
    logger.debug(
        "[Subaccounts] Found ${visibleSubaccounts.length} visible subaccounts");
    return visibleSubaccounts;
  }

  Future<void> _refreshSubaccounts() async {
    final newState = await AsyncValue.guard(() async {
      final bitcoinSubaccounts =
          await ref.read(bitcoinProvider).getSubaccounts();
      final liquidSubaccounts = await ref.read(liquidProvider).getSubaccounts();

      final allSubaccounts = [
        ...?bitcoinSubaccounts?.map(
            (s) => Subaccount(subaccount: s, networkType: NetworkType.bitcoin)),
        ...?liquidSubaccounts?.map(
            (s) => Subaccount(subaccount: s, networkType: NetworkType.liquid)),
      ];

      logger.debug(
          "[Subaccounts] Refreshed ${allSubaccounts.length} total subaccounts");
      return Subaccounts(subaccounts: allSubaccounts);
    });

    state = state.whenData((currentState) {
      if (newState.hasValue &&
          !_areSubaccountsEqual(
              currentState.subaccounts, newState.value!.subaccounts)) {
        return newState.value!;
      }
      return currentState;
    });
  }

  //ANCHOR: Native Segwit Liquid Subaccount
  Future<void> createNativeSegwitLiquidSubaccount() async {
    await createSubaccount(
      GdkSubaccount(
        name: "Liquid ${GdkSubaccountTypeEnum.type_p2wpkh.typeName}",
        type: GdkSubaccountTypeEnum.type_p2wpkh,
      ),
      NetworkType.liquid,
    );
    return await _refreshSubaccounts();
  }

  //ANCHOR: Create "Account" Subaccounts

  /// Create a subaccount with a specific derivation path for a given network and type.
  ///
  /// This method calculates the coin type based on the network type and retrieves
  /// the next available account index. It then constructs the derivation path
  /// and creates the subaccount with the specified details.
  ///
  /// Parameters:
  /// - [networkType]: The type of network for which the subaccount is created.
  /// - [type]: The type of subaccount to create.
  Future<void> createAccountSubaccount({
    required NetworkType networkType,
    GdkSubaccountTypeEnum type = GdkSubaccountTypeEnum.type_p2wpkh,
  }) async {
    final purpose = DerivationPathUtils.getPurposeForSubaccountType(type);
    final coinType = DerivationPathUtils.getCoinTypeForNetwork(networkType);
    final accountIndex = getNextAccountIndex(networkType, type);

    final userPath = [
      DerivationPathUtils.hardenIndex(purpose),
      DerivationPathUtils.hardenIndex(coinType),
      DerivationPathUtils.hardenIndex(accountIndex)
    ];

    await createSubaccount(
      GdkSubaccount(
        type: type,
        userPath: userPath,
        name: "Account ${accountIndex + 1}",
      ),
      networkType,
    );

    await _refreshSubaccounts();
  }

  int getNextAccountIndex(NetworkType networkType, GdkSubaccountTypeEnum type) {
    final purpose = DerivationPathUtils.getPurposeForSubaccountType(type);
    final coinType = DerivationPathUtils.getCoinTypeForNetwork(networkType);

    final existingSubaccounts = state.value?.subaccounts
            .where((s) => s.networkType == networkType)
            .where((s) =>
                s.subaccount.userPath != null &&
                s.subaccount.userPath!.length >= 3)
            .where((s) =>
                s.subaccount.userPath![DerivPathLevel.purpose.level] ==
                    DerivationPathUtils.hardenIndex(purpose) &&
                s.subaccount.userPath![DerivPathLevel.coinType.level] ==
                    DerivationPathUtils.hardenIndex(coinType))
            .toList() ??
        [];

    if (existingSubaccounts.isEmpty) {
      return 0;
    }

    final maxAccountIndex = existingSubaccounts
        .map((s) => DerivationPathUtils.unhardenIndex(
            s.subaccount.userPath![DerivPathLevel.account.level]))
        .reduce((max, current) => current > max ? current : max);

    return maxAccountIndex + 1;
  }

  //ANCHOR: Logging
  Future<void> _logSubaccountsInfo(List<GdkSubaccount>? bitcoinSubaccounts,
      List<GdkSubaccount>? liquidSubaccounts) async {
    logger.debug(
        "[Subaccounts] Loaded ${bitcoinSubaccounts?.length ?? 0} Bitcoin subaccounts and ${liquidSubaccounts?.length ?? 0} Liquid subaccounts");

    await _logSubaccountsDetails(bitcoinSubaccounts, NetworkType.bitcoin);
    await _logSubaccountsDetails(liquidSubaccounts, NetworkType.liquid);
  }

  Future<void> _logSubaccountsDetails(
      List<GdkSubaccount>? subaccounts, NetworkType networkType) async {
    if (subaccounts == null) return;

    final provider = networkType == NetworkType.bitcoin
        ? ref.read(bitcoinProvider)
        : ref.read(liquidProvider);

    for (final subaccount in subaccounts) {
      final path =
          DerivationPathUtils.formatDerivationPath(subaccount.userPath);
      final txs =
          await _getSubaccountFirstThirtyTransactions(subaccount, provider);
      logger.debug(
          "[Subaccounts] --- $path ($networkType) - Transactions: ${txs.length >= 30 ? '>=30' : txs.length}");
    }
  }

  // NOTE: Working, call can be modified to get full list of txs with paging
  Future<List<GdkTransaction>> _getSubaccountFirstThirtyTransactions(
      GdkSubaccount subaccount, dynamic provider) async {
    try {
      final transactions = await provider.getTransactions(
        requiresRefresh: true,
        details: GdkGetTransactionsDetails(
          subaccount: subaccount.pointer,
          count: 30,
        ),
      );
      logger.debug("[Subaccounts] --- Transactions: ${transactions.length}");
      return transactions;
    } catch (e) {
      logger.error("[Subaccounts] Error fetching transaction count: $e");
      return [];
    }
  }

  //ANCHOR: Debugging (will be removed)
  Future<int> getSubaccountTransactionCount(Subaccount subaccount) async {
    final provider = subaccount.networkType == NetworkType.bitcoin
        ? ref.read(bitcoinProvider)
        : ref.read(liquidProvider);

    try {
      final transactions = await provider.getTransactions(
        requiresRefresh: true,
        details: GdkGetTransactionsDetails(
          subaccount: subaccount.subaccount.pointer,
          count: 30,
        ),
      );
      return transactions?.length ?? 0;
    } catch (e) {
      logger.error("[Subaccounts] Error fetching transaction count: $e");
      return 0;
    }
  }
}
