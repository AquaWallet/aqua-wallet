import 'dart:async';
import 'dart:convert';

import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/io.dart';

final boltzSwapStatusProvider = AutoDisposeStreamNotifierProviderFamily<
    BoltzSwapStatusNotifier,
    BoltzSwapStatusResponse,
    String>(BoltzSwapStatusNotifier.new);

class BoltzSwapStatusNotifier
    extends AutoDisposeFamilyStreamNotifier<BoltzSwapStatusResponse, String> {
  IOWebSocketChannel? _wssStream;

  @override
  Stream<BoltzSwapStatusResponse> build(String arg) {
    final id = arg;
    final baseUrl = ref
        .read(boltzEnvConfigProvider.select((env) => env.apiUrl))
        .replaceFirst('https://', 'wss://');
    final url = '$baseUrl/ws';
    final _wssStream = IOWebSocketChannel.connect(url)
      ..sink.add('{"op":"subscribe","channel":"swap.update","args":["$id"]}');

    logger.d('[Boltz] [WSS] Opening status stream for: $id at $url');

    return _wssStream.stream
        .map((event) => jsonDecode(event))
        .where((json) => json['event'] == 'update')
        .map((json) => json['args'])
        .cast<List>()
        .where((items) => items.isNotEmpty)
        .map((items) => items.first)
        .map((json) {
      logger.d('[Boltz] [WSS] Event: $json');
      return BoltzSwapStatusResponse.fromJson(json);
    }).asyncMap((response) async {
      await ref
          .read(boltzStorageProvider.notifier)
          .updateBoltzSwapStatus(boltzId: id, status: response.status);
      return response;
    }).doOnError((e, st) {
      logger.d('[Boltz] [WSS] Error: $e');
      logger.e("[BOLTZ] Stream subscription error for $id: $e", e, st);
    });
  }

  void closeStream() {
    _wssStream?.sink.close();
  }
}
