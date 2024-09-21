import 'dart:async';

import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:async/async.dart';

final assetsProvider =
    AsyncNotifierProvider.autoDispose<AssetsNotifier, List<Asset>>(
        AssetsNotifier.new);

class AssetsNotifier extends AutoDisposeAsyncNotifier<List<Asset>> {
  final _reloadAssetsController = StreamController<void>();

  @override
  FutureOr<List<Asset>> build() async {
    ref.keepAlive();
    state = const AsyncValue.loading();
    await for (final assets in stream) {
      if (assets.isEmpty) continue;
      state = AsyncValue.data(assets);
    }
    return [];
  }

  Future<void> reloadAssets() async {
    //NOTE - Fake delay to give impression of loading
    await Future.delayed(const Duration(seconds: 1));
    _reloadAssetsController.add(null);
  }

  Stream<List<Asset>> get stream => StreamGroup.merge<void>([
        Stream.periodic(const Duration(seconds: 5)),
        _reloadAssetsController.stream,
      ]).asyncMap((_) async {
        final balances =
            await ref.read(bitcoinProvider).getBalance(requiresRefresh: true);
        return Asset.btc(amount: balances?['btc'] as int? ?? 0);
      }).asyncMap((btcAsset) async {
        final balances =
            await ref.read(liquidProvider).getBalance(requiresRefresh: true) ??
                {};
        final assets = ref
            .read(manageAssetsProvider.select((p) => p.userAssets))
            .map((asset) => balances.containsKey(asset.id)
                ? asset.copyWith(amount: balances[asset.id] as int)
                : asset);
        return [btcAsset, ...assets];
      }).distinct((previous, current) =>
          // Only let the event pass if:
          // - the list of assets is the same length
          previous.length == current.length &&
          // - the list of assets contains the same assets
          previous.every((asset) => current.contains(asset)) &&
          // - the balance and the order of each asset is unchanged
          List.generate(current.length, (index) => index).every((index) {
            return current[index].id == previous[index].id &&
                current[index].amount == previous[index].amount;
          }));
}
