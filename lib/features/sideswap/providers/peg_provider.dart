import 'dart:async';

import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/address_validator/address_validation.dart';
import 'package:coin_cz/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:coin_cz/features/settings/manage_assets/manage_assets.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.peg);

final pegProvider =
    AutoDisposeAsyncNotifierProvider<PegNotifier, PegState>(PegNotifier.new);

class PegNotifier extends AutoDisposeAsyncNotifier<PegState> {
  @override
  FutureOr<PegState> build() => const PegState.empty();

  //ANCHOR: Order Creation
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
      _logger.debug('Transaction cannot be created');
      final error = PegGdkTransactionException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }

    final sendAssetNetworkFee = txn.fee!;
    final inputAmount = input.deliverAmountSatoshi;
    final amountMinusOnchainFee = inputAmount - sendAssetNetworkFee;

    final receiveAssetNetworkFeeRate = input.receiveAsset!.isLBTC
        ? ref.read(feeEstimateProvider).getLiquidFeeRate()
        : (await ref
            .read(feeEstimateProvider)
            .fetchBitcoinFeeRates())[TransactionPriority.high]!;

    final amountMinusSideSwapFee =
        SideSwapFeeCalculator.subtractSideSwapFeeForPegDeliverAmount(
            amountMinusOnchainFee,
            input.isPegIn,
            statusStream,
            receiveAssetNetworkFeeRate);

    final receiveAssetNetworkFee = asset.isBTC
        ? SideSwapFeeCalculator.estimatedPegInSecondFee()
        : SideSwapFeeCalculator.estimatedPegOutSecondFee(
            receiveAssetNetworkFeeRate);

    logger.debug(
        "Verifying Order - Input Amount: $inputAmount - First onchain Fee: $sendAssetNetworkFee - Second onchain Fee: $receiveAssetNetworkFee - Amount (minus onchain fee): $amountMinusOnchainFee - Amount (minus sideswap fee): $amountMinusSideSwapFee");

    if (sendAssetNetworkFee > inputAmount) {
      logger.debug('Fee ($sendAssetNetworkFee) exceeds amount ($inputAmount)');
      final error = PegGdkFeeExceedingAmountException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }

    final data = SwapPegReviewModel(
      asset: asset,
      order: order,
      transaction: txn,
      inputAmount: inputAmount,
      firstOnchainFeeAmount: sendAssetNetworkFee,
      secondOnchainFeeAmount: receiveAssetNetworkFee,
      sendTxAmount: amountMinusOnchainFee,
      receiveAmount: amountMinusSideSwapFee.toInt(),
      isSendAll: input.isSendAll,
    );

    await _cachePegOrder(data);

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
        logger.debug('BTC amount too low (min: $minBtcAmountSatoshi))');
        final error = PegSideSwapMinBtcLimitException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
      if (minLbtcAmountSatoshi != null &&
          data.asset.isLBTC &&
          amount < minLbtcAmountSatoshi) {
        logger.debug('L-BTC amount too low (min: $minLbtcAmountSatoshi))');
        final error = PegSideSwapMinLBtcLimitException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }

      logger.debug(
          "[Sideswap]created tx - asset: ${data.asset.ticker} - amount: $amount - isSendAll: ${data.isSendAll} - pegAddress: ${data.order.pegAddress} - reply: ${data.transaction}");

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
              // second chain fee is estimated at the TX execution time
              // because fee rates vary we must save the estimated one in TX DB
              estimatedFee:
                  data.firstOnchainFeeAmount + data.secondOnchainFeeAmount,
              serviceOrderId: data.order.orderId,
              serviceAddress: data.order.pegAddress,
            ));

        await _updateCachedPegOrder(data.order.orderId, transaction);

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

  //ANCHOR: Caching
  Future<void> _cachePegOrder(SwapPegReviewModel data) async {
    final isPegIn = ref.read(sideswapInputStateProvider).isPegIn;
    final pegOrder = PegOrderDbModel.fromStatus(
      orderId: data.order.orderId,
      isPegIn: isPegIn,
      amount: data.inputAmount,
      status: SwapPegStatusResult(
        orderId: data.order.orderId,
        pegIn: isPegIn,
        addr: data.order.pegAddress,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        transactions: [],
      ),
      createdAt: DateTime.now(),
    );
    await ref.read(pegStorageProvider.notifier).save(pegOrder);
    logger.debug(
        '[Sideswap]Cached initial peg order: ${pegOrder.orderId}, Amount: ${pegOrder.amount}, IsPegIn: ${pegOrder.isPegIn}');
  }

  Future<void> _updateCachedPegOrder(
      String orderId, GdkNewTransactionReply transaction) async {
    final existingOrder =
        await ref.read(pegStorageProvider.notifier).getOrderById(orderId);
    if (existingOrder != null) {
      final updatedStatus = existingOrder.status.copyWith(
        transactions: [
          PegStatusTxns(
            txHash: transaction.txhash,
            amount: transaction.satoshi?.values.first,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            txState: PegTxState.detected,
          ),
        ],
      );
      final updatedOrder = existingOrder.copyWithStatus(updatedStatus);
      await ref.read(pegStorageProvider.notifier).save(updatedOrder);
      logger.debug(
          '[Sideswap]Updated cached peg order: $orderId, TxHash: ${transaction.txhash}, Amount: ${transaction.satoshi?.values.first}');
    } else {
      logger.warning(
          '[Sideswap]Attempted to update non-existent peg order: $orderId');
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
      logger.debug(
          "Create Gdk Tx - deliverAmountSatoshi $deliverAmountSatoshi - fee ${txReply?.fee} - feeRatePerKb $feeEstimateKb - isSendAll: $isSendAll");
      return txReply;
    } on GdkNetworkInsufficientFunds {
      logger.debug('Insufficient funds');
      if (relayErrors) {
        final error = PegGdkInsufficientFeeBalanceException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
    } catch (e) {
      if (relayErrors) {
        logger.error('create gdk tx error: $e');
        final error = PegGdkTransactionException();
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
    }

    return null;
  }

  Future<GdkNewTransactionReply?> signPegGdkTransaction(
      GdkNewTransactionReply reply, Asset asset) async {
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

      if (ref.read(featureFlagsProvider).fakeBroadcastsEnabled) {
        return signedReply;
      }

      await ref.read(electrsProvider).broadcast(signedReply.transaction!,
          asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid);

      return signedReply;
    } catch (e) {
      logger.error('sign/send gdk tx error: $e');
      final error = PegGdkTransactionException();
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
  }
}

sealed class PegError implements Exception {}

class PegGdkInsufficientFeeBalanceException extends PegError {}

class PegGdkFeeExceedingAmountException extends PegError {}

class PegGdkTransactionException extends PegError {}

class PegSideSwapMinBtcLimitException extends PegError {}

class PegSideSwapMinLBtcLimitException extends PegError {}
