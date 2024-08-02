import 'dart:async';

import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:rxdart/rxdart.dart';

// Note: This only accounts for the first tx fee.
// - ie, if you're pegging in, it only accounts for the btc fee to send to sideswap. Sideswap will then take out their fee and also the liquid fee for the second tx, which is minimal.
// - This is more notable when pegging out, because the second fee is a btc fee. In Sideswap app they have a fee rate selector so they know how much this second btc tx fee will be.
//   However, their api doesn't have this, so we don't know what the fee rate will be for the btc tx on peg-out. Therefore we don't include it but instead for now have a user prompt
//   warning of this.
final amountMinusChainFeeEstProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final input = ref.watch(sideswapInputStateProvider);
  final deliverAsset = input.deliverAsset;
  final balance = input.deliverAsset?.amount;
  final amount = input.deliverAmountSatoshi;

  if (amount == 0) {
    return 0;
  }

  if (input.deliverAsset == null) {
    logger.e('[PEG] ERROR: No deliver asset found');
    throw Exception('No deliverasset asset found');
  }

  final pegState = ref.read(pegProvider).valueOrNull;
  String? address;

  // if there's an order, use that pegAddress
  // if not, use a hardcoded sideswap multisig address for the estimate so fees match
  if (pegState is PegStateVerify) {
    address = pegState.data.order.pegAddress;
  } else {
    address = input.deliverAsset!.isLBTC
        ? "VJLELdbiVkhDvxHNnnJmdFzgipz66YtuGMphDR5FEuipCoDuoEArXDwHR8k2mgfHdaf7xcVLB2p3uuVU"
        : "bc1qq3s96g0x4pemmfgjy8k345wk4zazf57yk8kgjtp9uwerjgxz5n3sndxg2e";
  }

  final fee = await ref.watch(sideSwapFeeCalculatorProvider).pegFeeEstimate(
        amount,
        deliverAsset!,
        address,
        isSendAll: input.isSendAll,
      );

  final amountMinusFee = amount - fee;

  if (balance != null && fee > balance) {
    logger.d('[PEG] Fee ($fee) exceeds balance ($balance)');
    throw PegGdkInsufficientFeeBalanceException();
  }

  // this prevents showing a negative receive asset amount
  if (fee > amount) {
    logger.d('[PEG] Fee ($fee) exceeds amount ($amount)');
    throw PegGdkFeeExceedingAmountException();
  }

  logger.d(
      '[PEG] Input Amount: $amount - Fee: $fee =  Net Amount (sideswap fee not included): $amountMinusFee');
  return amountMinusFee;
});

final pegFeeRatesProvider =
    AutoDisposeAsyncNotifierProvider<PegFeeRatesNotifier, Map<Asset, double>>(
        PegFeeRatesNotifier.new);

class PegFeeRatesNotifier extends AutoDisposeAsyncNotifier<Map<Asset, double>> {
  @override
  FutureOr<Map<Asset, double>> build() async {
    logger.d('[PEG] Initializing...');
    final assets = ref.read(assetsProvider).asData?.value ?? <Asset>[];
    return Stream.fromIterable(assets)
        .where((asset) => asset.isBTC || asset.isLBTC)
        .asyncMap<MapEntry<Asset, double>?>((asset) async {
          final networkType =
              asset.isLBTC ? NetworkType.liquid : NetworkType.bitcoin;
          final feeEstimates = asset.isLBTC
              ? ref.read(feeEstimateProvider).fetchLiquidFeeRate()
              : await ref
                  .read(feeEstimateProvider)
                  .fetchBitcoinFeeRates(networkType);

          final fee = asset.isLBTC
              ? feeEstimates as double
              : (feeEstimates as Map<TransactionPriority, double>)[
                  TransactionPriority.high]!;

          logger.d('[PEG] Fee for ${asset.ticker}: $fee');
          return MapEntry(asset, fee);
        })
        .onErrorReturn(null)
        .whereNotNull()
        .fold({}, (prev, entry) => prev..addEntries([entry]));
  }
}

final sideSwapFeeCalculatorProvider =
    AutoDisposeProvider<SideSwapFeeCalculator>((ref) {
  return SideSwapFeeCalculator(ref);
});

class SideSwapFeeCalculator {
  final ProviderRef ref;

  SideSwapFeeCalculator(this.ref);

  Future<int> pegFeeEstimate(int amountInSats, Asset asset, String pegAddress,
      {bool isSendAll = false}) async {
    final txn = await ref.read(pegProvider.notifier).createPegGdkTransaction(
          asset: asset,
          pegAddress: pegAddress,
          deliverAmountSatoshi: amountInSats,
          isSendAll: isSendAll,
          relayErrors: false,
        );

    if (txn == null || txn.fee == null) {
      throw PegGdkTransactionException;
    }

    logger.d("[Peg] Tx Fee Estimate: ${txn.fee}");
    return txn.fee!;
  }

  /// Calculates value of peg deliver amount minus the sideswap fee (this does not account for on chain fee)
  static int subtractSideSwapFeeForPegDeliverAmount(
      int deliverAmount, bool isPegIn, ServerStatusResult? statusStream) {
    // service fee comes back as "0.1" from sideswap which is 0.1%
    final amount = deliverAmount.toDouble();
    final serviceFee = isPegIn
        ? statusStream?.serverFeePercentPegIn ?? 0.1
        : statusStream?.serverFeePercentPegOut ?? 0.1;
    final feeMultiplier = 1 - (serviceFee / 100);
    final amountAfterSideSwapFeeDedcution = amount * feeMultiplier;
    logger.d(
        '[Peg] Amount (minus onchain fee): $amount * $feeMultiplier = Amount (minus sideswap fee): $amountAfterSideSwapFeeDedcution');
    return amountAfterSideSwapFeeDedcution.toInt();
  }
}

final minPegInAmountWithFeeProvider = Provider.autoDispose<int>((ref) {
  final statusStream = ref.watch(sideswapStatusStreamResultStateProvider);
  final minPegInAmountSat = statusStream?.minPegInAmount;
  final pegInServiceFee = statusStream?.serverFeePercentPegIn;

  final minPegInAmountSatWithFee = minPegInAmountSat != null &&
          pegInServiceFee != null
      ? (minPegInAmountSat + (minPegInAmountSat * pegInServiceFee / 100)).ceil()
      : null;
  return minPegInAmountSatWithFee ?? 0;
});

final minPegOutAmountWithFeeProvider = Provider.autoDispose<int>((ref) {
  final statusStream = ref.watch(sideswapStatusStreamResultStateProvider);
  final minPegOutAmountSat = statusStream?.minPegOutAmount;
  final pegOutServiceFee = statusStream?.serverFeePercentPegOut;

  final minPegOutAmountSatWithFee =
      minPegOutAmountSat != null && pegOutServiceFee != null
          ? (minPegOutAmountSat + (minPegOutAmountSat * pegOutServiceFee / 100))
              .ceil()
          : null;
  return minPegOutAmountSatWithFee ?? 0;
});
