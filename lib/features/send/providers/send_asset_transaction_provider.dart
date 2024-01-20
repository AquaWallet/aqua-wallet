import 'dart:async';
import 'dart:convert';

import 'package:aqua/logger.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_storage_provider.dart';
import 'package:aqua/features/external/boltz/boltz_provider.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/send/providers/send_asset_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/providers/asset_balance_provider.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_asset_transaction_provider.g.dart';

//ANCHOR: - Send Asset Transaction Provider
final sendAssetTransactionProvider = AutoDisposeAsyncNotifierProvider<
    SendAssetTransactionProvider,
    GdkNewTransactionReply?>(SendAssetTransactionProvider.new);

class SendAssetTransactionProvider
    extends AutoDisposeAsyncNotifier<GdkNewTransactionReply?> {
  @override
  FutureOr<GdkNewTransactionReply?> build() => null;

  //ANCHOR: - Create Tx
  Future<GdkNewTransactionReply> createTransaction({
    int? amountSatoshi,
    required bool sendAll,
    required String address,
    int? feeRate,
    NetworkType network = NetworkType.liquid,
    String? assetId,
  }) async {
    try {
      final networkProvider = (network == NetworkType.bitcoin)
          ? ref.read(bitcoinProvider)
          : ref.read(liquidProvider);

      final addressee = GdkAddressee(
        address: address,
        satoshi: amountSatoshi,
        assetId: assetId,
      );

      logger.d('addresse: $addressee; feeRate: $feeRate');

      final transaction = GdkNewTransaction(
        addressees: [addressee],
        feeRate: feeRate ?? await networkProvider.getDefaultFees(),
        sendAll: sendAll,
        utxoStrategy: GdkUtxoStrategyEnum.defaultStrategy,
      );

      logger.d('provider tx: $transaction');

      final reply = await networkProvider.createTransaction(transaction);
      logger.d('provider tx reply: $reply');
      if (reply == null) {
        throw GdkNetworkException('Failed to create GDK transaction');
      }
      state = AsyncData(reply);
      return reply;
    } catch (e) {
      logger.d('[SEND] create gdk tx - error: $e');
      if (e is GdkNetworkException) {
        state = AsyncValue.error(e, StackTrace.current);
      }
      rethrow;
    }
  }

  //ANCHOR: Sign Tx through gdk
  Future<GdkNewTransactionReply?> signTransaction({
    required GdkNewTransactionReply transaction,
    required NetworkType network,
  }) async {
    try {
      final tx = network == NetworkType.bitcoin
          ? await ref.read(bitcoinProvider).signTransaction(transaction)
          : await ref.read(liquidProvider).signTransaction(transaction);
      return tx;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.d('[SEND] sign gdk tx - error: $e');
      rethrow;
    }
  }

  //ANCHOR: - Create & Sign Taxi Psbt
  Future<GdkSignPsbtResult?> createAndSignTaxiPsbt({
    required int amount,
    required String address,
    required Asset asset,
  }) async {
    try {
      final network =
          asset == Asset.btc() ? NetworkType.bitcoin : NetworkType.liquid;
      final networkProvider = (network == NetworkType.bitcoin)
          ? ref.read(bitcoinProvider)
          : ref.read(liquidProvider);

      // get utxos
      final utxos = await getUnspentOutputs(NetworkType.liquid);
      List<Map<String, dynamic>> flattenedUtxos = [];
      if (utxos.unsentOutputs != null) {
        flattenedUtxos = utxos.unsentOutputs!.entries.expand((entry) {
          return entry.value.map((output) => output.toJson());
        }).toList();
      }

      String utxosJson = jsonEncode(flattenedUtxos);

      // get change addfress
      final changeAddress = await networkProvider.getReceiveAddress();

      //TOOD: Call elements.rs to create and partially sign taxi pset
      logger.d('[TAXI] create tx - params - depositAmount: $amount');
      logger.d('[TAXI] create tx - params - depositAddress: $address');
      logger.d(
          '[TAXI] create tx - params - changeAddress: ${changeAddress?.address}');
      logger.d('[TAXI] create tx - params - utxos: $utxosJson');

      final signedPset = await signPsbt(
        pset: '', //TODO: replace with pset from elements.rs
        utxos: flattenedUtxos,
        network: network,
      );

      //TODO: Need to cache signed pset in `state`. However need a new object to hold both a `GdkNewTransactionReply` and a `GdkSignPsetDetailsReply`
      // state = AsyncData(signedPset);

      logger.d('[TAXI] create taxi tx - success: $signedPset');
      return signedPset;
    } catch (e) {
      logger.d('[TAXI] create taxi tx - error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  //ANCHOR: - Sign Pset
  Future<GdkSignPsbtResult?> signPsbt({
    required String pset,
    required List<Map<String, dynamic>> utxos,
    required NetworkType network,
  }) async {
    try {
      final psetDetails = GdkSignPsbtDetails(psbt: pset, utxos: utxos);
      final result = network == NetworkType.bitcoin
          ? await ref.read(bitcoinProvider).signPsbt(psetDetails)
          : await ref.read(liquidProvider).signPsbt(psetDetails);
      logger.d('[TAXI] sign taxi tx - success: ${psetDetails.toString()}');
      return result;
    } catch (e) {
      logger.d('[TAXI] sign taxi tx - error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  //ANCHOR: - Broadcast Tx
  Future<String?> broadcastTransaction(
      {required String rawTx,
      NetworkType network = NetworkType.liquid,
      SendBroadcastServiceType broadcastType =
          SendBroadcastServiceType.blockstream}) async {
    try {
      switch (broadcastType) {
        case SendBroadcastServiceType.blockstream:
          return await ref.read(electrsProvider).broadcast(rawTx, network);
        case SendBroadcastServiceType.boltz:
          final response = await ref
              .read(boltzProvider)
              .broadcastTransaction(currency: "L-BTC", transactionHex: rawTx);
          return response.transactionId;
      }
    } catch (e) {
      _handleBroadcastException(e);
      rethrow;
    }
  }

  void _handleBroadcastException(dynamic e) {
    String? errorMessage;
    if (e is DioException) {
      errorMessage = e.response?.data?.toString() ?? e.message;
    }
    state = AsyncValue.error(errorMessage ?? e.toString(), StackTrace.current);
  }

  //ANCHOR: - Success
  void success(GdkNewTransactionReply tx) {
    final asset = ref.read(sendAssetProvider);

    // cache tx hash for boltz
    if (asset.isLightning) {
      final boltzCurrentOrder =
          ref.watch(boltzSwapSuccessResponseProvider.notifier).state;

      if (boltzCurrentOrder != null && tx.txhash != null) {
        logger.d("[TX] success - cache tx hash for boltz: ${tx.txhash}");
        ref
            .read(boltzProvider)
            .cacheTxHash(swapId: boltzCurrentOrder.id, txHash: tx.txhash!);
      }
    }

    // cache tx hash for sideshift
    if (asset.isSideshift) {
      final sideShiftCurrentOrder = ref.watch(pendingOrderProvider);

      if (sideShiftCurrentOrder != null &&
          sideShiftCurrentOrder.id != null &&
          tx.txhash != null) {
        logger.d("[TX] success - cache tx hash for sideshift: ${tx.txhash}");
        ref
            .read(sideshiftStorageProvider)
            .updateTxHash(sideShiftCurrentOrder.id!, tx.txhash!);
      }
    }
  }

  //ANCHOR: Get UTXOs
  Future<GdkUnspentOutputsReply> getUnspentOutputs(NetworkType network) async {
    try {
      final networkProvider = (network == NetworkType.bitcoin)
          ? ref.read(bitcoinProvider)
          : ref.read(liquidProvider);

      final utxos = await networkProvider.getUnspentOutputs();
      return utxos as GdkUnspentOutputsReply;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

/// Verify if user has enough funds for fee for asset
@riverpod
Future<bool> hasEnoughFundsForFee(
  HasEnoughFundsForFeeRef ref, {
  required Asset asset,
  required double fee,
}) async {
  final assetBalance = await ref.read(balanceProvider).getBalance(asset);
  return assetBalance >= fee;
}
