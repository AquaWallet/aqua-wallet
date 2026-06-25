import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:aqua/config/router/go_router.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeepLinkScheme {
  aqua('aqua'),
  lightning('lightning'),
  bitcoin('bitcoin'),
  liquidnetwork('liquidnetwork');

  const DeepLinkScheme(this.value);
  final String value;

  static DeepLinkScheme? fromScheme(String scheme) => DeepLinkScheme.values
      .where((e) => e.value == scheme.toLowerCase())
      .firstOrNull;

  Asset get asset => switch (this) {
        DeepLinkScheme.bitcoin => Asset.btc(),
        DeepLinkScheme.liquidnetwork => Asset.lbtc(),
        DeepLinkScheme.lightning => Asset.lightning(),
        _ => Asset.unknown(),
      };

  bool get shouldRemoveScheme => this == DeepLinkScheme.lightning;
  bool get containsChildScheme => this == DeepLinkScheme.aqua;
}

final deepLinkProvider =
    AsyncNotifierProvider<DeepLinkNotifier, void>(DeepLinkNotifier.new);

class DeepLinkNotifier extends AsyncNotifier<void> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  Uri? _lastProcessedUri;
  DateTime? _lastProcessedTime;
  static const _deduplicationWindow = Duration(seconds: 3);

  @override
  Future<void> build() async {
    _subscription = _appLinks.uriLinkStream.listen(
      _onUri,
      onError: (e) => logger.error('[DeepLink] uriLinkStream error: $e'),
    );

    _appLinks.getInitialLink().then((uri) {
      logger.debug('[DeepLink] getInitialLink: $uri');
      if (uri != null) _onUri(uri);
    }).catchError((e) {
      logger.error('[DeepLink] getInitialLink error: $e');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  void _onUri(Uri uri) {
    logger.debug('[DeepLink] Received URI: $uri');

    final now = DateTime.now();
    if (_lastProcessedUri == uri &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!) < _deduplicationWindow) {
      logger.debug('[DeepLink] Skipping duplicate URI: $uri');
      return;
    }
    _lastProcessedUri = uri;
    _lastProcessedTime = now;

    _processUri(uri);
  }

  void _processUri(Uri uri) {
    final (:payload, :asset) = _extractPayload(uri);
    logger.debug(
        '[DeepLink] Processing payload: $payload (asset: ${asset.ticker})');

    final args = SendAssetArguments.fromAsset(asset).copyWith(
      input: payload,
      transactionType: SendTransactionType.deepLink,
    );
    final router = ref.read(routerProvider);
    router.push(SendAssetScreen.routeName, extra: args);
  }
}

({String payload, Asset asset}) _extractPayload(Uri uri) {
  final scheme = DeepLinkScheme.fromScheme(uri.scheme);
  final raw = uri.toString();
  if (scheme != null) {
    final subString = raw.substring('${uri.scheme}:'.length);
    if (scheme.containsChildScheme) {
      return _extractPayload(Uri.parse(subString));
    } else if (scheme.shouldRemoveScheme) {
      return (payload: subString, asset: scheme.asset);
    }
  }

  return (payload: raw, asset: scheme?.asset ?? Asset.unknown());
}
