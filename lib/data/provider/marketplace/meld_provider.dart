import 'package:coin_cz/logger.dart';
import 'package:coin_cz/features/shared/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meld_provider.g.dart';

//NOTE: There are extensive Meld testing docs here: https://docs.meld.io/docs/crypto-testing-guide
@riverpod
Uri meldUri(Ref ref, String? receiveAddress) {
  final uri = ref.watch(meldEnvConfigProvider.select((env) => env.apiUrl));
  final key = ref.watch(meldEnvConfigProvider.select((env) => env.apiKey));
  logger.info("[ENV] using meld base uri: $uri");

  final baseUri = Uri.parse(uri);
  final params = {
    if (receiveAddress != null) 'walletAddress': receiveAddress,
    'publicKey': key,
    'destinationCurrencyCodeLocked': 'BTC'
  };
  final newUri = baseUri.replace(queryParameters: params);
  return newUri;
}
