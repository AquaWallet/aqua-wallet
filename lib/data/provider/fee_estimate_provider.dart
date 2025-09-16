import 'dart:async';

import 'package:coin_cz/config/constants/urls.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/extensions/provider_extensions.dart';

final _logger = CustomLogger(FeatureFlag.fees);

enum TransactionPriority {
  high('1'),
  medium('3'),
  low('6'),
  min('1008');

  const TransactionPriority(this.value);

  final String value;
}

// fallback hardcoded rates in case blockstream call fails
const liquidFallbackFeeRates = 0.1;
const liquidFallbackFeeRatesLowball = 0.01;

enum FeeEstimateService { mempool, blockstream }

class FeeEstimateClient {
  FeeEstimateClient(this.ref);

  final ProviderRef ref;

  Future<Map<TransactionPriority, double>> fetchBitcoinFeeRates() async {
    return await ref.read(onChainFeeProvider.future);
  }

  /// Returns sats/vbyte
  double getLiquidFeeRate({bool isLowball = false}) {
    if (ref.read(envProvider) == Env.testnet) {
      return isLowball ? liquidFallbackFeeRatesLowball : liquidFallbackFeeRates;
    }

    return isLowball ? liquidFallbackFeeRatesLowball : liquidFallbackFeeRates;
  }

  Future<Map<TransactionPriority, double>> fetchMempoolFeeRates() async {
    final client = ref.read(dioProvider);
    const endpoint = '$mempoolSpaceUrl/fees/recommended';

    final response = await client.get(endpoint);
    final json = response.data as Map<String, dynamic>;
    return {
      TransactionPriority.high: json['fastestFee'].toDouble(),
      TransactionPriority.medium: json['halfHourFee'].toDouble(),
      TransactionPriority.low: json['hourFee'].toDouble(),
      TransactionPriority.min: json['minimumFee'].toDouble()
    };
  }
}

final feeEstimateProvider = Provider<FeeEstimateClient>(
  (ref) => FeeEstimateClient(ref),
);

final onChainFeeProvider =
    FutureProvider.autoDispose<Map<TransactionPriority, double>>((ref) async {
  ref.cacheFor(const Duration(seconds: 15));
  ref.refreshAfter(const Duration(seconds: 60));

  try {
    // fetch from mempool
    final fees = await ref.read(feeEstimateProvider).fetchMempoolFeeRates();
    _logger.debug("fetched from mempool: $fees");
    return fees;
  } catch (e) {
    // if mempool fetch fails, fetch from blockstream
    _logger.error('mempool request failed:', e);
    final fees =
        await ref.read(electrsProvider).fetchFeeRates(NetworkType.bitcoin);
    _logger.debug("fetched from blockstream: $fees");
    return fees;
  }
});

final liquidFeeRateProvider = FutureProvider<double>((ref) async {
  final client = ref.read(feeEstimateProvider);
  return client.getLiquidFeeRate();
});
