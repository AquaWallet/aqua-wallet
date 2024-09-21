import 'dart:async';

import 'package:aqua/common/price/btc_price.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/elements.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/settings/manage_assets/providers/manage_assets_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';

final sideswapTaxiProvider =
    AutoDisposeAsyncNotifierProvider<TaxiNotifier, TaxiState>(TaxiNotifier.new);

class TaxiNotifier extends AutoDisposeAsyncNotifier<TaxiState> {
  final _clientUtxosCache = <int, List<GdkUnspentOutputs>>{};

  @override
  FutureOr<TaxiState> build() => const TaxiState.empty();

  Future<String> createTaxiTransaction(
      {required Asset taxiAsset,
      required int amount,
      required String sendAddress,
      bool isLowball = true,
      bool sendAll = false}) async {
    state = const AsyncLoading();

    try {
      final selectedClientUtxos =
          await _selectClientUtxos(sendAmount: amount, sendAll: sendAll);

      final partiallySignedTaxiPset = await _createTaxiPset(
          asset: taxiAsset,
          amount: amount,
          sendAddress: sendAddress,
          selectedUtxos: selectedClientUtxos,
          isLowball: isLowball,
          sendAll: sendAll);
      state = AsyncData(
          TaxiState.createPset(partiallySignedPset: partiallySignedTaxiPset));

      final clientSignedPset = await _signPset(
          pset: partiallySignedTaxiPset, utxos: selectedClientUtxos);
      state = AsyncData(
          TaxiState.clientSignedPset(fullySignedPset: clientSignedPset));

      final finalPset = await _createFinalPset(
          clientSignedPset: clientSignedPset.psbt!,
          serverSignedPset: partiallySignedTaxiPset);

      return finalPset;
    } on DioException catch (e) {
      logger.e(
          "[Taxi] Create pset dio error: ${e.response?.statusCode}, ${e.response?.data}");
      state = AsyncError(NetworkException(e.message), StackTrace.current);
      rethrow;
    } catch (e) {
      logger.e("[Taxi] Create pset error: $e");
      state = AsyncError(e, StackTrace.current);
      throw Exception(e);
    }
  }

  Future<String> _createTaxiPset(
      {required Asset asset,
      required int amount,
      required String sendAddress,
      required List<GdkUnspentOutputs> selectedUtxos,
      bool isLowball = true,
      required bool sendAll}) async {
    try {
      final changeAddress = await ref.read(liquidProvider).getReceiveAddress();
      assert(changeAddress != null && changeAddress.address != null);

      final txResult = await Future.value(Elements.createTaxiTransaction(
          amount,
          sendAddress,
          changeAddress!.address!,
          selectedUtxos,
          kSideswapUserAgent,
          kSideswapApiKey,
          sendAll,
          isLowball,
          ref.read(envProvider) == Env.testnet));

      if (txResult.errorMessage != null || txResult.tx == null) {
        throw Exception(txResult.errorMessage);
      }

      return Future.value(txResult.tx);
    } catch (e) {
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
  Future<List<GdkUnspentOutputs>> _selectClientUtxos(
      {required int sendAmount,
      bool sendAll = false,
      bool isLowball = true}) async {
    if (_clientUtxosCache.containsKey(sendAmount)) {
      return _clientUtxosCache[sendAmount]!;
    }

    final allUtxos = await ref.read(liquidProvider).getUnspentOutputs();
    final usdtAsset = ref.read(manageAssetsProvider).liquidUsdtAsset;
    final usdtUtxos = allUtxos!.unsentOutputs![usdtAsset.id];
    if (usdtUtxos == null) {
      logger.e("[Taxi] process order - error: insufficient funds");
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
        uxtoInputs, defaultMultisigInputs, defaultOutputs,
        isLowball: isLowball);

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
        logger.e(
            "[Taxi] Error: select client utxos - still insufficient funds after trying to add more utxos");
        throw TaxiInsufficientFundsException();
      }

      uxtoInputs = selectedUsdtUtxos.length + serverInputs;
      initialNetworkFee = await _expectedNetworkFeeUsdt(
          uxtoInputs, defaultMultisigInputs, defaultOutputs,
          isLowball: isLowball);

      requiredAmount = sendAmount + initialNetworkFee + kSideswapTaxiFee;
    }

    _clientUtxosCache[sendAmount] = selectedUsdtUtxos;

    return selectedUsdtUtxos;
  }

  Future<GdkNewTransactionReply> _signPset(
      {required String pset, required List<GdkUnspentOutputs> utxos}) async {
    try {
      final utxosList = utxos.map((utxo) => utxo.toJson()).toList();
      final psetDetails = GdkSignPsbtDetails(psbt: pset, utxos: utxosList);
      final signedPset = await ref.read(liquidProvider).signPsbt(psetDetails);

      if (signedPset == null) {
        throw TaxiSignPsetException;
      }

      return signedPset;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _createFinalPset(
      {required String clientSignedPset,
      required String serverSignedPset}) async {
    try {
      final finalPset = await Future.value(Elements.createFinalTaxiPset(
        clientSignedPset,
        serverSignedPset,
      ));

      if (finalPset.errorMessage != null || finalPset.tx == null) {
        logger.e("[Taxi] Error finalizing pset: ${finalPset.errorMessage}");
        throw TaxiFinalizePsetException;
      }

      return Future.value(finalPset.tx);
    } catch (e) {
      rethrow;
    }
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
      int singleSigInputs, int multiSigInputs, int blindedOutputs,
      {bool isLowball = true}) async {
    int weight = weightFixed +
        weightVinSingleSig * singleSigInputs +
        weightVinMultiSig * multiSigInputs +
        weightVout * blindedOutputs +
        weightFee;

    double feeRateVb =
        ref.read(feeEstimateProvider).getLiquidFeeRate(isLowball: isLowball);

    int vsize = (weight + 3) ~/ 4;
    return (vsize * feeRateVb).ceil();
  }

  Future<int> _expectedNetworkFeeUsdt(
      int singleSigInputs, int multiSigInputs, int blindedOutputs,
      {bool isLowball = true}) async {
    try {
      final btcPriceUsd =
          await BitcoinUSDPrice(ref.read(dioProvider)).fetchPrice();
      final feeSats = await _expectedNetworkFeeSats(
          singleSigInputs, multiSigInputs, blindedOutputs,
          isLowball: isLowball);
      final feeUsdt = (btcPriceUsd * feeSats).ceil();
      return Future.value(feeUsdt);
    } catch (e) {
      logger.e("[Taxi] Error estimating usdt network fee: $e");
      return kFallbackTaxiFeeEstimate;
    }
  }

  // This should be an accurate estimate because we are calculating actual client utxos.
  // However, there is a small chance more than one server utxo will need to be used.
  // Can't know until we place the order
  Future<int> estimatedTaxiFeeUsdt(int sendAmount, bool sendAll,
      {bool isLowball = true}) async {
    final clientUtxos = await _selectClientUtxos(
        sendAmount: sendAmount, sendAll: sendAll, isLowball: isLowball);
    final inputUtxosCount = clientUtxos.length + 1; // +1 for server utxo
    final networkFeeUsdt = await _expectedNetworkFeeUsdt(
        inputUtxosCount, 0, defaultOutputs,
        isLowball: isLowball);
    return kSideswapTaxiFee + networkFeeUsdt;
  }
}

final estimatedTaxiFeeUsdtProvider =
    FutureProvider.family<int, (int, bool, bool)>((ref, arguments) async {
  return await ref.read(sideswapTaxiProvider.notifier).estimatedTaxiFeeUsdt(
      arguments.$1, arguments.$2,
      isLowball: arguments.$3);
});

class TaxiInvalidAmountException implements Exception {}

class TaxiInsufficientFundsException implements Exception {}

class TaxiCreatePsetException implements Exception {}

class TaxiSignPsetException implements Exception {}

class TaxiFinalizePsetException implements Exception {}
