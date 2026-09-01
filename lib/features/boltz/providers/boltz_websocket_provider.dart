import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

/// Opens the transport for a wss:// url. Only tests replace it, so they can
/// drive connect failures and reconnects without a live server.
typedef BoltzChannelFactory = WebSocketChannel Function(String url);

/// One independently managed WebSocket per Boltz API URL.
final boltzWebSocketProvider =
    Provider.family<BoltzWebSocket, String>((ref, apiUrl) {
  final boltzWebSocket = BoltzWebSocket(apiUrl);
  ref.onDispose(() {
    if (boltzWebSocket.isConnected) {
      boltzWebSocket.closeConnection();
    }
  });
  return boltzWebSocket;
});

class BoltzWebSocket {
  final String apiUrl;
  final BoltzChannelFactory _channelFactory;
  WebSocketChannel? _wssStream;
  StreamSubscription? _wsSubscription;
  final _subscriptions = <String, StreamController<Map<String, dynamic>>>{};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  final _subscriptionQueue = <String>{};
  bool _isConnectionReady = false;
  Future<void>? _connecting;

  BoltzWebSocket(this.apiUrl, {BoltzChannelFactory? channelFactory})
      : _channelFactory = channelFactory ?? _connectIoChannel {
    _logger.debug('[Boltz] -- BoltzWebSocket init for $apiUrl --');
  }

  static WebSocketChannel _connectIoChannel(String url) =>
      IOWebSocketChannel.connect(
        url,
        connectTimeout: const Duration(seconds: 10),
      );

  /// Queued ids count too: a connection that dies before the first subscribe
  /// succeeds has an empty [_subscriptions] map but still needs a reconnect.
  bool get _hasSubscribers =>
      _subscriptions.isNotEmpty || _subscriptionQueue.isNotEmpty;

  bool get isConnected {
    if (_wssStream == null) {
      _logger.info('[Boltz] [WSS] Connection check: WebSocket stream is null');
      return false;
    }

    final isConnected = _wssStream!.closeCode == null && _isConnectionReady;
    if (!isConnected) {
      _logger.info(
          '[Boltz] [WSS] Connection check: WebSocket is not ready (closeCode: ${_wssStream!.closeCode}, ready: $_isConnectionReady)');
    }
    return isConnected;
  }

  /// Transport only: opens the socket and marks it ready. Subscription
  /// bookkeeping lives in [_connect], the sole caller.
  Future<void> _openSocket() async {
    _logger.info('[Boltz] [WSS] Initializing WebSocket connection');

    final baseUrl = apiUrl.replaceFirst('https://', 'wss://');
    final url = '$baseUrl/ws';

    try {
      _wssStream = _channelFactory(url);
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
      _isConnectionReady = true;
      _logger.info('[Boltz] [WSS] WebSocket connection established');
    } catch (e) {
      _isConnectionReady = false;
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
    _isConnectionReady = false;
    _scheduleReconnection();
  }

  void _handleDisconnection() {
    _logger.info('[Boltz] [WSS] WebSocket connection closed');
    _isConnectionReady = false;

    if (_hasSubscribers) {
      _logger.info(
          '[Boltz] [WSS] Active subscriptions found, scheduling reconnection');
      _scheduleReconnection();
    } else {
      _logger.info('[Boltz] [WSS] No active subscriptions, closing connection');
    }
  }

  /// Safe to call from multiple sites: the active-timer guard makes repeat
  /// scheduling a no-op.
  void _scheduleReconnection() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.error('[Boltz] [WSS] Max reconnection attempts reached');
      return;
    }

    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
    _logger.info('[Boltz] [WSS] Scheduling reconnection in $delay');
    _reconnectTimer = Timer(delay, () {
      // A subscribe() can reconnect through _ensureConnected while this timer
      // is pending. Do not spend an attempt on a run that has nothing to do,
      // otherwise the backoff for the next real failure starts too high.
      if (isConnected && _subscriptionQueue.isEmpty) {
        _logger.info(
            '[Boltz] [WSS] Reconnect timer fired but connection is live, skipping');
        return;
      }
      if (_hasSubscribers) {
        _logger.info(
            '[Boltz] [WSS] Attempting to reconnect... (Attempt ${_reconnectAttempts + 1})');
        _reconnectAttempts++;
        // Reconnects and re-sends the queue; a failed attempt logs and
        // reschedules internally. Its error is ignored here: there is no
        // caller to report it to.
        _processSubscriptionQueue().ignore();
      }
    });
  }

  /// Serializes connection attempts: concurrent callers await the same
  /// in-flight connect instead of racing cleanup against init.
  Future<void> _ensureConnected() {
    if (isConnected) return Future.value();
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<void> _connect() async {
    _logger.info('[Boltz] [WSS] Reestablishing WebSocket connection');
    // Cleanup must fully finish before _openSocket assigns the new channel,
    // otherwise cleanup's teardown nulls out the fresh stream.
    await _cleanupConnection();
    await _openSocket();

    // The new socket knows nothing about previously live subscriptions
    // (e.g. after a server restart), so re-send them along with the queue.
    // The queue may transiently overlap _subscriptions here; sends dedup.
    _subscriptionQueue.addAll(_subscriptions.keys);
    await _drainSubscriptionQueue();
  }

  Future<void> _cleanupConnection() async {
    _logger.info('[Boltz] [WSS] Cleaning up existing connection');
    _isConnectionReady = false;
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
      if (!isConnected) {
        throw StateError('WebSocket is not connected');
      }
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
            _logger.debug(
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
    try {
      await _ensureConnected();
    } catch (e) {
      // _openSocket already logged and scheduled a reconnect, and the queued
      // ids stay queued for it. Rethrow anyway: subscribe() callers must see
      // the real connection error, not a generic "no subscription" failure.
      _logger.error('[Boltz] [WSS] Cannot connect to send subscriptions: $e');
      rethrow;
    }

    await _drainSubscriptionQueue();
  }

  Future<void> _drainSubscriptionQueue() async {
    while (_subscriptionQueue.isNotEmpty) {
      try {
        final swapIds = _subscriptionQueue.toList();
        await _sendSubscriptions(swapIds);
        // Only drop what was sent: new ids may have been queued while the
        // send was in flight.
        _subscriptionQueue.removeAll(swapIds);
      } catch (e) {
        _logger.error('[Boltz] [WSS] Failed to process subscriptions: $e');
        _scheduleReconnection();
        break;
      }
    }
  }

  Future<void> unsubscribe(String swapId) async {
    // Drop the queued id first. A subscribe that never reached the server has
    // no entry in _subscriptions, and a leftover queue entry keeps
    // _hasSubscribers true, so the socket would reconnect and resurrect a
    // subscription that nobody listens to.
    _subscriptionQueue.remove(swapId);

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
