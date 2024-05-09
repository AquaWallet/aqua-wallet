import 'dart:async';

import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:rxdart/rxdart.dart';

final maxPegFeeDeductedAmountProvider =
    Provider.autoDispose<AsyncValue<int>>((ref) {
  final feeMap = ref.watch(maxPegFeeProvider).asData?.value ?? {};
  final input = ref.watch(sideswapInputStateProvider);
  final deliverAsset = input.deliverAsset;
  final balance = input.deliverAsset?.amount;
  final amount = input.deliverAmountSatoshi;

  if (amount == 0) {
    return const AsyncValue.data(0);
  }

  final fee = feeMap[deliverAsset];
  if (fee == null) {
    logger.d('[PEG] ERROR: No fee found for asset ${deliverAsset?.ticker}');
    return AsyncValue.error(
      Exception('No fee found for asset ${deliverAsset?.ticker}'),
      StackTrace.current,
    );
  }

  final feeDeductedAmount = amount - fee;
  logger.d(
      '[PEG] Fee: $fee, Gross Amount: $amount, Net Amount: $feeDeductedAmount');

  if (balance != null && fee > balance) {
    logger.d('[PEG] Fee ($fee) exceeds balance ($balance)');
    return AsyncValue.error(
      PegGdkInsufficientFeeBalanceException(),
      StackTrace.current,
    );
  }

  // this prevents showing a negative receive asset amount
  if (fee > amount) {
    logger.d('[PEG] Fee ($fee) exceeds amount ($amount)');
    return AsyncValue.error(
      PegGdkFeeExceedingAmountException(),
      StackTrace.current,
    );
  }

  logger.d(
      '[PEG] Fee Deducted Amount: $feeDeductedAmount ($feeDeductedAmount / ${fee > amount})');
  return AsyncValue.data(feeDeductedAmount);
});

final maxPegFeeProvider =
    AutoDisposeAsyncNotifierProvider<MaxPegFeeNotifier, Map<Asset, int>>(
        MaxPegFeeNotifier.new);

class MaxPegFeeNotifier extends AutoDisposeAsyncNotifier<Map<Asset, int>> {
  @override
  FutureOr<Map<Asset, int>> build() async {
    logger.d('[PEG] Initializing...');
    final assets = ref.read(assetsProvider).asData?.value ?? <Asset>[];
    return Stream.fromIterable(assets)
        .where((asset) => asset.isBTC || asset.isLBTC)
        .asyncMap<MapEntry<Asset, int>?>((asset) async {
          final network = asset.isLBTC
              ? ref.read(liquidProvider)
              : ref.read(bitcoinProvider);
          final address = await network.getReceiveAddress();
          final pegAddress = address?.address;

          if (pegAddress == null) {
            logger.d('[PEG] ERROR: No address found');
            throw Exception('No address found');
          }

          final txn =
              await ref.read(pegProvider.notifier).createPegGdkTransaction(
                    asset: asset,
                    pegAddress: pegAddress,
                    deliverAmountSatoshi: asset.amount,
                    isSendAll: true,
                    relayErrors: false,
                  );

          if (txn == null) {
            logger.d(
                '[PEG] Transaction cannot be created (asset: ${asset.ticker})');
            throw PegGdkTransactionException();
          }

          final fee = txn.fee!;
          logger.d('[PEG] Fee for ${asset.ticker}: $fee');
          return MapEntry(asset, fee);
        })
        .onErrorReturn(null)
        .whereNotNull()
        .fold({}, (prev, entry) => prev..addEntries([entry]));
  }
}
