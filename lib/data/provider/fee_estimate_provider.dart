import 'dart:async';

import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/provider_extensions.dart';

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
const liquidLowballFeeRates = 0.01;

enum FeeEstimateService { mempool, blockstream }

class FeeEstimateClient {
  FeeEstimateClient(this.ref);

  final ProviderRef ref;

  Future<Map<TransactionPriority, double>> fetchBitcoinFeeRates(
      NetworkType network) async {
    return await ref.read(onChainFeeProvider.future);
  }

  /// Returns sats/vbyte
  double fetchLiquidFeeRate({bool isLowball = true}) {
    return isLowball ? liquidLowballFeeRates : liquidFallbackFeeRates;
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
  try {
    final fees = await ref.read(feeEstimateProvider).fetchMempoolFeeRates();
    logger.d("[Fees] fetched from mempool.space: $fees");
    ref.cacheFor(const Duration(seconds: 15));
    ref.refreshAfter(const Duration(seconds: 60));
    return fees;
  } catch (e) {
    logger.e('[Fees] mempool request failed:', e);
    final fees =
        await ref.read(electrsProvider).fetchFeeRates(NetworkType.bitcoin);
    logger.d("[Fees] fallback to blockstream: $fees");
    return fees;
  }
});

final liquidFeeRateProvider = FutureProvider<double>((ref) async {
  final client = ref.read(feeEstimateProvider);
  return client.fetchLiquidFeeRate();
});
