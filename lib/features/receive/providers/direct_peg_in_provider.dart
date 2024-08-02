import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';

final directPegInProvider =
    AutoDisposeNotifierProvider<_Notifier, DirectPegState>(_Notifier.new);

class _Notifier extends AutoDisposeNotifier<DirectPegState> {
  @override
  DirectPegState build() {
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(sideswapWebsocketProvider).sendPeg(isPegIn: true);
    });

    return const DirectPegState.requestSent();
  }

  void orderCreated(SwapStartPegResponse response) {
    final order = response.result!;
    logger.d("[DirectPegIn] Created Order: $order");
    ref.read(pegStatusProvider.notifier).requestPegStatus(
          orderId: order.orderId,
          isPegIn: true,
        );
    state = DirectPegState.orderCreated(order: order);
  }
}
