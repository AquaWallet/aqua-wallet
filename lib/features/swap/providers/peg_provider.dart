import 'dart:async';
import 'dart:developer';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

const minBtcAmountSatoshi = 10000;
const minLbtcAmountSatoshi = 100000;
const onePercent = 0.01;

// Problem: When user executes a non-sendAll peg, the fee amount is added on
// top of the deliver amount. The expected behavior is to deduct the fee
// from the deliver amount. E.g. if 0.0001 is being converted and the fee is
// 0.00001, the user should receive 0.00009.
//
// The problem in designing this flow is that the fee is known only after
// the GDK Transaction is created. This means we will need to create the
// transaction twice, once to get the fee, and once to sign the transaction
// with the amount exclusive of the fee.

final pegProvider =
    AutoDisposeAsyncNotifierProvider<PegNotifier, PegState>(PegNotifier.new);

class PegNotifier extends AutoDisposeAsyncNotifier<PegState> {
  @override
  FutureOr<PegState> build() => const PegState.empty();

  Future<void> requestVerification(SwapStartPegResponse response) async {
    final order = response.result!;
    final isLiquid =
        await ref.read(addressParserProvider).isValidAddressForAsset(
              asset: Asset.liquid(),
              address: order.pegAddress,
            );
    final assets = ref.read(assetsProvider).asData?.value ?? [];
    final asset = assets.firstWhere((e) => isLiquid ? e.isLBTC : e.isBTC);
    final input = ref.read(sideswapInputStateProvider);

    final txn = await createPegGdkTransaction(
      asset: asset,
      pegAddress: order.pegAddress,
      isSendAll: input.isSendAll,
      deliverAmountSatoshi: input.deliverAmountSatoshi,
    );

    if (txn == null) {
      log('[PEG] Transaction cannot be created');
      final error = PegGdkTransactionException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }

    final fee = txn.fee!;
    final deliverAmount = input.deliverAmountSatoshi;
    final feeDeductedAmount = deliverAmount - fee;
    // this is the sideswap fee. This should ideally come from the value we
    // get from the `server_status` call to sideswap. but putting this in for
    // now do we are accurate in predicting how much btc/lbtc comes back to
    // the user.
    final finalAmountAfterSideSwapFee = feeDeductedAmount * .98;

    if (fee > deliverAmount) {
      log('[PEG] Fee ($fee) exceeds amount ($deliverAmount)');
      final error = PegGdkFeeExceedingAmountException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }

    final data = SwapPegReviewModel(
      asset: asset,
      order: order,
      transaction: txn,
      deliverAmount: deliverAmount,
      feeAmount: fee,
      finalAmount: finalAmountAfterSideSwapFee.toInt(),
      isSendAll: input.isSendAll,
    );
    state = AsyncData(PegState.pendingVerification(data: data));
  }

  Future<void> executeTransaction() async {
    final currentState = state.asData?.value;
    if (currentState is PegStateVerify) {
      final data = currentState.data;
      final amount = data.finalAmount;
      if (data.asset.isBTC && amount < minBtcAmountSatoshi) {
        log('[PEG] BTC amount too low (min: $minBtcAmountSatoshi))');
        final error = PegSideSwapMinBtcLimitException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
      if (data.asset.isLBTC && amount < minLbtcAmountSatoshi) {
        log('[PEG] L-BTC amount too low (min: $minLbtcAmountSatoshi))');
        final error = PegSideSwapMinLBtcLimitException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
      final reply = await createPegGdkTransaction(
        asset: data.asset,
        pegAddress: data.order.pegAddress,
        isSendAll: data.isSendAll,
        deliverAmountSatoshi: amount,
      );
      final transaction = await signPegGdkTransaction(reply!, data.asset);
      if (transaction == null) {
        final error = PegGdkTransactionException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      } else {
        state = const AsyncValue.data(PegState.success());
      }
    } else {
      throw Exception('Invalid state: $state');
    }
  }

  Future<GdkNewTransactionReply?> createPegGdkTransaction({
    required Asset asset,
    required String pegAddress,
    required bool isSendAll,
    required int deliverAmountSatoshi,
    bool relayErrors = true,
  }) async {
    try {
      final network =
          asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);

      final addressee = GdkAddressee(
        assetId: asset.id,
        address: pegAddress,
        satoshi: deliverAmountSatoshi,
      );

      final transaction = GdkNewTransaction(
        addressees: [addressee],
        feeRate: await network.getDefaultFees(),
        sendAll: isSendAll,
        utxoStrategy: GdkUtxoStrategyEnum.defaultStrategy,
      );

      return await network.createTransaction(transaction);
    } on GdkNetworkInsufficientFunds {
      log('[PEG] Insufficient funds');
      if (relayErrors) {
        final error = PegGdkInsufficientFeeBalanceException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
    } catch (e) {
      log('[PEG] Generic exception');
    }
    return null;
  }

  Future<GdkNewTransactionReply?> signPegGdkTransaction(
    GdkNewTransactionReply reply,
    Asset asset,
  ) async {
    final network =
        asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);
    final signedReply = await network.signTransaction(reply);
    if (signedReply != null) {
      final response = await network.sendTransaction(signedReply);
      if (response != null) {
        return response;
      }
    }
    return null;
  }
}

sealed class PegError implements Exception {}

class PegGdkInsufficientFeeBalanceException extends PegError {}

class PegGdkFeeExceedingAmountException extends PegError {}

class PegGdkTransactionException extends PegError {}

class PegSideSwapMinBtcLimitException extends PegError {}

class PegSideSwapMinLBtcLimitException extends PegError {}
