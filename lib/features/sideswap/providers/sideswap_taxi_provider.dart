import 'dart:async';

import 'package:aqua/common/price/btc_price.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/settings/manage_assets/providers/manage_assets_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/data/provider/lwk_provider.dart';
import 'package:convert/convert.dart';
import 'package:lwk/lwk.dart';

const bool useLowBallForElementsFallback = false;
const Duration kTaxiPayjoinTimeout = Duration(seconds: 20);

final sideswapTaxiProvider =
    AutoDisposeAsyncNotifierProvider<TaxiNotifier, TaxiState>(TaxiNotifier.new);

class TaxiNotifier extends AutoDisposeAsyncNotifier<TaxiState> {
  final _clientUtxosCache = <int, List<GdkUnspentOutputs>>{};

  @override
  FutureOr<TaxiState> build() => const TaxiState.empty();

  Future<String> createTaxiTransaction({
    required Asset taxiAsset,
    required int amount,
    required String sendAddress,
    bool sendAll = false,
  }) async {
    state = const AsyncLoading();

    final pset = await _createTaxiPsetWithLwk(
      asset: taxiAsset,
      amount: amount,
      sendAddress: sendAddress,
      sendAll: sendAll,
    );
    state = AsyncData(TaxiState.clientSignedPset(
      fullySignedPset: GdkNewTransactionReply(psbt: pset),
    ));
    return pset;
  }

  Future<String> _createTaxiPsetWithLwk({
    required Asset asset,
    required int amount,
    required String sendAddress,
    required bool sendAll,
  }) async {
    try {
      logger.debug('[Taxi] Creating payjoin transaction with LWK');

      // Create payjoin transaction using LWK
      final payjoinTx = await ref
          .read(lwkProvider)
          .createPayjoin(
            usdtSats: amount,
            outAddress: sendAddress,
            asset: asset.id,
          )
          .timeout(
            kTaxiPayjoinTimeout,
            onTimeout: () => throw const SideswapPayjoinTimeoutException(),
          );

      logger.debug('[Taxi] LWK payjoin transaction created successfully');

      final signedPset =
          await ref.read(lwkProvider).signPsetWithExtraDetails(payjoinTx.pset);
      final txBytes = await extractTxBytes(pset: signedPset);
      return hex.encode(txBytes);
    } catch (e) {
      if (e is LwkError) {
        logger.error('[Taxi] LWK payjoin creation failed: ${e.msg}');
        if (e.msg.contains('insufficient funds')) {
          final balances = await ref.read(lwkProvider).getBalances();
          logger.info(
              '[Taxi] Insufficient funds. Wallet Balance: ${balances.map((balance) => '${balance.assetId}: ${balance.value}').join(', ')}');
          ref.read(lwkProvider).syncWallet();
        }
        rethrow;
      }
      logger.error('[Taxi] LWK payjoin creation failed: $e');
      rethrow;
    }
  }

  static const int defaultMultisigInputs = 0;
  static const int defaultOutputs =
      3; // outputs: usdt send + change + fee to server - no need for fee output as that was a different weight and will be calculated below

  /// Compose the taxi pset combining server and user inputs and outputs
  /// 1. Choose server lbtc utxo to use for lbtc fee input - these are returned in start order call
  /// 2. Choose user usdt utxos to use for user inputs - these are the main utxos to consume for the usdt send
  /// 3. Create lbtc fee output from server lbtc input, adding an optional lbtc change output if needed
  /// 4. Create usdt outputs from user usdt inputs.
  ///    There will be 3 usdt outputs: Main send output, change output, and sideswap fee output
  Future<List<GdkUnspentOutputs>> _selectClientUtxos({
    required int sendAmount,
    bool sendAll = false,
  }) async {
    if (_clientUtxosCache.containsKey(sendAmount)) {
      return _clientUtxosCache[sendAmount]!;
    }

    final allUtxos = await ref.read(liquidProvider).getUnspentOutputs();
    final usdtAsset = ref.read(manageAssetsProvider).liquidUsdtAsset;
    final usdtUtxos = allUtxos!.unsentOutputs![usdtAsset.id];
    if (usdtUtxos == null) {
      logger.error("[Taxi] process order - error: insufficient funds");
      throw TaxiInsufficientFundsException;
    }

    if (sendAll) {
      return Future.value(usdtUtxos);
    }

    // first select utxos to cover send amount
    usdtUtxos.sort((a, b) => b.satoshi!.compareTo(a.satoshi!));
    final List<GdkUnspentOutputs> selectedUsdtUtxos = [];
    var selectedUsdtUtxosSum = 0;

    for (final utxo in usdtUtxos) {
      if (selectedUsdtUtxosSum >= sendAmount) {
        break;
      }

      selectedUsdtUtxos.add(utxo);
      selectedUsdtUtxosSum = selectedUsdtUtxosSum + utxo.satoshi!;
    }

    // estimate network fee based on initially selected UTXOs
    const serverInputs =
        2; // usually will be 1, but won't know until we place the order, so over-estimate to send enough utxos
    int uxtoInputs = selectedUsdtUtxos.length + serverInputs;
    int initialNetworkFee = await _expectedNetworkFeeUsdt(
      uxtoInputs,
      defaultMultisigInputs,
      defaultOutputs,
    );

    // add more UTXOs if needed to cover network fee
    int requiredAmount = sendAmount + initialNetworkFee + kSideswapTaxiFee;
    while (selectedUsdtUtxosSum < requiredAmount) {
      bool added = false;
      for (final utxo in usdtUtxos) {
        if (!selectedUsdtUtxos.contains(utxo)) {
          selectedUsdtUtxos.add(utxo);
          selectedUsdtUtxosSum += utxo.satoshi!;
          added = true;
          break;
        }
      }
      if (!added) {
        logger.error(
            "[Taxi] Error: select client utxos - still insufficient funds after trying to add more utxos");
        throw TaxiInsufficientFundsException();
      }

      uxtoInputs = selectedUsdtUtxos.length + serverInputs;
      initialNetworkFee = await _expectedNetworkFeeUsdt(
        uxtoInputs,
        defaultMultisigInputs,
        defaultOutputs,
      );

      requiredAmount = sendAmount + initialNetworkFee + kSideswapTaxiFee;
    }

    _clientUtxosCache[sendAmount] = selectedUsdtUtxos;

    return selectedUsdtUtxos;
  }

  // an estimate from actual txs to fallback to
  static const int fallbackTaxiFeeEstimate = 45000000;
  static const int sideswapTaxiFee = 10000000; // 0.1 usdt

  // below taken from https://github.com/sideswap-io/sideswapclient
  static const int weightFixed = 44;
  static const int weightVinSingleSig = 367;
  static const int weightVinMultiSig = 526;
  static const int weightVout = 4810;
  static const int weightFee = 178;

  Future<int> _expectedNetworkFeeSats(
    int singleSigInputs,
    int multiSigInputs,
    int blindedOutputs,
  ) async {
    int weight = weightFixed +
        weightVinSingleSig * singleSigInputs +
        weightVinMultiSig * multiSigInputs +
        weightVout * blindedOutputs +
        weightFee;

    final feeRateVb =
        ref.read(feeEstimateProvider).getLiquidFeeRate(isLiquidTaxi: true);
    final vsize = (weight + 3) ~/ 4;
    return (vsize * feeRateVb).ceil();
  }

  Future<int> _expectedNetworkFeeUsdt(
    int singleSigInputs,
    int multiSigInputs,
    int blindedOutputs,
  ) async {
    try {
      final btcPriceUsd =
          await BitcoinUSDPrice(ref.read(dioProvider)).fetchPrice();
      final feeSats = await _expectedNetworkFeeSats(
        singleSigInputs,
        multiSigInputs,
        blindedOutputs,
      );
      final feeUsdt = (btcPriceUsd * feeSats).ceil();
      return Future.value(feeUsdt);
    } catch (e) {
      logger.error("[Taxi] Error estimating usdt network fee: $e");
      return kFallbackTaxiFeeEstimate;
    }
  }

  // This should be an accurate estimate because we are calculating actual client utxos.
  // However, there is a small chance more than one server utxo will need to be used.
  // Can't know until we place the order
  Future<int> estimatedTaxiFeeUsdt(
    int sendAmount,
    bool sendAll,
  ) async {
    final clientUtxos = await _selectClientUtxos(
      sendAmount: sendAmount,
      sendAll: sendAll,
    );
    final inputUtxosCount = clientUtxos.length + 1; // +1 for server utxo
    final networkFeeUsdt = await _expectedNetworkFeeUsdt(
      inputUtxosCount,
      0,
      defaultOutputs,
    );
    return kSideswapTaxiFee + networkFeeUsdt;
  }
}

final estimatedTaxiFeeUsdtProvider =
    FutureProvider.family<int, (int, bool)>((ref, arguments) async {
  return await ref
      .read(sideswapTaxiProvider.notifier)
      .estimatedTaxiFeeUsdt(arguments.$1, arguments.$2);
});

class TaxiInvalidAmountException implements Exception {}

class TaxiInsufficientFundsException implements Exception {}

class TaxiCreatePsetException implements Exception {}

class TaxiSignPsetException implements Exception {}

class TaxiFinalizePsetException implements Exception {}
