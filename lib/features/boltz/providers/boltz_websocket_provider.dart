import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

final boltzWebSocketProvider = Provider<BoltzWebSocket>((ref) {
  final boltzWebSocket = BoltzWebSocket(ref);
  ref.onDispose(() {
    if (boltzWebSocket.isConnected) {
      boltzWebSocket.closeConnection();
    }
  });
  return boltzWebSocket;
});

class BoltzWebSocket {
  final Ref _ref;
  IOWebSocketChannel? _wssStream;
  StreamSubscription? _wsSubscription;
  final _subscriptions = <String, StreamController<Map<String, dynamic>>>{};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  final _subscriptionQueue = <String>[];

  BoltzWebSocket(this._ref) {
    _logger.debug('[Boltz] -- BoltzWebSocket init --');
  }

  bool get hasActiveSubscriptions => _subscriptions.isNotEmpty;

  bool get isConnected {
    if (_wssStream == null) {
      _logger.info('[Boltz] [WSS] Connection check: WebSocket stream is null');
      return false;
    }

    final isConnected =
        _wssStream!.innerWebSocket?.readyState == WebSocket.open;
    if (!isConnected) {
      _logger
          .info('[Boltz] [WSS] Connection check: WebSocket is not connected');
    }
    return isConnected;
  }

  Future<void> initializeWebSocket() async {
    if (isConnected) {
      _logger.info('[Boltz] [WSS] WebSocket already connected');
      return;
    }

    _logger.info('[Boltz] [WSS] Initializing WebSocket connection');

    final baseUrl = _ref
        .read(boltzEnvConfigProvider.select((env) => env.apiUrl))
        .replaceFirst('https://', 'wss://');
    final url = '$baseUrl/ws';

    try {
      _wssStream = IOWebSocketChannel.connect(
        url,
        connectTimeout: const Duration(seconds: 10),
      );
      _logger.info('[Boltz] [WSS] Opening shared WebSocket connection at $url');

      _wsSubscription = _wssStream!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      await _wssStream!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('WebSocket initialization timed out');
        },
      );

      _reconnectAttempts = 0;
      _logger.info('[Boltz] [WSS] WebSocket connection established');

      _processSubscriptionQueue();
    } catch (e) {
      _logger
          .error('[Boltz] [WSS] Failed to establish WebSocket connection: $e');
      _scheduleReconnection();
      rethrow;
    }
  }

  void _handleMessage(dynamic event) {
    try {
      final json = jsonDecode(event);
      if (json['event'] == 'update' &&
          json['args'] is List &&
          json['args'].isNotEmpty) {
        final update = json['args'][0];
        final id = update['id'];

        if (_subscriptions.containsKey(id)) {
          _subscriptions[id]!.add(update);
        }
      }

      _logger.info('[Boltz] [WSS] Message received: $json');
    } catch (e) {
      _logger.error('[Boltz] [WSS] Error handling message: $e');
    }
  }

  void _handleError(error) {
    _logger.error('[Boltz] [WSS] WebSocket error: $error');
    _scheduleReconnection();
  }

  void _handleDisconnection() {
    _logger.info('[Boltz] [WSS] WebSocket connection closed');

    if (hasActiveSubscriptions) {
      _logger.info(
          '[Boltz] [WSS] Active subscriptions found, scheduling reconnection');
      _scheduleReconnection();
    } else {
      _logger.info('[Boltz] [WSS] No active subscriptions, closing connection');
    }
  }

  void _scheduleReconnection() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.error('[Boltz] [WSS] Max reconnection attempts reached');
      return;
    }

    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
    _logger.info('[Boltz] [WSS] Scheduling reconnection in $delay');
    _reconnectTimer = Timer(delay, () {
      if (hasActiveSubscriptions) {
        _logger.info(
            '[Boltz] [WSS] Attempting to reconnect... (Attempt ${_reconnectAttempts + 1})');
        _reconnectAttempts++;
        _reestablishConnection();
      }
    });
  }

  Future<void> _reestablishConnection() async {
    _logger.info('[Boltz] [WSS] Reestablishing WebSocket connection');

    if (isConnected) {
      _logger.info(
          '[Boltz] [WSS] WebSocket already connected, skipping reestablishment');
      return;
    }

    try {
      // Set a timeout for the entire reestablishment process
      await Future.wait([
        _cleanupConnection(),
        initializeWebSocket(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.error('[Boltz] [WSS] Connection reestablishment timed out');
          throw TimeoutException('WebSocket reestablishment timed out');
        },
      );
    } catch (e) {
      _logger.error('[Boltz] [WSS] Failed to reestablish connection: $e');

      // If we still have active subscriptions, schedule another reconnection attempt
      if (hasActiveSubscriptions) {
        _scheduleReconnection();
      }

      rethrow;
    }
  }

  Future<void> _cleanupConnection() async {
    _logger.info('[Boltz] [WSS] Cleaning up existing connection');
    try {
      // Set timeouts for each cleanup operation
      await Future.wait([
        _wsSubscription?.cancel().timeout(
                  const Duration(seconds: 2),
                  onTimeout: () => null,
                ) ??
            Future.value(),
        _wssStream?.sink.close().timeout(
                  const Duration(seconds: 2),
                  onTimeout: () => null,
                ) ??
            Future.value(),
      ]);
    } catch (e) {
      _logger.error('[Boltz] [WSS] Error during connection cleanup: $e');
    } finally {
      _wsSubscription = null;
      _wssStream = null;
    }
  }

  Future<void> _sendSubscriptions(List<String> swapIds) async {
    try {
      _wssStream!.sink.add(jsonEncode(
          {"op": "subscribe", "channel": "swap.update", "args": swapIds}));

      // Create or verify broadcast controllers for each swap ID
      for (final swapId in swapIds) {
        if (_subscriptions.containsKey(swapId)) {
          if (_subscriptions[swapId]!.isClosed) {
            _logger.info(
                '[Boltz] [WSS] Recreating closed controller for swap: $swapId');
            _subscriptions[swapId] =
                StreamController<Map<String, dynamic>>.broadcast();
          } else {
            _logger.info(
                '[Boltz] [WSS] Controller already exists and active for swap: $swapId');
            continue;
          }
        } else {
          _subscriptions[swapId] =
              StreamController<Map<String, dynamic>>.broadcast();
          _logger.info(
              '[Boltz] [WSS] Created new broadcast controller for swap: $swapId');
        }
      }

      _logger.info('[Boltz] [WSS] Subscribed to updates for swaps: $swapIds');
    } catch (e) {
      _logger.error('[Boltz] [WSS] Failed to send subscriptions: $e');
      rethrow;
    }
  }

  Future<void> subscribe(String swapId,
      {bool forceNewSubscription = false}) async {
    if (forceNewSubscription) {
      _logger.info(
          '[Boltz] [WSS] Force refreshing subscription for swap: $swapId');
      if (_subscriptions.containsKey(swapId)) {
        _logger.info(
            '[Boltz] [WSS] Removing existing subscription for swap: $swapId');
        await unsubscribe(swapId);
      }
    }

    if (forceNewSubscription || !_subscriptions.containsKey(swapId)) {
      _subscriptionQueue.add(swapId);
      _logger.info(
          '[Boltz] [WSS] ${forceNewSubscription ? "Adding renewed" : "Adding new"} subscription for swap: $swapId. Queue size: ${_subscriptionQueue.length}');

      await _processSubscriptionQueue();
    } else {
      _logger.info(
          '[Boltz] [WSS] Subscription already exists for swap: $swapId. Skipping queue.');
    }
  }

  Future<void> _processSubscriptionQueue() async {
    if (!isConnected) {
      _logger.info('[Boltz] [WSS] Connection lost, attempting to reconnect');
      await Future.delayed(const Duration(milliseconds: 100));
      await _reestablishConnection();
    }

    while (_subscriptionQueue.isNotEmpty) {
      try {
        final swapIds = List<String>.from(_subscriptionQueue);
        await _sendSubscriptions(swapIds);
        _subscriptionQueue.clear();
      } catch (e) {
        _logger.error('[Boltz] [WSS] Failed to process subscriptions: $e');
        break;
      }
    }
  }

  Future<void> unsubscribe(String swapId) async {
    if (_subscriptions.containsKey(swapId)) {
      try {
        if (_wssStream != null && isConnected) {
          _wssStream!.sink.add(jsonEncode({
            "op": "unsubscribe",
            "channel": "swap.update",
            "args": [swapId]
          }));
          _logger.debug(
              '[Boltz] [WSS] Unsubscribed from updates for swap: $swapId');
        }
      } catch (e) {
        _logger.error(
            '[Boltz] [WSS] Error unsubscribing from swap: $swapId', e);
      } finally {
        await _subscriptions[swapId]!.close();
        _subscriptions.remove(swapId);
      }
    }
  }

  Future<Stream<Map<String, dynamic>>> getStream(
    String swapId, {
    bool forceNewSubscription = false,
  }) async {
    if (forceNewSubscription || !_subscriptions.containsKey(swapId)) {
      await subscribe(swapId, forceNewSubscription: forceNewSubscription);
    }

    if (!_subscriptions.containsKey(swapId)) {
      throw StateError(
          '[Boltz] [WSS] No subscription available for swap: $swapId after attempted subscription');
    }

    return _subscriptions[swapId]!.stream;
  }

  Future<void> closeConnection() async {
    _logger.info('[Boltz] [WSS] Closing shared WebSocket connection');
    for (var controller in _subscriptions.values) {
      await controller.close();
    }
    _subscriptions.clear();
    await _cleanupConnection();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _logger.info('[Boltz] [WSS] WebSocket connection closed');
  }
}
