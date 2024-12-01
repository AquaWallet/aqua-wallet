import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/aqua_node_provider.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/features/address_validator/models/address_validator_models.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swap/models/taxi_state.dart';
import 'package:aqua/features/swap/providers/sideswap_taxi_provider.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_asset_transaction_provider.g.dart';

//ANCHOR: - Send Asset Transaction Provider
final sendAssetTransactionProvider = AutoDisposeAsyncNotifierProvider<
    SendAssetTransactionProvider,
    SendAssetOnchainTx?>(SendAssetTransactionProvider.new);

class SendAssetTransactionProvider
    extends AutoDisposeAsyncNotifier<SendAssetOnchainTx?> {
  @override
  FutureOr<SendAssetOnchainTx?> build() => null;

  Future<GdkNewTransactionReply?>
      createInitialGdkTransactionForFeeEstimate() async {
    final isLowball = ref.read(isAquaNodeSyncedProvider) == true;

    var asset = ref.read(sendAssetProvider);
    if (asset.isSideshift) {
      final useAllFunds = ref.read(useAllFundsProvider);
      return await ref
          .read(sideshiftSendProvider)
          .createGdkTxForSwap(useAllFunds, isLowball: isLowball);
    }
    if (asset.isLightning) {
      return await ref
          .read(boltzSubmarineSwapProvider.notifier)
          .createTxnForSubmarineSwap(
            isLowball: isLowball,
            isFeeEstimateTxn: true,
          );
    }

    // for any liquid asset, we don't need to create a lbtc fee tx if user has no ltbc funds. A taxi fee estimate will be created separately.
    if (!asset.isBTC) {
      final lbtcBalance = await ref.read(balanceProvider).getLBTCBalance();
      if (lbtcBalance == 0) return Future.value(null);
    }

    logger.d("[Send] send review - create transaction");
    return createGdkTransaction(isLowball: isLowball);
  }

  Future<GdkNewTransactionReply> createGdkTransaction({
    String? address,
    int? amountWithPrecision,
    Asset? asset,
    bool rbfEnabled = true,
    bool isLowball = true,
  }) async {
    try {
      asset = asset ?? ref.read(sendAssetProvider);
      if (asset == null) {
        logger.e('[Send] asset is null');
        throw Exception('Asset is null');
      }

      final userEnteredAmount = ref.read(userEnteredAmountProvider);
      if (amountWithPrecision == null && userEnteredAmount == null) {
        logger.e('[Send] amount is null');
        throw AmountParsingException(AmountParsingExceptionType.emptyAmount);
      }
      amountWithPrecision = amountWithPrecision ??
          ref.read(enteredAmountWithPrecisionProvider(userEnteredAmount!));

      address = address ?? ref.read(sendAddressProvider);
      if (address == null) {
        throw AddressParsingException(AddressParsingExceptionType.emptyAddress);
      }

      final customFeeInput = ref.read(customFeeInputProvider);

      final feeRatePerVb = asset.isBTC
          ? customFeeInput != null
              ? Decimal.tryParse(customFeeInput)?.toBigInt().toInt()
              : ref.read(userSelectedFeeRatePerVByteProvider)?.rate.toInt()
          : ref
              .read(feeEstimateProvider)
              .getLiquidFeeRate(isLowball: isLowball);

      final feeRatePerKb =
          feeRatePerVb != null ? (feeRatePerVb * 1000).toInt() : null;
      final useAllFunds = ref.read(useAllFundsProvider);

      final networkProvider =
          ref.read(asset.isBTC ? bitcoinProvider : liquidProvider);

      final addressee = GdkAddressee(
          address: address,
          satoshi: amountWithPrecision,
          assetId: asset.id != 'btc' ? asset.id : null,
          isGreedy: useAllFunds);

      final filteredUtxos = await ref.read(liquidProvider).getUnspentOutputs();
      final notes = ref.read(noteProvider);
      final transaction = GdkNewTransaction(
          addressees: [addressee],
          feeRate: feeRatePerKb ?? await networkProvider.getDefaultFees(),
          utxoStrategy: GdkUtxoStrategyEnum.defaultStrategy,
          memo: notes,
          utxos: filteredUtxos?.unsentOutputs);

      logger.d('[Send] provider tx: $transaction');

      try {
        final gdkNewTxReply = await networkProvider.createTransaction(
          transaction: transaction,
          rbfEnabled: rbfEnabled,
        );
        if (gdkNewTxReply == null) {
          throw GdkNetworkException('Failed to create GDK transaction');
        }
        ref.read(insufficientBalanceProvider.notifier).state = null;
        state = AsyncData(SendAssetOnchainTx.gdkTx(gdkNewTxReply));
        return gdkNewTxReply;
      } on GdkNetworkInsufficientFunds {
        ref.read(insufficientBalanceProvider.notifier).state =
            InsufficientFundsType.sendAmount;
        rethrow;
      }
    } catch (e) {
      logger.d('[Send] create gdk tx - error: $e');
      final isUSDTFeeError = asset != null &&
          asset.isUSDt &&
          (e is GdkNetworkInsufficientFundsForFee); // We can ignore fee errors for USDT as it can be paid with USDT or LBTC
      if (e is GdkNetworkException && !isUSDTFeeError) {
        state = AsyncValue.error(e, StackTrace.current);
      }
      rethrow;
    }
  }

  //ANCHOR: - Create taxi pset
  Future<String?> initiateTaxiTransaction(
      {String? address, bool isLowball = true}) async {
    final asset = ref.read(sendAssetProvider);
    final userEnteredAmount = ref.read(userEnteredAmountProvider);
    final resolvedAddress = address ?? ref.read(sendAddressProvider);
    final amountSatoshi = ref.read(formatterProvider).parseAssetAmountDirect(
        amount: userEnteredAmount.toString(), precision: asset.precision);
    final sendAll = ref.read(useAllFundsProvider);

    if (resolvedAddress == null || userEnteredAmount == null) {
      logger.e('[Send][Taxi] address or amount is null');
      throw Exception('Address or amount is null');
    }

    return await executeTaxiTransaction(resolvedAddress, amountSatoshi, sendAll,
        isLowball: isLowball);
  }

  Future<String?> executeTaxiTransaction(
      String address, int amount, bool sendAll,
      {bool isLowball = true}) async {
    try {
      state = const AsyncLoading();

      final usdtAsset = ref.read(manageAssetsProvider).liquidUsdtAsset;
      final taxiState =
          ref.read(sideswapTaxiProvider.notifier).state.valueOrNull;
      if (taxiState is TaxiStateFinalSignedPset) {
        logger.d('[Send][Taxi] Final signed pset exists - returning');
        return taxiState.finalSignedPset;
      }

      final finalPset = await ref
          .read(sideswapTaxiProvider.notifier)
          .createTaxiTransaction(
              taxiAsset: usdtAsset,
              amount: amount,
              sendAddress: address,
              sendAll: sendAll,
              isLowball: isLowball);
      logger.d('[Send][Taxi] Final signed pset successfully created');
      state = AsyncData(SendAssetOnchainTx.gdkPsbt(finalPset));
      return finalPset;
    } catch (e) {
      logger.d('[Send][Taxi] create taxi tx - error: $e');
      rethrow;
    }
  }

  Future<void> createAndSendFinalTransaction({
    required Function onSuccess,
    bool isLowball = true,
  }) async {
    try {
      final asset = ref.read(sendAssetProvider);
      final feeAsset = ref.read(userSelectedFeeAssetProvider);
      final sendAll = ref.read(useAllFundsProvider);

      if (asset.isLightning) {
        await ref
            .read(boltzSubmarineSwapProvider.notifier)
            .createTxnForSubmarineSwap(isLowball: isLowball);
      } else if (asset.isSideshift) {
        await ref
            .read(sideshiftSendProvider)
            .createOnchainTxForSwap(feeAsset, sendAll, isLowball: isLowball);
      } else if (feeAsset == FeeAsset.tetherUsdt) {
        await ref
            .read(sendAssetTransactionProvider.notifier)
            .initiateTaxiTransaction(isLowball: isLowball);
      } else {
        await ref
            .read(sendAssetTransactionProvider.notifier)
            .createGdkTransaction(isLowball: isLowball);
      }

      final transaction = state.asData?.value;
      final network = asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid;

      if (transaction == null || transaction.transactionHex == null) {
        throw Exception(
            'Failed to sign transaction - missing hex encoded transaction data');
      }

      logger.d('[Send] signing transaction: ${transaction.transactionHex!}');

      String? signedRawTx;

      await transaction.when(
        gdkTx: (GdkNewTransactionReply gdkTx) async {
          final blindedTx = asset.isBTC
              ? transaction.txReply
              : await ref
                  .read(liquidProvider)
                  .blindTransaction(transaction.txReply!);

          final signedGdkTx =
              await _signTransaction(transaction: blindedTx!, network: network);

          signedRawTx = signedGdkTx.transaction!;
        },
        gdkPsbt: (String tx) {
          signedRawTx = tx;
        },
      );

      if (ref.read(featureFlagsProvider).fakeBroadcastsEnabled) {
        onSuccess('12345', DateTime.now().microsecondsSinceEpoch, network);
        return;
      }

      final txId = await broadcastTransaction(
          rawTx: signedRawTx!, network: network, isLowball: isLowball);
      final createdAt = DateTime.now();

      // If boltz, mark as broadcasted
      // - this isn't a boltz status, but our own added one. see comment on status for why this is necessary
      if (asset.isLightning) {
        await ref
            .read(boltzSubmarineSwapProvider.notifier)
            .updateStatusOnSubmarineLockupBroadcast(txId);
      }

      // Save lowball transaction to db until it is detected by GDK (for ghost txns)
      if (isLowball) {
        final userEnteredAmount = ref.read(userEnteredAmountProvider);
        final amountWithPrecision =
            ref.read(enteredAmountWithPrecisionProvider(userEnteredAmount!));

        final underlyingAssetId = asset.isLightning
            ? ref.read(manageAssetsProvider).lbtcAsset.id
            : asset.id;

        final type = asset.isLightning
            ? TransactionDbModelType.boltzSwap
            : TransactionDbModelType.aquaSend;

        await ref
            .read(transactionStorageProvider.notifier)
            .save(TransactionDbModel(
              txhash: txId,
              assetId: underlyingAssetId,
              type: type,
              isGhost: !asset.isBTC,
              ghostTxnCreatedAt: createdAt,
              ghostTxnAmount: -amountWithPrecision,
              ghostTxnFee: transaction.txReply?.fee,
            ));
      }

      // Cache used utxos for lowball double-spend issue
      if (!asset.isBTC) {
        _cacheUsedUtxos(transaction);
      }

      onSuccess(txId, createdAt.microsecondsSinceEpoch, network);
    } on AquaTxBroadcastException {
      // Return exception directly so we can show a retry dialog and let user manually retry
      state = AsyncValue.error(AquaTxBroadcastException(), StackTrace.current);
    } on MempoolConflictTxBroadcastException {
      // Return exception directly so we can show a retry dialog
      state = AsyncValue.error(
          MempoolConflictTxBroadcastException(), StackTrace.current);
    } catch (e, stackTrace) {
      String? errorMessage;
      if (e is DioException) {
        errorMessage = e.response?.data?.toString() ?? e.message;
      }
      state = AsyncValue.error(errorMessage ?? e.toString(), stackTrace);
    }
  }

  Future<GdkNewTransactionReply> _signTransaction({
    required GdkNewTransactionReply transaction,
    required NetworkType network,
  }) async {
    try {
      final provider = ref.read(
          network == NetworkType.bitcoin ? bitcoinProvider : liquidProvider);
      final signedTx = await provider.signTransaction(transaction);

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

  Future<String> broadcastTransaction({
    required String rawTx,
    String? txHash,
    NetworkType network = NetworkType.liquid,
    SendBroadcastServiceType broadcastType = SendBroadcastServiceType.aqua,
    bool isLowball = true,
  }) async {
    String result;
    switch (broadcastType) {
      case SendBroadcastServiceType.boltz:
        // REVIEW: Boltz Dart has swap.broadcastTx but it expects a pset
        // Using old method to broadcast transaction
        final response = await ref
            .read(legacyBoltzProvider)
            .broadcastTransaction(currency: "L-BTC", transactionHex: rawTx);
        result = response.transactionId;
      default:
        result = await ref
            .read(electrsProvider)
            .broadcast(rawTx, network, isLowball: isLowball);
    }

    txHash = result;
    await _success(txHash);

    return result;
  }

  //ANCHOR: - Success
  Future<void> _success(String txHash) async {
    final asset = ref.read(sendAssetProvider);

    // cache tx hash for boltz
    if (asset.isLightning) {
      final swap = ref.watch(boltzSubmarineSwapProvider);

      if (swap != null) {
        logger.d("[TX] success - cache tx hash for boltz: $txHash");
        await ref
            .read(boltzStorageProvider.notifier)
            .updateSubmarineOnchainTxId(boltzId: swap.id, txId: txHash);
      }
    }

    // cache tx hash for sideshift
    if (asset.isSideshift) {
      final sideShiftCurrentOrder = ref.watch(sideshiftPendingOrderProvider);

      if (sideShiftCurrentOrder != null && sideShiftCurrentOrder.id != null) {
        logger.d("[TX] success - cache tx hash for sideshift: $txHash");
        await ref
            .read(sideshiftStorageProvider.notifier)
            .updateOrder(orderId: sideShiftCurrentOrder.id!, txHash: txHash);
      }
    }
  }

  //ANCHOR: - Used utxos caching
  void _cacheUsedUtxos(SendAssetOnchainTx transaction) {
    // NOTE: cache used utxos to fix lowball issue where spent utxos are not seen until block is mined.
    // Without manually caching these, gdk will re-use these spent utxos if another tx is formed before the this tx is mined
    Map<String, List<GdkUnspentOutputs>>? usedUtxos = transaction.when(
      gdkTx: (GdkNewTransactionReply gdkTx) {
        if (gdkTx.transactionInputs == null) return null;

        final Map<String, List<GdkUnspentOutputs>> mappedUtxos = {};

        for (var input in gdkTx.transactionInputs!) {
          if (input.assetId == null) {
            assert(false, "Malformed transactionInputs");
            continue;
          }

          final assetId = input.assetId!;

          if (!mappedUtxos.containsKey(assetId)) {
            mappedUtxos[assetId] = [];
          }

          logger.d(
              "[Lowball] caching used utxo: ${input.txhash}, ${input.ptIdx}, ${input.satoshi}");
          mappedUtxos[assetId]!.add(input);
        }

        return mappedUtxos;
      },
      gdkPsbt: (_) {
        return null; // cannot easily parse utxos from psbt at this point
      },
    );

    if (usedUtxos == null) return;
    ref.read(recentlySpentUtxosProvider.notifier).addUtxos(usedUtxos);
  }
}

final externalServiceTxIdProvider =
    Provider.family.autoDispose<String?, Asset>((ref, asset) {
  if (asset.isSideshift) {
    final sideshiftCurrentOrder = ref.watch(sideshiftPendingOrderProvider);
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
  if (assetBalance == 0) {
    return false;
  }
  return assetBalance >= fee;
}
