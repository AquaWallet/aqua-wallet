import 'dart:async';
import 'dart:convert';

import 'package:aqua/logger.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

const sideswapWssAddressLive = 'wss://api.sideswap.io/json-rpc-ws';
const sideswapWssAddressTestnet = 'wss://api-testnet.sideswap.io/json-rpc-ws';
const sideswapWssAddressRegtest = 'wss://api-regtest.sideswap.io/json-rpc-ws';

String getSideswapWssAddress(Env env) => switch (env) {
      Env.mainnet => sideswapWssAddressLive,
      Env.regtest => sideswapWssAddressRegtest,
      Env.testnet => sideswapWssAddressTestnet,
    };

final swapNetworkErrorStateProvider =
    StateProvider.autoDispose<SwapNetworkErrorState>((_) {
  return const SwapNetworkErrorState.empty();
});

/// Websocket *********************************************

final sideswapWebsocketProvider =
    Provider.autoDispose<SideswapWebsocketProvider>(
        (ref) => SideswapWebsocketProvider(ref));

class SideswapWebsocketProvider {
  final AutoDisposeProviderRef ref;

  SideswapWebsocketProvider(this.ref) {
    ref.onDispose(() {
      _channel.sink.close(status.goingAway);
    });

    connect();
  }

  late WebSocketChannel _channel;
  StreamSubscription<dynamic>? _channelSubscription;

  Future<void> _sendRequest(
    WebSocketChannel channel,
    int requestId,
    String method,
    Map<String, dynamic>? params,
  ) async {
    logger.d('[Sideswap] Requesting $method: $params');

    channel.sink.add(
      jsonEncode({
        'id': requestId,
        'method': method,
        'params': params,
      }),
    );
  }

  Future<void> getServerStatus() async {
    await _sendRequest(_channel, 1, serverStatus, null);
  }

  Future<void> getAssets() async {
    await _sendRequest(
      _channel,
      1,
      assets,
      const AssetsRequest(embeddedIcons: false).toJson(),
    );
  }

  Future<void> subscribeAsset(SubscribePriceStreamRequest request) async {
    logger.d('[Sideswap] requesting: $request');
    ref.read(sideswapWebsocketSubscribedAssetIdStateProvider.notifier).state =
        request.asset ?? '';

    await _sendRequest(_channel, 1, subscribePriceStream, request.toJson());
  }

  Future<void> sendSwap(PriceStreamResult priceStreamResult) async {
    ref.read(swapLoadingIndicatorStateProvider.notifier).state =
        const SwapProgressState.waiting();

    final request = SwapStartWebRequest(
      asset: priceStreamResult.asset,
      price: priceStreamResult.price,
      sendBitcoins: priceStreamResult.sendBitcoins,
      sendAmount: priceStreamResult.sendAmount,
      recvAmount: priceStreamResult.recvAmount,
    );

    await _sendRequest(_channel, 1, startSwapWeb, request.toJson());
  }

  Future<void> sendPeg({required bool isPegIn}) async {
    ref.read(swapLoadingIndicatorStateProvider.notifier).state =
        const SwapProgressState.waiting();

    final receiveAddress = isPegIn
        ? await ref.read(liquidProvider).getReceiveAddress()
        : await ref.read(bitcoinProvider).getReceiveAddress();

    if (receiveAddress?.address?.isNotEmpty ?? false) {
      final request = SwapStartPegRequest(
        isPegIn: isPegIn,
        receiveAddress: receiveAddress!.address!,
      );

      await _sendRequest(_channel, 1, startPeg, request.toJson());
    } else {
      throw Exception('Invalid receive address');
    }
  }

  Future<void> connect() async {
    final env = ref.read(envProvider);
    final sideswapServerAddr = getSideswapWssAddress(env);
    _channel = WebSocketChannel.connect(Uri.parse(sideswapServerAddr));

    await getServerStatus();
    await getAssets();

    /// Listen for all incoming data
    if (_channelSubscription != null) {
      _channelSubscription!.cancel();
    }

    ref.read(sideswapWebsocketSubscribedAssetIdStateProvider.notifier).state =
        '';

    _channelSubscription = _channel.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
  }

  void _onData(dynamic data) {
    final json = jsonDecode(data as String) as Map<String, dynamic>;
    logger.d('[Sideswap] websocket reply: $json');

    if (json.containsKey('error')) {
      final error = Error.fromJson(json);
      logger.e('[Sideswap] $error');
      ref.read(swapLoadingIndicatorStateProvider.notifier).state =
          const SwapProgressState.empty();
      if (error.error?.message != null) {
        ref.read(swapNetworkErrorStateProvider.notifier).state =
            SwapNetworkErrorState.error(message: error.error?.message);
      }
      return;
    }

    if (json.containsKey('method')) {
      final method = json['method'] as String;

      switch (method) {
        case serverStatus:
          final response = ServerStatusResponse.fromJson(json);
          if (response.result != null) {
            ref.read(sideswapStatusStreamResultStateProvider.notifier).state =
                response.result;
          }
          break;
        case assets:
          final assetsResponse = AssetsResponse.fromJson(json);
          if (assetsResponse.result?.assets != null) {
            ref
                .read(swapAssetsProvider.notifier)
                .addAssets(assetsResponse.result?.assets ?? []);
          }
          break;
        case subscribePriceStream:
          final response = SubscribePriceStreamResponse.fromJson(json);
          if (response.result != null) {
            ref.read(sideswapPriceStreamResultStateProvider.notifier).state =
                response.result;
          }
          break;
        case notificationUpdatePriceStream:
          final response = UpdatePriceStreamResponse.fromJson(json);
          ref.read(sideswapPriceStreamResultStateProvider.notifier).state =
              response.params;
          break;
        case startSwapWeb:
          final response = SwapStartWebResponse.fromJson(json);
          ref.read(swapProvider.notifier).requestVerification(response);
          break;
        case startPeg:
          final response = SwapStartPegResponse.fromJson(json);
          ref.read(pegProvider.notifier).requestVerification(response);
          break;
        case swapDone:
          final response = SwapDoneResponse.fromJson(json);
          final receiveAsset = response.params?.recvAsset;
          final transactionId = response.params?.txid;
          final success = response.params?.status == SwapDoneStatusEnum.success;
          if (receiveAsset != null && transactionId != null && success) {
            ref.read(swapProvider.notifier).markSwapSuccess(response);
          } else {
            // TODO Handle error
            logger.e('[Sideswap] Error: $json');
          }
          break;
        default:
          logger.w('[Sideswap] unexpected response: $method');
          logger.w('[Sideswap] ${json['result']}');
      }
    }
  }

  void _onError(dynamic error) {
    logger.e('[Sideswap] Error: $error');
  }

  void _onDone() {
    logger.d('[Sideswap] Done');
    ref.read(sideswapWebsocketSubscribedAssetIdStateProvider.notifier).state =
        '';
    ref.read(swapLoadingIndicatorStateProvider.notifier).state =
        const SwapProgressState.empty();
  }
}
