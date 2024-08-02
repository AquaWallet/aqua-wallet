import 'dart:async';

import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/features/marketplace/models/models.dart';
import 'package:aqua/features/settings/region/providers/region_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';

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

    final filteredIntegrations = OnRampIntegration.allIntegrations
        .where((integration) =>
            integration.allRegions ||
            integration.regions.any((r) => r.iso == region.iso))
        .toList();

    state = filteredIntegrations;
  }

  Future<String?> fetchPrice(OnRampIntegration onRamp) async {
    final client = ref.read(dioProvider);
    final uri = onRamp.priceApi;

    if (uri == null) return null;

    try {
      final response = await client.get(uri);
      logger.d("[Onramp] fetch price: $response for: ${onRamp.name}");

      return parseAndFormatPrice(onRamp, response);
    } on DioException catch (e) {
      logger.e(
          "[Onramp] on ramp dio error: ${e.response?.statusCode}, ${e.response?.data}");
      throw Exception(e);
    }
  }

  // Parse price response based on OnRampIntegration type. All providers will have different response formats.
  Future<String?> parseAndFormatPrice(
      OnRampIntegration onRamp, dynamic response) async {
    switch (onRamp.type) {
      case OnRampIntegrationType.beaverBitcoin:
        final data = response.data;
        final priceInCents = data['priceInCents'] as int;
        final price = (priceInCents / 100);
        final formatter = ref.read(currencyFormatProvider(0));
        return "${onRamp.priceSymbol}${formatter.format(price)}";
      case OnRampIntegrationType.pocketBitcoin:
        final data = response.data;
        final result = data['result']['XXBTZEUR'];
        final price = double.parse(
            result['a'][0]); // `['a'][0]` is the ask returned in quote
        final formatter = ref.read(currencyFormatProvider(0));
        return "${onRamp.priceSymbol}${formatter.format(price)}";
      default:
        return null;
    }
  }

  String _baseUri(OnRampIntegration onRamp) {
    final isTestnet = ref.watch(envProvider) == Env.testnet;

    if (isTestnet && onRamp.refLinkTestnet != null) {
      return onRamp.refLinkTestnet!;
    }

    return onRamp.refLinkMainnet;
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
