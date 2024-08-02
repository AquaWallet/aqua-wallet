import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

const int kLiquidBlockTimeoutMillis = 90000;
const int kInitialDelaySeconds = 5;
const int kLiquidStatusCheckPeriodSeconds = 10;

final connectionStatusProvider = AsyncNotifierProvider.autoDispose<
    ConnectionStatusNotifier, ConnectionStatus>(
  ConnectionStatusNotifier.new,
);

class ConnectionStatusNotifier
    extends AutoDisposeAsyncNotifier<ConnectionStatus> {
  ConnectionStatusNotifier();

  Timer? _checkLastLiquidBlockTimer;
  //just start assuming we are online
  int lastLiquidBlockTime = DateTime.now().millisecondsSinceEpoch;

  @override
  FutureOr<ConnectionStatus> build() async {
    Future.delayed(
      const Duration(seconds: kInitialDelaySeconds),
      startSync,
    );

    return const ConnectionStatus(
      isDeviceConnected: null,
      lastBitcoinBlock: null,
      lastLiquidBlock: null,
      initialized: false,
    );
  }

  Future<void> _checkLastLiquidBlockTime() async {
    logger.i("[StatusManager] fetch last liquid block time");
    final now = DateTime.now().millisecondsSinceEpoch;
    // liquid block times are 1 minute, so we check for block staleness every
    // 90 seconds
    final isDisconnected =
        now - lastLiquidBlockTime > kLiquidBlockTimeoutMillis;
    state = AsyncValue.data(
      state.requireValue.copyWith(isDeviceConnected: !isDisconnected),
    );
  }

  Future<void> startSync() async {
    logger.i("[StatusManager] start sync");
    _checkLastLiquidBlockTimer?.cancel();
    _checkLastLiquidBlockTimer = Timer.periodic(
      const Duration(seconds: kLiquidStatusCheckPeriodSeconds),
      (_) async => await _checkLastLiquidBlockTime(),
    );

    await _checkLastLiquidBlockTime();

    ref.read(bitcoinProvider).blockHeightEventSubject.stream.listen((block) {
      logger.i("[StatusManager] last Bitcoin block: $block");

      state = AsyncValue.data(
        state.requireValue.copyWith(lastBitcoinBlock: block),
      );
    });

    ref.read(liquidProvider).blockHeightEventSubject.stream.listen((block) {
      logger.i("[StatusManager] last Liquid block: $block");
      lastLiquidBlockTime = DateTime.now().millisecondsSinceEpoch;

      state = AsyncValue.data(
        state.requireValue.copyWith(lastLiquidBlock: block),
      );
    });

    state = AsyncValue.data(
      state.requireValue.copyWith(initialized: true),
    );
  }
}
