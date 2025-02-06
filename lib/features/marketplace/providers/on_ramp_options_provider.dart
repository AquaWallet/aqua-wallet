import 'dart:async';

import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/features/marketplace/models/models.dart';
import 'package:aqua/features/marketplace/services/on_ramp_price_fetcher_factory.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/settings/region/providers/region_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final onRampOptionsProvider =
    AutoDisposeNotifierProvider<OnRampOptionsNotifier, List<OnRampIntegration>>(
        OnRampOptionsNotifier.new);

final onRampPriceProvider = FutureProvider.autoDispose
    .family<String?, OnRampIntegration>((ref, onRamp) {
  final price = ref.watch(onRampOptionsProvider.notifier).fetchPrice(onRamp);
  return price;
});

class OnRampOptionsNotifier
    extends AutoDisposeNotifier<List<OnRampIntegration>> {
  @override
  List<OnRampIntegration> build() {
    _init();
    return state;
  }

  void _init() {
    final region = ref.watch(regionsProvider).currentRegion;

    if (region == null) {
      assert(false);
      state = [];
      return;
    }

    final isBtcDirectEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.btcDirectEnabled));

    final filteredIntegrations = OnRampIntegration.allIntegrations
        .where((integration) =>
            // Filter by region
            (integration.allRegions ||
                integration.regions.any((r) => r.iso == region.iso)) &&
            // FEATURE FLAG: Filter BTC Direct by feature flag
            (integration.type != OnRampIntegrationType.btcDirect ||
                isBtcDirectEnabled))
        .toList();

    state = filteredIntegrations;
  }

  Future<String?> fetchPrice(OnRampIntegration onRamp) async {
    try {
      final priceFetcher = OnRampPriceFetcherFactory.create(onRamp.type, ref);
      final price = await priceFetcher.fetchPrice(onRamp, ref);
      logger.debug("[Onramp] Price fetched for ${onRamp.name}: $price");
      return price;
    } catch (e) {
      logger.error("[Onramp] Price fetch error for ${onRamp.name}: $e");
      rethrow;
    }
  }

  String _baseUri(OnRampIntegration onRamp) {
    final isTestnet = ref.watch(envProvider) == Env.testnet;

    if (isTestnet && onRamp.refLinkTestnet != null) {
      return onRamp.refLinkTestnet!;
    }

    return onRamp.refLinkMainnet ?? '';
  }

  Future<Uri> formattedUri(OnRampIntegration onRamp) async {
    try {
      final baseUri = Uri.parse(_baseUri(onRamp));

      switch (onRamp.type) {
        case OnRampIntegrationType.meld:
          final receiveAddress =
              await ref.read(bitcoinProvider).getReceiveAddress();
          final key =
              ref.watch(meldEnvConfigProvider.select((env) => env.apiKey));
          final params = {
            if (receiveAddress != null) 'walletAddress': receiveAddress.address,
            'publicKey': key,
            'CurrencyCodeLocked': 'BTC'
          };
          final newUri = baseUri.replace(queryParameters: params);
          return newUri;
        default:
          return baseUri;
      }
    } catch (e) {
      rethrow;
    }
  }
}
