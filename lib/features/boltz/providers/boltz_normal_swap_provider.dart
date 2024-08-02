import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:flutter/foundation.dart';

// ANCHOR - Submarine Swap Provider
final boltzSubmarineSwapProvider =
    StateNotifierProvider<BoltzSubmarineSwapNotifier, LbtcLnV2Swap?>(
        BoltzSubmarineSwapNotifier.new);

class BoltzSubmarineSwapNotifier extends StateNotifier<LbtcLnV2Swap?> {
  BoltzSubmarineSwapNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<bool> prepareSubmarineSwap() async {
    final address = _ref.read(sendAddressProvider);

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

      // REVIEW: How to check if this swap address already has broadcast?
      // Using the old method for now
      final existingTxs = await _ref
          .read(electrsProvider)
          .fetchTransactions(existingSwap.scriptAddress, NetworkType.liquid);
      if (existingTxs != null && existingTxs.isNotEmpty) {
        throw BoltzException(BoltzExceptionType.normalSwapAlreadyBroadcasted);
      }

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
    final response = await LbtcLnV2Swap.newSubmarine(
      mnemonic: mnemonicString,
      index: 0,
      invoice: address,
      network: chain,
      electrumUrl: electrumUrl,
      boltzUrl: _ref.read(boltzEnvConfigProvider).apiUrl,
      referralId: 'AQUA',
    );
    state = response;
    logger.d("[Send] Boltz Submarine Swap response: $response");

    final swapDbModel = BoltzSwapDbModel.fromV2SwapResponse(response)
        .copyWith(lastKnownStatus: BoltzSwapStatus.created);
    final transactionDbModel = TransactionDbModel.fromV2SwapResponse(
      txhash: "",
      settleAddress: "",
      assetId: Asset.lightning().id,
      swap: response,
    );
    _ref.read(boltzStorageProvider.notifier).saveBoltzSwapResponse(
          txnDbModel: transactionDbModel,
          swapDbModel: swapDbModel,
          keys: response.keys,
          preimage: response.preimage,
        );

    return true;
  }

  // ANCHOR: - Send Onchain Normal Swap
  Future<GdkNewTransactionReply> createTxnForSubmarineSwap(
      {bool isLowball = true}) async {
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
      final amount = kDebugMode && forceBoltzFailedNormalSwapEnabled
          ? boltzOrder.outAmount - 1
          : boltzOrder.outAmount;

      final tx = await _ref
          .read(sendAssetTransactionProvider.notifier)
          .createGdkTransaction(
            address: boltzOrder.swapScript.fundingAddrs,
            amountWithPrecision: amount,
            asset: _ref.read(manageAssetsProvider).lbtcAsset,
            rbfEnabled: false,
            isLowball: isLowball,
          );

      logger
          .d('[Send] Boltz Submarine Swap createGdkTransaction response: $tx}');
      return tx;
    } catch (e) {
      logger.e('[Send] Boltz Submarine Swap createGdkTransaction error: $e');
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

    // try legacy
    final legacySwap = await _ref
        .read(boltzDataProvider)
        .getBoltzNormalSwapData(swapDbModel.boltzId);
    if (legacySwap == null) return null;
    return _ref.read(boltzSwapRefundDataProvider(legacySwap));
  }
}
