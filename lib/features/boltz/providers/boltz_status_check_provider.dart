import 'dart:async';

import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

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
    final apiUrl = await _resolveApiUrl(arg);
    final boltzWebSocket = ref.read(boltzWebSocketProvider(apiUrl));

    await _subscription?.cancel();
    _subscription = null;

    ref.onDispose(() async {
      _logger.info('[Boltz] [WSS] Disposing status stream for: $_id');
      await _subscription?.cancel();
      await boltzWebSocket.unsubscribe(arg);
    });

    final stream = await boltzWebSocket.getStream(
      _id!,
      forceNewSubscription: true,
    );

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

  /// Prefer the URL stored on the swap; fall back to current setup config by kind.
  Future<String> _resolveApiUrl(String swapId) async {
    final swapDb =
        await ref.read(boltzStorageProvider.notifier).getSwapById(swapId);
    if (swapDb == null) {
      throw StateError(
          '[Boltz] [WSS] Cannot resolve API URL: swap $swapId not found');
    }

    final storedUrl = swapDb.boltzUrl;
    if (storedUrl != null && storedUrl.isNotEmpty) {
      return storedUrl;
    }

    return ref.watch(boltzApiUrlProvider(swapDb.kind).future);
  }
}
