import 'dart:async';

import 'package:aqua/features/boltz/providers/boltz_websocket_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/boltz_websocket_mocks.dart';

/// All swap ids this channel was asked to subscribe to, in send order.
List<String> subscribedIds(FakeWebSocketChannel channel) => channel.sent
    .where((frame) => frame['op'] == 'subscribe')
    .expand((frame) => (frame['args'] as List).cast<String>())
    .toList();

/// Lets pending stream events run without letting reconnect timers fire.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  const apiUrl = 'https://api.boltz.test';

  late List<FakeWebSocketChannel> channels;

  setUp(() => channels = []);

  BoltzWebSocket buildSocket({Future<void> Function()? ready}) =>
      BoltzWebSocket(apiUrl, channelFactory: (_) {
        final channel = FakeWebSocketChannel(ready: ready?.call());
        channels.add(channel);
        return channel;
      });

  group('BoltzWebSocket connect failure', () {
    test('concurrent subscribers share one attempt and both see the error',
        () async {
      final socket = buildSocket(
        ready: () => Future.error(TimeoutException('no route to host')),
      );
      addTearDown(socket.closeConnection);

      final errors = await Future.wait([
        _errorOf(() => socket.getStream('swap-a')),
        _errorOf(() => socket.getStream('swap-b')),
      ]);

      expect(channels, hasLength(1), reason: 'connects must be serialized');
      expect(errors[0], isA<TimeoutException>());
      expect(errors[1], isA<TimeoutException>());
    });
  });

  group('BoltzWebSocket reconnection', () {
    test('re-sends live subscriptions and keeps existing streams alive',
        () async {
      final socket = buildSocket();
      addTearDown(socket.closeConnection);

      final updates = <Map<String, dynamic>>[];
      final streamA = await socket.getStream('swap-a');
      streamA.listen(updates.add);
      await socket.getStream('swap-b');

      expect(channels, hasLength(1));
      expect(subscribedIds(channels[0]), ['swap-a', 'swap-b']);

      await channels[0].serverClose();
      await settle();

      // A new subscribe reconnects before the backoff timer fires.
      await socket.getStream('swap-c');

      expect(channels, hasLength(2));
      expect(
        subscribedIds(channels[1]),
        containsAll(['swap-a', 'swap-b', 'swap-c']),
      );

      channels[1].emit({
        'event': 'update',
        'args': [
          {'id': 'swap-a', 'status': 'transaction.mempool'}
        ],
      });
      await settle();

      expect(updates, hasLength(1),
          reason: 'the pre-reconnect listener must still receive updates');
      expect(updates.first['status'], 'transaction.mempool');
    });
  });

  group('BoltzWebSocket send failure', () {
    test('keeps the ids queued for the next successful send', () async {
      final socket = buildSocket();
      addTearDown(socket.closeConnection);

      await socket.getStream('swap-a');
      channels[0].failSends = true;

      await expectLater(
        socket.getStream('swap-b'),
        throwsA(isA<StateError>()),
      );
      expect(subscribedIds(channels[0]), ['swap-a']);

      channels[0].failSends = false;
      await socket.getStream('swap-c');

      expect(subscribedIds(channels[0]), containsAll(['swap-b', 'swap-c']),
          reason: 'the failed id must be re-sent, not dropped');
    });

    test('unsubscribe drops an id that never reached the server', () async {
      final socket = buildSocket();
      addTearDown(socket.closeConnection);

      await socket.getStream('swap-a');
      channels[0].failSends = true;

      await expectLater(
        socket.getStream('swap-b'),
        throwsA(isA<StateError>()),
      );

      await socket.unsubscribe('swap-b');
      channels[0].failSends = false;
      await socket.getStream('swap-c');

      expect(subscribedIds(channels[0]), ['swap-a', 'swap-c'],
          reason: 'an abandoned id must not be resurrected by a later send');
    });
  });
}

/// Runs [action] and returns the error it threw, or null if it succeeded.
Future<Object?> _errorOf(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } catch (error) {
    return error;
  }
}
