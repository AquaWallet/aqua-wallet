import 'dart:async';

import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideshift/sideshift.dart';
import 'package:coin_cz/logger.dart';

final sideshiftAssetPairInfoProvider = AutoDisposeAsyncNotifierProviderFamily<
    _Notifier, SideShiftAssetPairInfo?, SideshiftAssetPair>(_Notifier.new);

class _Notifier extends AutoDisposeFamilyAsyncNotifier<SideShiftAssetPairInfo?,
    SideshiftAssetPair> {
  @override
  FutureOr<SideShiftAssetPairInfo?> build(SideshiftAssetPair arg) async {
    final info = await ref
        .read(sideshiftHttpProvider)
        .fetchSideShiftAssetPair(arg.from, arg.to);
    logger.d('[SideShift] Pair info: ${info.toJson()}');
    return info;
  }

  void setPairInfo(SideShiftAssetPairInfo? pairInfo) {
    state = AsyncValue.data(pairInfo);
  }
}
