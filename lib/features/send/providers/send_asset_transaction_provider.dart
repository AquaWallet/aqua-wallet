import 'dart:async';
import 'dart:convert';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/address_validator/models/address_validator_models.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_asset_transaction_provider.g.dart';

const liquidFeeRatePerVb = 0.1; // hardcoded sats per vbytes
const liquidFeeRatePerKb = 100; // hardcoded sats per 1000vbytes

//ANCHOR: - Send Asset Transaction Provider
final sendAssetTransactionProvider = AutoDisposeAsyncNotifierProvider<
    SendAssetTransactionProvider,
    SendAssetOnchainTx?>(SendAssetTransactionProvider.new);

class SendAssetTransactionProvider
    extends AutoDisposeAsyncNotifier<SendAssetOnchainTx?> {
  @override
  FutureOr<SendAssetOnchainTx?> build() => null;

  //ANCHOR: - Create Gdk Tx
  Future<GdkNewTransactionReply> createGdkTransaction({
    String? address,
    int? amountWithPrecision,
    Asset? asset,
  }) async {
    try {
      // asset
      asset = asset ?? ref.read(sendAssetProvider);
      if (asset == null) {
        logger.e('[Send] asset is null');
        throw Exception('Asset is null');
      }

      // amount
      if (amountWithPrecision == null) {
        final userEnteredAmount = ref.read(userEnteredAmountProvider);
        if (userEnteredAmount == null) {
          logger.e('[Send] amount is null');
          throw AmountParsingException(AmountParsingExceptionType.emptyAmount);
        }

        amountWithPrecision =
            ref.read(enteredAmountWithPrecisionProvider(userEnteredAmount));
      }

      // address
      address = address ?? ref.read(sendAddressProvider);
      if (address == null) {
        throw AddressParsingException(AddressParsingExceptionType.emptyAddress);
      }

      final feeRatePerVb = asset.isBTC
          ? ref.read(userSelectedFeeRatePerVByteProvider)?.rate.toInt()
          : liquidFeeRatePerVb;
      final feeRatePerKb =
          feeRatePerVb != null ? (feeRatePerVb * 1000).toInt() : null;
      final useAllFunds = ref.read(useAllFundsProvider);
      logger.d(
          '[Send][Fee] creating transaction with fee rate per kb: $feeRatePerKb');
      logger.d('[Send] creating transaction with useAllFunds: $useAllFunds');

      final networkProvider =
          asset.isBTC ? ref.read(bitcoinProvider) : ref.read(liquidProvider);

      final addressee = GdkAddressee(
        address: address,
        satoshi: amountWithPrecision,
        assetId: asset.id,
      );

      logger.d('[Send] addresse: $addressee; feeRate: $feeRatePerKb');

      final notes = ref.read(noteProvider);
      final transaction = GdkNewTransaction(
        addressees: [addressee],
        feeRate: feeRatePerKb ?? await networkProvider.getDefaultFees(),
        sendAll: useAllFunds,
        utxoStrategy: GdkUtxoStrategyEnum.defaultStrategy,
        memo: notes,
      );

      logger.d('[Send] provider tx: $transaction');

      final reply = await networkProvider.createTransaction(transaction);
      logger.d('[Send] provider tx reply: $reply');
      if (reply == null) {
        throw GdkNetworkException('Failed to create GDK transaction');
      }
      ref.read(insufficientBalanceProvider.notifier).state = false;
      state = AsyncData(SendAssetOnchainTx.gdkTx(reply));
      return reply;
    } on GdkNetworkInsufficientFunds {
      ref.read(insufficientBalanceProvider.notifier).state = true;
      rethrow;
    } catch (e) {
      logger.d('[Send] create gdk tx - error: $e');
      if (e is GdkNetworkException) {
        state = AsyncValue.error(e, StackTrace.current);
      }
      rethrow;
    }
  }

  //ANCHOR: Sign Tx through gdk
  Future<GdkNewTransactionReply?> _signGdkTransaction({
    required GdkNewTransactionReply transaction,
    required NetworkType network,
  }) async {
    try {
      final signedTx = network == NetworkType.bitcoin
          ? await ref.read(bitcoinProvider).signTransaction(transaction)
          : await ref.read(liquidProvider).signTransaction(transaction);
      if (signedTx == null) {
        throw GdkNetworkException('Failed to sign GDK transaction');
      }
      state = AsyncData(SendAssetOnchainTx.gdkTx(signedTx));
      return signedTx;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      logger.d('[SEND] sign gdk tx - error: $e');
      rethrow;
    }
  }

  //ANCHOR: - Create & Sign Taxi Psbt
  Future<GdkSignPsbtResult?> createTaxiPsbt() async {
    try {
      final asset = ref.read(sendAssetProvider);
      final userEnteredAmount = ref.read(userEnteredAmountProvider);
      final address = ref.read(sendAddressProvider);
      final amountSatoshi = ref.read(formatterProvider).parseAssetAmountDirect(
          amount: userEnteredAmount.toString(), precision: asset.precision);

      if (address == null || userEnteredAmount == null) {
        logger.e('[Send][Taxi] address or amount is null');
        throw Exception('Address or amount is null');
      }

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
      logger.d('[TAXI] create tx - params - depositAmount: $amountSatoshi');
      logger.d('[TAXI] create tx - params - depositAddress: $address');
      logger.d(
          '[TAXI] create tx - params - changeAddress: ${changeAddress?.address}');
      logger.d('[TAXI] create tx - params - utxos: $utxosJson');

      final partiallySignedPsbt = await _signPsbt(
        pset: '', //TODO: replace with pset from elements.rs
        utxos: flattenedUtxos,
        network: network,
      );

      if (partiallySignedPsbt == null) {
        state = AsyncValue.error(
            Exception('Failed to sign taxi pset'), StackTrace.current);
      }

      state = AsyncData(SendAssetOnchainTx.gdkPsbt(partiallySignedPsbt!));
      logger.d('[TAXI] create taxi tx - success: $partiallySignedPsbt');
      return partiallySignedPsbt;
    } catch (e) {
      logger.d('[TAXI] create taxi tx - error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  //ANCHOR: - Sign Pset
  Future<GdkSignPsbtResult?> _signPsbt({
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

  //ANCHOR: - Sign and Broadcast Tx
  Future<void> signAndBroadcastTransaction(
      {required Function onSuccess}) async {
    final asset = ref.read(sendAssetProvider);
    final transaction = state.asData?.value;
    final network = asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid;

    if (transaction != null && transaction.transactionHex != null) {
      logger.d('[Send] signing transaction: ${transaction.transactionHex!}');

      // sign tx
      final signedTx = await signTransaction(
          transactionHex: transaction.transactionHex!, network: network);

      if (signedTx == null) {
        throw Exception('Failed to sign transaction');
      }

      // broadcast tx
      final txId = await ref
          .read(sendAssetTransactionProvider.notifier)
          .broadcastTransaction(
              rawTx: signedTx,
              network: network,
              broadcastType: asset.broadcastService);

      onSuccess(txId, DateTime.now().microsecondsSinceEpoch, network);
    } else {
      throw Exception('Failed to sign transaction - no transaction found');
    }
  }

  Future<String?> signTransaction({
    required String transactionHex,
    required NetworkType network,
  }) async {
    final tx = state.value;
    return tx?.maybeMap(
      gdkTx: (gdkTx) async {
        try {
          final signedTx = await _signGdkTransaction(
            transaction: gdkTx.gdkTx.copyWith(
              memo: ref.read(noteProvider),
            ),
            network: network,
          );
          return signedTx?.transaction;
        } catch (e) {
          throw Exception('Failed to sign GDK transaction: $e');
        }
      },
      gdkPsbt: (gdkPsbt) async {
        try {
          final signedPsbt = await _signPsbt(
              pset: gdkPsbt.gdkPsbt.psbt,
              utxos: gdkPsbt.gdkPsbt.utxos,
              network: network);
          return signedPsbt?.psbt;
        } catch (e) {
          throw Exception('Failed to sign PSBT transaction: $e');
        }
      },
      orElse: () => throw Exception('Failed to sign transaction'),
    );
  }

  Future<String?> broadcastTransaction(
      {required String rawTx,
      String? txHash,
      NetworkType network = NetworkType.liquid,
      SendBroadcastServiceType broadcastType =
          SendBroadcastServiceType.blockstream}) async {
    try {
      String result;
      switch (broadcastType) {
        case SendBroadcastServiceType.blockstream:
          result = await ref.read(electrsProvider).broadcast(rawTx, network);
        case SendBroadcastServiceType.boltz:
          final response = await ref
              .read(boltzProvider)
              .broadcastTransaction(currency: "L-BTC", transactionHex: rawTx);
          result = response.transactionId;
      }

      txHash = result;
      await success(txHash);

      return result;
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
  Future<void> success(String txHash) async {
    final asset = ref.read(sendAssetProvider);

    // cache tx hash for boltz
    if (asset.isLightning) {
      final boltzCurrentOrder =
          ref.watch(boltzSwapSuccessResponseProvider.notifier).state;

      if (boltzCurrentOrder != null) {
        logger.d("[TX] success - cache tx hash for boltz: $txHash");
        await ref
            .read(boltzProvider)
            .cacheTxHash(swapId: boltzCurrentOrder.id, txHash: txHash);
      }
    }

    // cache tx hash for sideshift
    if (asset.isSideshift) {
      final sideShiftCurrentOrder = ref.watch(pendingOrderProvider);

      if (sideShiftCurrentOrder != null && sideShiftCurrentOrder.id != null) {
        logger.d("[TX] success - cache tx hash for sideshift: $txHash");
        await ref
            .read(sideshiftStorageProvider)
            .updateTxHash(sideShiftCurrentOrder.id!, txHash);
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

//ANCHOR: - External Tx Id Provider
final externalServiceTxIdProvider =
    Provider.family.autoDispose<String?, Asset>((ref, asset) {
  if (asset.isSideshift) {
    final sideshiftCurrentOrder = ref.watch(pendingOrderProvider);
    if (sideshiftCurrentOrder != null) {
      return sideshiftCurrentOrder.id;
    }
  } else if (asset.isLightning) {
    final boltzCurrentOrder =
        ref.watch(boltzSwapSuccessResponseProvider.notifier).state;
    if (boltzCurrentOrder != null) {
      return boltzCurrentOrder.id;
    }
  }

  return null;
});

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
