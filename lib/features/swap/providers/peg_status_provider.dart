import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';

const kStatusCheckInterval = Duration(seconds: 15);

typedef SwapStatusParams = ({
  String orderId,
  bool isPegIn,
});

final pegStatusProvider =
    NotifierProvider.autoDispose<_Notifier, SwapPegStatusResult?>(
        _Notifier.new);

class _Notifier extends AutoDisposeNotifier<SwapPegStatusResult?> {
  SwapStatusParams? params;

  @override
  SwapPegStatusResult? build() {
    Timer.periodic(kStatusCheckInterval, (_) {
      if (params != null) {
        ref.read(pegStatusProvider.notifier).requestPegStatus(
              orderId: params!.orderId,
              isPegIn: params!.isPegIn,
            );
      }
    });
    return null;
  }

  void requestPegStatus({
    required String orderId,
    required bool isPegIn,
  }) {
    params = (orderId: orderId, isPegIn: true);
    ref
        .read(sideswapWebsocketProvider)
        .requestPegStatus(orderId: orderId, isPegIn: true);
  }

  void processPegStatus(SwapPegStatusResponse response) {
    logger.d('[PegStatus] Status: ${response.result}');
    state = response.result;
  }
}
