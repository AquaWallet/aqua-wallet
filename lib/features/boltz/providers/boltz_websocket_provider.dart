import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final boltzWebSocketProvider = Provider<BoltzWebSocket>((ref) {
  final boltzWebSocket = BoltzWebSocket(ref);
  ref.onDispose(() {
    boltzWebSocket.closeConnection();
  });
  return boltzWebSocket;
});

class BoltzWebSocket {
  final Ref _ref;
  IOWebSocketChannel? _wssStream;
  StreamSubscription? _wsSubscription;
  final _subscriptions = <String, StreamController<Map<String, dynamic>>>{};
  //TODO: Investigate using `_wssStream?.closeCode == null` instead of manually managing reconnection
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  BoltzWebSocket(this._ref) {
    _initializeWebSocket();
  }

  bool get hasActiveSubscriptions => _subscriptions.isNotEmpty;

  Future<void> _initializeWebSocket() async {
    if (_wssStream != null) return;

    final baseUrl = _ref
        .read(boltzEnvConfigProvider.select((env) => env.apiUrl))
        .replaceFirst('https://', 'wss://');
    final url = '$baseUrl/ws';

    try {
      _wssStream = IOWebSocketChannel.connect(
        url,
        pingInterval: const Duration(seconds: 10),
      );
      logger.d('[Boltz] [WSS] Opening shared WebSocket connection at $url');

      // Wait for connection to be ready
      await _wssStream!.ready;

      // Create a single subscription to the broadcast stream
      _wsSubscription = _wssStream!.stream.asBroadcastStream().listen(
            _handleMessage,
            onError: _handleError,
            onDone: _handleDisconnection,
            cancelOnError: false,
          );

      _isConnected = true;
      _reconnectAttempts = 0;
      logger.d('[Boltz] [WSS] WebSocket connection established');

      // Resubscribe to existing subscriptions if any
      for (final swapId in _subscriptions.keys.toList()) {
        _sendSubscription(swapId);
      }
    } catch (e) {
      logger.e('[Boltz] [WSS] Failed to establish WebSocket connection: $e');
      _scheduleReconnection();
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

      logger.d('[Boltz] [WSS] Message received: $json');
    } catch (e) {
      logger.e('[Boltz] [WSS] Error handling message: $e');
    }
  }

  void _handleError(error) {
    logger.e('[Boltz] [WSS] WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnection();
  }

  void _handleDisconnection() {
    logger.d('[Boltz] [WSS] WebSocket connection closed');
    _isConnected = false;

    if (hasActiveSubscriptions) {
      logger.d(
          '[Boltz] [WSS] Active subscriptions found, scheduling reconnection');
      _scheduleReconnection();
    } else {
      logger.d('[Boltz] [WSS] No active subscriptions, closing connection');
    }
  }

  void _scheduleReconnection() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      logger.e('[Boltz] [WSS] Max reconnection attempts reached');
      return;
    }

    // Exponential backoff
    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
    logger.d('[Boltz] [WSS] Scheduling reconnection in $delay');
    _reconnectTimer = Timer(delay, () {
      if (hasActiveSubscriptions) {
        logger.d(
            '[Boltz] [WSS] Attempting to reconnect... (Attempt ${_reconnectAttempts + 1})');
        _reconnectAttempts++;
        _reestablishConnection();
      }
    });
  }

  Future<void> _reestablishConnection() async {
    logger.d('[Boltz] [WSS] Reestablishing WebSocket connection');
    _cleanupConnection();
    await _initializeWebSocket();
  }

  void _cleanupConnection() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wssStream?.sink.close();
    _wssStream = null;
  }

  Future<void> _sendSubscription(String swapId) async {
    if (_wssStream != null && _isConnected) {
      await _wssStream!.sink.addStream(Stream.value(jsonEncode({
        "op": "subscribe",
        "channel": "swap.update",
        "args": [swapId]
      })));
      logger.d('[Boltz] [WSS] Subscribed to updates for swap: $swapId');
    }
  }

  Future<void> subscribe(String swapId) async {
    if (!_subscriptions.containsKey(swapId)) {
      _subscriptions[swapId] =
          StreamController<Map<String, dynamic>>.broadcast();

      if (!_isConnected) {
        await _reestablishConnection();
      }

      await _sendSubscription(swapId);

      logger.d('[Boltz] [WSS] Subscription requested for swap: $swapId');
    }
  }

  Future<void> unsubscribe(String swapId) async {
    if (_subscriptions.containsKey(swapId)) {
      if (_wssStream != null && _isConnected) {
        await _wssStream!.sink.addStream(Stream.value(jsonEncode({
          "op": "unsubscribe",
          "channel": "swap.update",
          "args": [swapId]
        })));
        logger.d('[Boltz] [WSS] Unsubscribed from updates for swap: $swapId');
      }

      await _subscriptions[swapId]!.close();
      _subscriptions.remove(swapId);

      if (!hasActiveSubscriptions) {
        await closeConnection();
      }
    }
  }

  Stream<Map<String, dynamic>> getStream(String swapId,
      {bool forceNewSubscription = false}) {
    if (forceNewSubscription || !_subscriptions.containsKey(swapId)) {
      if (_subscriptions.containsKey(swapId)) {
        unsubscribe(swapId);
      }
      subscribe(swapId);
    }

    logger.d('[Boltz] [WSS] Stream requested for swap: $swapId');
    return _subscriptions[swapId]!.stream;
  }

  Future<void> closeConnection() async {
    logger.d('[Boltz] [WSS] Closing shared WebSocket connection');
    for (var controller in _subscriptions.values) {
      await controller.close();
    }
    _subscriptions.clear();
    _cleanupConnection();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _isConnected = false;
    logger.d('[Boltz] [WSS] WebSocket connection closed');
  }
}
