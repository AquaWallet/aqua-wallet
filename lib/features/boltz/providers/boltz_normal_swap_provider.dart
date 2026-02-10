import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/models/bolt11_ext.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:boltz/boltz.dart';

final boltzSubmarineSwapProvider =
    StateNotifierProvider<BoltzSubmarineSwapNotifier, LbtcLnSwap?>(
        BoltzSubmarineSwapNotifier.new);

class BoltzSubmarineSwapNotifier extends StateNotifier<LbtcLnSwap?> {
  BoltzSubmarineSwapNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<bool> prepareSubmarineSwap({String? address}) async {
    if (address == null || address.isEmpty) {
      throw Exception('Could not get address');
    }

    // Check if swap with that invoice already exists
    final existingSwap = await _ref
        .read(boltzStorageProvider.notifier)
        .getLbtcLnV2SwapByInvoice(address);

    if (existingSwap != null) {
      state = existingSwap;

      // Check if swap already broadcast or settled. This is very important!
      // We don't want to double pay for a swap!

      // 1. Check status if already paid
      final swapDbModel = await _ref
          .read(boltzStorageProvider.notifier)
          .getSubmarineSwapDbModelByInvoice(address);
      logger.debug(
          "[Boltz] Found existing sub swap in cache with status: ${swapDbModel?.lastKnownStatus.toString()}");
      if (swapDbModel?.lastKnownStatus != null &&
          !swapDbModel!.lastKnownStatus!.isSubmarineUnpaid) {
        throw BoltzException(BoltzExceptionType.normalSwapAlreadyBroadcasted);
      }

      // 2. Just to be safe, check if tx exist in chain (should never get here unless local db was wiped)
      final existingTxs = await _ref
          .read(electrsProvider)
          .fetchTransactions(existingSwap.scriptAddress, NetworkType.liquid);
      if (existingTxs != null && existingTxs.isNotEmpty) {
        throw BoltzException(BoltzExceptionType.normalSwapAlreadyBroadcasted);
      }

      logger.debug(
          "[Boltz] Found existing unpaid sub swap in cache: ${existingSwap.id}");
      return true;
    }

    // call createSwap if none existing
    // REVIEW: Is this the right way to get the electrum url?
    final network = await _ref.read(liquidProvider).getNetwork();
    final electrumUrl = network!.electrumUrl!;

    final mnemonic = await _ref.read(liquidProvider).generateMnemonic12();
    final mnemonicString = mnemonic!.join(' ');

    final chain = _ref.read(envProvider) == Env.mainnet
        ? Chain.liquid
        : Chain.liquidTestnet;
    final response = await LbtcLnSwap.newSubmarine(
      mnemonic: mnemonicString,
      index: BigInt.zero,
      invoice: address,
      network: chain,
      electrumUrl: electrumUrl,
      boltzUrl: _ref.read(boltzEnvConfigProvider).apiUrl,
      referralId: 'AQUA',
    );
    state = response;

    // Log response (masking sensitive data)
    logger.debug("[Send] Boltz Submarine Swap created - ID: ${response.id}");
    final deliverAmount =
        Bolt11Ext.getAmountFromLightningInvoice(response.invoice);
    final walletId = await _ref.read(currentWalletIdOrThrowProvider.future);
    final swapDbModel = BoltzSwapDbModel.fromV2SwapResponse(
      response,
      walletId: walletId,
    ).copyWith(lastKnownStatus: BoltzSwapStatus.created);
    final transactionDbModel = TransactionDbModel.fromV2SwapResponse(
      txhash: "",
      settleAddress: address,
      assetId: Asset.lightning().id,
      swap: response,
      walletId: walletId,
      deliverAmount: deliverAmount,
    );
    await _ref.read(boltzStorageProvider.notifier).saveBoltzSwapResponse(
          txnDbModel: transactionDbModel,
          swapDbModel: swapDbModel,
          keys: response.keys,
          preimage: response.preimage,
        );

    return true;
  }

  // ANCHOR: - Send Onchain Normal Swap
  Future<SendAssetOnchainTx> createTxnForSubmarineSwap({
    required SendAssetArguments arguments,
    bool isFeeEstimateTxn = false,
  }) async {
    final boltzOrder = state;
    try {
      final forceBoltzFailedNormalSwapEnabled = _ref.watch(featureFlagsProvider
          .select((p) => p.forceBoltzFailedNormalSwapEnabled));

      if (boltzOrder == null) {
        return Future.error('No current boltz order');
      }

      // For refund debugging purposes, sending an amount 1 sat less than the
      // expected amount will cause the swap to fail and put the swap in a state
      // where a refund is needed
      final adjustedAmount = forceBoltzFailedNormalSwapEnabled
          ? boltzOrder.outAmount - BigInt.one
          : boltzOrder.outAmount;

      // Extract the original invoice amount from the invoice
      // This is what the user expects to send to the recipient
      final invoiceAmount =
          Bolt11Ext.getAmountFromLightningInvoice(boltzOrder.id);

      final rate = _ref.read(exchangeRatesProvider).currentCurrency;

      final sendInput = SendAssetInputState(
        addressFieldText: boltzOrder.swapScript.fundingAddrs,
        // Use the invoice amount for display if available, otherwise fall back to adjusted amount
        amount: invoiceAmount ?? adjustedAmount.toInt(),
        // Always use the exact amount needed for the transaction
        adjustedAmountToSend: adjustedAmount.toInt(),
        asset: _ref.read(manageAssetsProvider).lbtcAsset,
        rate: rate,
      );

      final txn = await _ref
          .read(sendTransactionExecutorProvider(arguments))
          .createTransaction(
            sendInput: sendInput,
            rbfEnabled: false,
          );

      return txn;
    } catch (e) {
      logger
          .error('[Send] Boltz Submarine Swap createGdkTransaction error: $e');
      return Future.error(e);
    }
  }

  Future<BoltzRefundData?> getRefundData(BoltzSwapDbModel swapDbModel) async {
    final swap = await _ref
        .read(boltzStorageProvider.notifier)
        .getLbtcLnV2SwapById(swapDbModel.boltzId);

    if (swap != null) {
      return BoltzRefundData(
        id: swap.id,
        privateKey: swap.keys.secretKey,
        blindingKey: swap.blindingKey,
        redeemScript: swapDbModel.redeemScript ?? "",
        timeoutBlockHeight: swap.swapScript.locktime,
      );
    }
    return null;
  }
}
