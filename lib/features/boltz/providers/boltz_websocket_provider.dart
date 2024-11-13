import 'dart:async';
import 'dart:convert';

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
  final _subscriptions = <String, StreamController<Map<String, dynamic>>>{};

  BoltzWebSocket(this._ref) {
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    final baseUrl = _ref
        .read(boltzEnvConfigProvider.select((env) => env.apiUrl))
        .replaceFirst('https://', 'wss://');
    final url = '$baseUrl/ws';

    _wssStream = IOWebSocketChannel.connect(url);
    logger.d('[Boltz] [WSS] Opening shared WebSocket connection at $url');

    _wssStream!.stream.listen(
      (event) {
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
      },
      onError: (error) {
        logger.e('[Boltz] [WSS] WebSocket error: $error');
      },
      onDone: () {
        logger.d('[Boltz] [WSS] WebSocket connection closed');
      },
    );
  }

  void subscribe(String swapId) {
    if (!_subscriptions.containsKey(swapId)) {
      _subscriptions[swapId] =
          StreamController<Map<String, dynamic>>.broadcast();
      _wssStream?.sink.add(jsonEncode({
        "op": "subscribe",
        "channel": "swap.update",
        "args": [swapId]
      }));
      logger.d('[Boltz] [WSS] Subscribed to updates for swap: $swapId');
    }
  }

  void unsubscribe(String swapId) {
    if (_subscriptions.containsKey(swapId)) {
      _subscriptions[swapId]!.close();
      _subscriptions.remove(swapId);
      _wssStream?.sink.add(jsonEncode({
        "op": "unsubscribe",
        "channel": "swap.update",
        "args": [swapId]
      }));
      logger.d('[Boltz] [WSS] Unsubscribed from updates for swap: $swapId');
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
    return _subscriptions[swapId]!.stream;
  }

  void closeConnection() {
    logger.d('[Boltz] [WSS] Closing shared WebSocket connection');
    for (var controller in _subscriptions.values) {
      controller.close();
    }
    _subscriptions.clear();
    _wssStream?.sink.close();
    _wssStream = null;
  }
}
