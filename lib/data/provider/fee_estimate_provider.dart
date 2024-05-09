import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

enum TransactionPriority {
  high('1'),
  medium('3'),
  low('6'),
  min('1008');

  const TransactionPriority(this.value);

  final String value;
}

enum FeeEstimateService { mempool, blockstream }

class FeeEstimateClient {
  FeeEstimateClient(this.ref);

  final ProviderRef ref;

  // If liquid, fetch from blockstream.
  // If btc try mempool.space first, then fallback to blockstream.
  Future<Map<TransactionPriority, double>> fetchFeeRates(
      NetworkType network) async {
    if (network == NetworkType.liquid) {
      return await ref.read(electrsProvider).fetchFeeRates(network);
    }

    try {
      final fees = await fetchMempoolFeeRates();
      logger.d("[Fees] fetched from mempool.space: $fees");
      return fees;
    } catch (_) {
      final fees = await ref.read(electrsProvider).fetchFeeRates(network);
      logger.d("[Fees] mempool fetch failed - fetched from blockstream: $fees");
      return fees;
    }
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
