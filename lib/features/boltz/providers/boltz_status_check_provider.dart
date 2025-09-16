import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

final boltzSwapStatusProvider = StreamNotifierProvider.autoDispose
    .family<BoltzSwapStatusNotifier, BoltzSwapStatusResponse, String>(
  BoltzSwapStatusNotifier.new,
);

class BoltzSwapStatusNotifier
    extends AutoDisposeFamilyStreamNotifier<BoltzSwapStatusResponse, String> {
  String? _id;
  StreamSubscription? _subscription;

  @override
  Stream<BoltzSwapStatusResponse> build(String arg) async* {
    _logger.info(
        '[Boltz] [WSS] Building status notifier for: $arg, current _id: $_id');

    _id = arg;
    final boltzWebSocket = ref.read(boltzWebSocketProvider);

    await _subscription?.cancel();
    _subscription = null;

    ref.onDispose(() async {
      _logger.info('[Boltz] [WSS] Disposing status stream for: $_id');
      await _subscription?.cancel();
    });

    final stream =
        await boltzWebSocket.getStream(_id!, forceNewSubscription: true);

    _subscription = stream.listen(
      null,
      onError: (error, stack) {
        _logger.error('[Boltz] Stream error for $_id', error, stack);
      },
    );

    yield* stream.map((json) {
      try {
        final response = BoltzSwapStatusResponse.fromJson(json);
        _logger.info(
            '[Boltz] [WSS] Status response for $_id: ${response.status.value}');

        Future(() async {
          await ref
              .read(boltzStorageProvider.notifier)
              .updateBoltzSwapStatus(boltzId: _id!, status: response.status);
        });

        return response;
      } catch (e, st) {
        _logger.error("[Boltz] Stream parsing error for $_id: $e", e, st);
        rethrow;
      }
    });
  }
}
