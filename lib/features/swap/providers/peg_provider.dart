import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';

final pegProvider =
    AutoDisposeAsyncNotifierProvider<PegNotifier, PegState>(PegNotifier.new);

class PegNotifier extends AutoDisposeAsyncNotifier<PegState> {
  @override
  FutureOr<PegState> build() => const PegState.empty();

  Future<void> requestVerification(SwapStartPegResponse response) async {
    final order = response.result!;
    final isLiquid =
        await ref.read(addressParserProvider).isValidAddressForAsset(
              asset: ref.read(manageAssetsProvider).lbtcAsset,
              address: order.pegAddress,
            );
    final assets = ref.read(assetsProvider).asData?.value ?? [];
    final asset = assets.firstWhere((e) => isLiquid ? e.isLBTC : e.isBTC);
    final input = ref.read(sideswapInputStateProvider);
    final statusStream = ref.read(sideswapStatusStreamResultStateProvider);

    final txn = await createPegGdkTransaction(
      asset: asset,
      pegAddress: order.pegAddress,
      isSendAll: input.isSendAll,
      deliverAmountSatoshi: input.deliverAmountSatoshi,
    );

    if (txn == null) {
      logger.d('[PEG] Transaction cannot be created');
      final error = PegGdkTransactionException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }

    final firstOnchainFee = txn.fee!;
    final inputAmount = input.deliverAmountSatoshi;
    final amountMinusOnchainFee = inputAmount - firstOnchainFee;

    final feeEstimates = asset.isLBTC
        ? ref.read(feeEstimateProvider).getLiquidFeeRate()
        : (await ref
            .read(feeEstimateProvider)
            .fetchBitcoinFeeRates())[TransactionPriority.high]!;

    final amountMinusSideSwapFee =
        SideSwapFeeCalculator.subtractSideSwapFeeForPegDeliverAmount(
            amountMinusOnchainFee, input.isPegIn, statusStream, feeEstimates);

    final secondOnchainFee = asset.isBTC
        ? SideSwapFeeCalculator.estimatedPegInSecondFee(feeEstimates)
        : SideSwapFeeCalculator.estimatedPegOutSecondFee(feeEstimates);

    logger.d(
        "[Peg] Verifying Order - Input Amount: $inputAmount - First onchain Fee: $firstOnchainFee - Second onchain Fee: $secondOnchainFee - Amount (minus onchain fee): $amountMinusOnchainFee - Amount (minus sideswap fee): $amountMinusSideSwapFee");

    if (firstOnchainFee > inputAmount) {
      logger.d('[PEG] Fee ($firstOnchainFee) exceeds amount ($inputAmount)');
      final error = PegGdkFeeExceedingAmountException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }

    final data = SwapPegReviewModel(
      asset: asset,
      order: order,
      transaction: txn,
      inputAmount: inputAmount,
      feeAmount: firstOnchainFee + secondOnchainFee,
      sendTxAmount: amountMinusOnchainFee,
      receiveAmount: amountMinusSideSwapFee.toInt(),
      isSendAll: input.isSendAll,
    );
    state = AsyncData(PegState.pendingVerification(data: data));
  }

  Future<void> executeTransaction() async {
    final currentState = state.asData?.value;
    if (currentState is PegStateVerify) {
      final data = currentState.data;
      final amount = data.sendTxAmount;
      final statusStream = ref.read(sideswapStatusStreamResultStateProvider);

      final minBtcAmountSatoshi = statusStream?.minPegInAmount;
      final minLbtcAmountSatoshi = statusStream?.minPegOutAmount;
      if (minBtcAmountSatoshi != null &&
          data.asset.isBTC &&
          amount < minBtcAmountSatoshi) {
        logger.d('[PEG] BTC amount too low (min: $minBtcAmountSatoshi))');
        final error = PegSideSwapMinBtcLimitException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
      if (minLbtcAmountSatoshi != null &&
          data.asset.isLBTC &&
          amount < minLbtcAmountSatoshi) {
        logger.d('[PEG] L-BTC amount too low (min: $minLbtcAmountSatoshi))');
        final error = PegSideSwapMinLBtcLimitException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }

      logger.d(
          "[Sideswap][Peg] created tx - asset: ${data.asset.ticker} - amount: $amount - isSendAll: ${data.isSendAll} - pegAddress: ${data.order.pegAddress} - reply: ${data.transaction}");

      final transaction =
          await signPegGdkTransaction(data.transaction, data.asset);
      if (transaction == null) {
        final error = PegGdkTransactionException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      } else {
        await ref
            .read(transactionStorageProvider.notifier)
            .save(TransactionDbModel(
              txhash: transaction.txhash!,
              assetId: data.asset.id,
              type: ref.read(sideswapInputStateProvider).isPegIn
                  ? TransactionDbModelType.sideswapPegIn
                  : TransactionDbModelType.sideswapPegOut,
              serviceOrderId: data.order.orderId,
              serviceAddress: data.order.pegAddress,
            ));
        state = AsyncValue.data(PegState.success(
          asset: data.asset,
          txn: data.transaction,
          orderId: data.order.orderId,
        ));
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
    bool isLowball = true,
  }) async {
    try {
      final network =
          asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);

      final addressee = GdkAddressee(
          assetId: asset.isBTC ? null : asset.id,
          address: pegAddress,
          satoshi: deliverAmountSatoshi,
          isGreedy: isSendAll);

      final feeEstimateVb = asset.isLBTC
          ? ref.read(feeEstimateProvider).getLiquidFeeRate()
          : (await ref
              .read(feeEstimateProvider)
              .fetchBitcoinFeeRates())[TransactionPriority.high]!;
      final feeEstimateKb = (feeEstimateVb * 1000).ceil();

      final transaction = GdkNewTransaction(
        addressees: [addressee],
        feeRate: feeEstimateKb,
        utxoStrategy: GdkUtxoStrategyEnum.defaultStrategy,
      );

      final txReply = await network.createTransaction(transaction: transaction);
      logger.d(
          "[Peg] Create Gdk Tx - deliverAmountSatoshi $deliverAmountSatoshi - fee ${txReply?.fee} - feeRatePerKb $feeEstimateKb - isSendAll: $isSendAll");
      return txReply;
    } on GdkNetworkInsufficientFunds {
      logger.d('[PEG] Insufficient funds');
      if (relayErrors) {
        final error = PegGdkInsufficientFeeBalanceException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
    } catch (e) {
      if (relayErrors) {
        logger.e('[PEG] create gdk tx error: $e');
        final error = PegGdkTransactionException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
    }

    return null;
  }

  Future<GdkNewTransactionReply?> signPegGdkTransaction(
      GdkNewTransactionReply reply, Asset asset,
      {bool isLowball = true}) async {
    try {
      final network =
          asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);

      final blindedTx = asset.isBTC
          ? reply
          : await ref.read(liquidProvider).blindTransaction(reply);
      if (blindedTx == null) {
        throw PegGdkTransactionException();
      }

      final signedReply = await network.signTransaction(blindedTx);
      if (signedReply == null || signedReply.transaction == null) {
        throw PegGdkTransactionException();
      }

      // if liquid, try lowball. if fail, try again without lowball
      try {
        if (ref.read(featureFlagsProvider).fakeBroadcastsEnabled) {
          return signedReply;
        }

        await ref.read(electrsProvider).broadcast(signedReply.transaction!,
            asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid,
            isLowball: !asset.isBTC);
      } on AquaTxBroadcastException {
        if (asset.isBTC) {
          assert(false, 'BTC should not be broadcasted through aqua');
          final error = PegGdkTransactionException();
          state = AsyncValue.error(error, StackTrace.current);
          throw error;
        }

        signAndSendNonLowballTx(reply);
      }

      return signedReply;
    } catch (e) {
      logger.e('[PEG] sign/send gdk tx error: $e');
      final error = PegGdkTransactionException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
  }

  Future<void> signAndSendNonLowballTx(GdkNewTransactionReply lowballTx) async {
    final nonLowballFeeKb =
        ref.read(feeEstimateProvider).getLiquidFeeRate(isLowball: false) * 1000;
    final nonLowbalTx = lowballTx.copyWith(feeRate: nonLowballFeeKb.toInt());
    final blindedTx =
        await ref.read(liquidProvider).blindTransaction(nonLowbalTx);
    if (blindedTx == null) {
      throw PegGdkTransactionException();
    }
    final signedReply =
        await ref.read(liquidProvider).signTransaction(blindedTx);
    if (signedReply == null || signedReply.transaction == null) {
      throw PegGdkTransactionException();
    }

    if (ref.read(featureFlagsProvider).fakeBroadcastsEnabled) {
      return;
    }

    await ref.read(electrsProvider).broadcast(
        signedReply.transaction!, NetworkType.liquid,
        isLowball: false);
  }
}

sealed class PegError implements Exception {}

class PegGdkInsufficientFeeBalanceException extends PegError {}

class PegGdkFeeExceedingAmountException extends PegError {}

class PegGdkTransactionException extends PegError {}

class PegSideSwapMinBtcLimitException extends PegError {}

class PegSideSwapMinLBtcLimitException extends PegError {}
