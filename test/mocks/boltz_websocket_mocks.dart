import 'dart:async';
import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// In-memory stand-in for a Boltz socket. [Mock] only supplies noSuchMethod
/// for the parts of the interface that BoltzWebSocket never touches.
class FakeWebSocketChannel extends Mock implements WebSocketChannel {
  FakeWebSocketChannel({Future<void>? ready}) : ready = ready ?? Future.value();

  final _incoming = StreamController<dynamic>();
  late final FakeWebSocketSink _sink = FakeWebSocketSink(this);

  /// Decoded frames the client sent on this channel.
  final sent = <Map<String, dynamic>>[];

  /// Makes every send fail, the way a broken sink does.
  bool failSends = false;

  @override
  final Future<void> ready;

  @override
  int? closeCode;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  /// Pushes a server frame to the client.
  void emit(Object frame) => _incoming.add(jsonEncode(frame));

  /// Drops the connection the way a server restart does.
  Future<void> serverClose() async {
    closeCode = 1006;
    await _incoming.close();
  }
}

class FakeWebSocketSink extends Mock implements WebSocketSink {
  FakeWebSocketSink(this._channel);

  final FakeWebSocketChannel _channel;

  @override
  void add(dynamic data) {
    if (_channel.failSends) {
      throw StateError('sink is broken');
    }
    _channel.sent.add(jsonDecode(data as String) as Map<String, dynamic>);
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}
