import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/address_list/address_lists.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua/logger.dart';

final addressListProvider = AutoDisposeAsyncNotifierProviderFamily<
    AddressListNotifier, AddressLists, NetworkType>(AddressListNotifier.new);

class AddressListNotifier
    extends AutoDisposeFamilyAsyncNotifier<AddressLists, NetworkType> {
  late final NetworkType _networkType;

  // Gdk `getPreviousAddresses` loads 10 addresses per call, but only a few might be used.
  // This sets a min number of used addresses to load initially.
  static const int _minInitialUsedAddresses = 10;

  @override
  Future<AddressLists> build(NetworkType arg) async {
    _networkType = arg;
    logger.d('[Address] Building AddressListNotifier for $_networkType');
    return await _loadAddresses();
  }

  Future<AddressLists> _loadAddresses({
    int? lastPointer,
    List<GdkPreviousAddress> accumulatedUsed = const [],
    List<GdkPreviousAddress> accumulatedUnused = const [],
  }) async {
    final provider = _networkType == NetworkType.bitcoin
        ? ref.read(bitcoinProvider)
        : ref.read(liquidProvider);

    try {
      final result = await provider.getPreviousAddresses(
        details: GdkPreviousAddressesDetails(
          subaccount: provider.session.getSubAccount(),
          lastPointer: lastPointer,
        ),
      );

      if (result == null) {
        return AddressLists(
          usedAddresses: accumulatedUsed,
          unusedAddresses: accumulatedUnused,
        );
      }

      final addresses = result.$1;
      final newLastPointer = result.$2;

      logger.d('[Address] Total addresses received: ${addresses.length}');

      final usedAddresses =
          addresses.where((addr) => addr.txCount! > 0).toList();
      final unusedAddresses =
          addresses.where((addr) => addr.txCount == 0).toList();

      final allUsedAddresses = [...accumulatedUsed, ...usedAddresses];
      final allUnusedAddresses = [...accumulatedUnused, ...unusedAddresses];

      final hasMore = newLastPointer != null;

      if (allUsedAddresses.length < _minInitialUsedAddresses && hasMore) {
        return _loadAddresses(
          lastPointer: newLastPointer,
          accumulatedUsed: allUsedAddresses,
          accumulatedUnused: allUnusedAddresses,
        );
      }

      logger.d(
          '[Address] Final used addresses: ${allUsedAddresses.length}, Final unused addresses: ${allUnusedAddresses.length}');

      return AddressLists(
        usedAddresses: allUsedAddresses,
        unusedAddresses: allUnusedAddresses,
        lastPointer: newLastPointer,
        hasMore: hasMore,
      );
    } catch (e) {
      logger.e('[Address] Error loading addresses: $e');
      return Future.error(e);
    }
  }

  Future<void> refreshAddresses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadAddresses());
  }

  Future<bool> loadMoreAddresses() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) {
      return false;
    }

    final newAddresses =
        await _loadAddresses(lastPointer: currentState.lastPointer);

    logger.d(
        '[Address] New addresses loaded. Used: ${newAddresses.usedAddresses.length}, Unused: ${newAddresses.unusedAddresses.length}');

    state = AsyncValue.data(AddressLists(
      usedAddresses: [
        ...currentState.usedAddresses,
        ...newAddresses.usedAddresses
      ],
      unusedAddresses: [
        ...currentState.unusedAddresses,
        ...newAddresses.unusedAddresses
      ],
      lastPointer: newAddresses.lastPointer,
      hasMore: newAddresses.hasMore,
      searchQuery: currentState.searchQuery,
    ));

    return newAddresses.hasMore;
  }

  void search(String query) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(searchQuery: query));
  }

  List<GdkPreviousAddress> getFilteredAddresses(bool isUsed) {
    final currentState = state.value;
    if (currentState == null) return [];

    final addresses =
        isUsed ? currentState.usedAddresses : currentState.unusedAddresses;

    if (currentState.searchQuery.isEmpty) {
      return addresses;
    }

    final filteredAddresses = addresses
        .where((addr) =>
            addr.address
                ?.toLowerCase()
                .contains(currentState.searchQuery.toLowerCase()) ??
            false)
        .toList();

    logger.d('[Address] Filtered addresses: ${filteredAddresses.length}');

    return filteredAddresses;
  }
}
