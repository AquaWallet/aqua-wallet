import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.swap);

/// A provider that determines which swap service to use for a given pair
final swapServiceResolverProvider =
    Provider.family<SwapServiceSource, SwapPair>((ref, pair) {
  if (pair.from.isUSDt() && pair.to.isUSDt()) {
    final preferredService = ref.watch(preferredUsdtSwapServiceProvider);
    return preferredService.when(
      data: (service) => service,
      loading: () {
        _logger
            .debug('Preferred USDT service loading, defaulting to Changelly');
        return SwapServiceSource.changelly;
      },
      error: (_, __) {
        _logger.error(
            'Error getting preferred USDT service, defaulting to Changelly');
        return SwapServiceSource.changelly;
      },
    );
  }

  return SwapServiceSource.changelly;
});
