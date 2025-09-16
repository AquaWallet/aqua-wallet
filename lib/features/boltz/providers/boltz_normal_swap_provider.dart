import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';

// ANCHOR - Submarine Swap Provider
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
      existingSwap.txSize();

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
      index: 0,
      invoice: address,
      network: chain,
      electrumUrl: electrumUrl,
      boltzUrl: _ref.read(boltzEnvConfigProvider).apiUrl,
      referralId: 'COIN.CZ',
    );
    state = response;

    // Mask sensitive data before logging
    final maskedResponse = response.copyWith(
      keys: response.keys.copyWith(
        secretKey: '********',
      ),
      preimage: PreImage(
        value: '********',
        sha256: response.preimage.sha256,
        hash160: response.preimage.hash160,
      ),
    );

    logger.debug("[Send] Boltz Submarine Swap response: $maskedResponse");

    final swapDbModel = BoltzSwapDbModel.fromV2SwapResponse(response)
        .copyWith(lastKnownStatus: BoltzSwapStatus.created);
    final transactionDbModel = TransactionDbModel.fromV2SwapResponse(
      txhash: "",
      settleAddress: "",
      assetId: Asset.lightning().id,
      swap: response,
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
      final amount = forceBoltzFailedNormalSwapEnabled
          ? boltzOrder.outAmount - 1
          : boltzOrder.outAmount;

      final sendInput = SendAssetInputState(
        addressFieldText: boltzOrder.swapScript.fundingAddrs,
        amount: amount,
        asset: _ref.read(manageAssetsProvider).lbtcAsset,
      );

      final txn = await _ref
          .read(sendTransactionExecutorProvider(arguments))
          .createTransaction(
            sendInput: sendInput,
            rbfEnabled: false,
          );

      logger.debug(
          '[Send] Boltz Submarine Swap createGdkTransaction response: $txn}');
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
