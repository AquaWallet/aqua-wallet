import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final boltzSwapStatusProvider = StreamNotifierProvider.autoDispose
    .family<BoltzSwapStatusNotifier, BoltzSwapStatusResponse, String>(
  BoltzSwapStatusNotifier.new,
);

class BoltzSwapStatusNotifier
    extends AutoDisposeFamilyStreamNotifier<BoltzSwapStatusResponse, String> {
  late final String _id;

  @override
  Stream<BoltzSwapStatusResponse> build(String arg) {
    _id = arg;
    logger.d('[Boltz] [WSS] Opening status stream for: $_id');

    // Ensure the WebSocket connection is initialized
    final boltzWebSocket = ref.read(boltzWebSocketProvider);

    ref.onDispose(() {
      logger.d('[Boltz] [WSS] Closing status stream for: $_id');
      boltzWebSocket.unsubscribe(_id);
    });

    return boltzWebSocket
        .getStream(_id, forceNewSubscription: true)
        .map((json) {
      logger.d('[Boltz] [WSS] Event for $_id: $json');
      return BoltzSwapStatusResponse.fromJson(json);
    }).asyncMap((response) async {
      await ref
          .read(boltzStorageProvider.notifier)
          .updateBoltzSwapStatus(boltzId: _id, status: response.status);
      return response;
    }).handleError((e, st) {
      logger.e("[Boltz] Stream subscription error for $_id: $e", e, st);
    });
  }

  Future<void> refreshSubscription() async {
    logger.d('[Boltz] Refreshing subscription for: $_id');

    final boltzWebSocket = ref.read(boltzWebSocketProvider);
    await boltzWebSocket.subscribe(_id);
  }
}
