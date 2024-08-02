import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/data/provider/sideshift/sideshift_http_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

import 'models/sideshift.dart';

const liquidNetwork = 'liquid';
const bitcoinNetwork = 'bitcoin';
const btcId = 'btc-bitcoin';
const lbtcId = 'btc-liquid';
const usdtId = 'usdt-liquid';

// Errors /////////////////////////////////////////////////////////////////////

class DeliverAmountRequiredException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftDeliverAmountRequiredError;
  }
}

class DeliverAmountExceedBalanceException
    implements ExceptionLocalized, OrderError {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftDeliverAmountExceedBalanceError;
  }
}

class MinDeliverAmountException implements ExceptionLocalized, OrderError {
  MinDeliverAmountException(this.min, this.assetId);

  final Decimal min;
  final String assetId;

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftMinDeliverAmountError('$min');
  }
}

class MaxDeliverAmountException implements ExceptionLocalized, OrderError {
  MaxDeliverAmountException(this.max, this.assetId);

  final Decimal max;
  final String assetId;

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftMaxDeliverAmountError('$max');
  }
}

class FeeBalanceException implements ExceptionLocalized, OrderError {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.sideshiftFeeBalanceError;
  }
}

class ReceivingAddressException implements Exception {}

class RefundAddressException implements Exception {}

class MissingPairException implements Exception {}

class MissingPairInfoException implements Exception {}

// // Providers //////////////////////////////////////////////////////////////////

// Setup

final sideshiftSetupProvider = Provider.autoDispose
    .family<SideshiftSetupProvider, SideshiftAssetPair>((ref, pair) {
  return SideshiftSetupProvider(ref, pair);
});

class SideshiftSetupProvider {
  final ProviderRef ref;
  final SideshiftAssetPair currentPair;

  SideshiftSetupProvider(this.ref, this.currentPair);

  // Setup Order - check permissions and get pair info
  Stream<AsyncValue<bool>> setupSideshiftOrder() async* {
    yield const AsyncValue.loading();

    final sideshiftHttp = ref.read(sideshiftHttpProvider);

    try {
      // Fetch permissions and pairInfo in parallel
      final results = await Future.wait([
        sideshiftHttp.checkPermissions(),
        sideshiftHttp.fetchSideShiftAssetPair(currentPair.from, currentPair.to)
      ]);

      final permissionsResponse = results[0] as SideshiftPermissionsResponse;
      final pairInfoReponse = results[1] as SideShiftAssetPairInfo;

      // No permission error
      if (!permissionsResponse.createShift) {
        logger.d("[SideShift] Permission exception triggered");
        yield AsyncValue.error(NoPermissionsException(), StackTrace.empty);
        return;
      }

      // Cache pair info
      ref.read(sideshiftCurrentPairInfoProvider.notifier).state =
          pairInfoReponse;
      logger.d(
          "[SideShift] Pair ${pairInfoReponse.settleCoin}/${pairInfoReponse.depositCoin} has min/max amounts: ${pairInfoReponse.min}/${pairInfoReponse.max}");

      yield const AsyncData(true);
    } catch (error) {
      logger.e("[SideShift] Error occurred: $error", error, StackTrace.current);
      yield AsyncValue.error(error, StackTrace.current);
    }
  }
}

// Pairs

/// Caches current pair info
final sideshiftCurrentPairInfoProvider =
    StateProvider.autoDispose<SideShiftAssetPairInfo?>((ref) => null);

/// Fetches pair info from SideShift API, used to calculate min/max amounts
final sideshiftPairInfoProvider = FutureProvider.autoDispose
    .family<SideShiftAssetPairInfo, SideshiftAssetPair>((ref, pair) async {
  return ref
      .read(sideshiftHttpProvider)
      .fetchSideShiftAssetPair(pair.from, pair.to)
      .then((pairInfo) {
    ref.read(sideshiftCurrentPairInfoProvider.notifier).state = pairInfo;
    logger.d('[SideShift] Pair info: ${pairInfo.toJson()}');
    return pairInfo;
  }).catchError((e) {
    logger.e('[SideShift] Pair info error: $e');
    return e;
  });
});

// Assets list

/// Fetches all available coins from SideShift API
final sideShiftAssetsListProvider =
    FutureProvider.autoDispose<List<SideshiftAsset>>(
  (ref) async {
    return await ref.read(sideshiftHttpProvider).fetchSideShiftAssetsList();
  },
);

// SideShiftAsset to Asset conversion
final assetConverterProvider =
    Provider.autoDispose.family<Asset?, SideshiftAsset>((ref, shiftAsset) {
  final value = ref.watch(assetsProvider);
  final assets = value.asData?.value ?? [];
  return assets.firstWhereOrNull((e) {
    final isLbtc = e.isLBTC && shiftAsset.id == lbtcId;
    final isBtc = e.isBTC && shiftAsset.id == btcId;
    final isUsdt = e.isUSDt && shiftAsset.id == usdtId;
    return e.id == shiftAsset.coin || isLbtc || isBtc || isUsdt;
  });
});

// Wallet balance

class WalletBalanceProvider {
  final AutoDisposeProviderRef ref;

  WalletBalanceProvider(this.ref);

  /// Fetches user balance for an asset
  Future<Decimal?> getWalletBalance(SideshiftAsset shiftAsset) async {
    final asset = ref.watch(assetConverterProvider(shiftAsset));
    logger.d(
        '[SideShift] wallet balance provider - Asset amount (${asset?.amount})');

    if (asset == null) {
      return null;
    }

    final balance = DecimalExt.satsToDecimal(asset.amount, asset.precision);
    logger.d('[SideShift] wallet balance provider - Asset ($balance)');
    return balance;
  }
}

final walletBalanceProvider =
    Provider.autoDispose<WalletBalanceProvider>((ref) {
  return WalletBalanceProvider(ref);
});
