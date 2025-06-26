import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final _logger = CustomLogger(FeatureFlag.send);

final sendAssetTxnProvider = AutoDisposeAsyncNotifierProviderFamily<
    SendAssetTxnNotifier,
    SendAssetTransactionState,
    SendAssetArguments>(SendAssetTxnNotifier.new);

class SendAssetTxnNotifier extends AutoDisposeFamilyAsyncNotifier<
    SendAssetTransactionState, SendAssetArguments> {
  @override
  FutureOr<SendAssetTransactionState> build(SendAssetArguments arg) =>
      const SendAssetTransactionState.idle();

  Future<void> createFeeEstimateTransaction() async {
    // NOTE: For any Liquid asset, we don't need to create a LBTC fee txn if the
    // user has no LBTC funds. A taxi fee estimate will be created separately.
    if (!arg.asset.isBTC) {
      final lbtcBalance = await ref.read(balanceProvider).getLBTCBalance();
      if (lbtcBalance == 0) {
        // ignore: null_argument_to_non_null_type
        return Future.value(null);
      }
    }

    state = await AsyncValue.guard(() async {
      //TODO - Submarine swap provider should be remodeled to a functional class
      // declaration like the sendTransactionExecutorProvider since it is now part
      // of the new send flow, therefore it should not have its own state.
      final input = ref.read(sendAssetInputStateProvider(arg)).value!;
      final txn = input.asset.isLightning
          ? await ref
              .read(boltzSubmarineSwapProvider.notifier)
              .createTxnForSubmarineSwap(
                arguments: arg,
                isFeeEstimateTxn: true,
              )
          : await ref
              .read(sendTransactionExecutorProvider(arg))
              .createTransaction(
                sendInput: input,
              );
      _logger.debug("[Send] Fee Estimate Transaction: ${txn.transactionHash}");

      return SendAssetTransactionState.created(tx: txn);
    });
  }

  Future<void> executeGdkSendTransaction() async {
    try {
      final input = ref.read(sendAssetInputStateProvider(arg)).value!;
      if (input.asset.isLightning) {
        final txn = await ref
            .read(boltzSubmarineSwapProvider.notifier)
            .createTxnForSubmarineSwap(arguments: arg);
        state = AsyncValue.data(SendAssetTransactionState.created(tx: txn));
      } else if (input.feeAsset == FeeAsset.tetherUsdt) {
        await executeTaxiTransaction();
      } else {
        final txn = await ref
            .read(sendTransactionExecutorProvider(arg))
            .createTransaction(
              sendInput: input,
            );
        state = AsyncValue.data(SendAssetTransactionState.created(tx: txn));
      }

      final createdAt = DateTime.now();
      final transaction = state.value?.mapOrNull(created: (value) => value.tx);

      if (transaction == null || transaction.transactionHex == null) {
        throw AquaSendFailedSigningIncompleteTxnError();
      }

      _logger
          .debug('[Send] signing transaction: ${transaction.transactionHex!}');

      final network =
          arg.asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid;

      final String? signedRawTx = await transaction.when(
        gdkTx: (GdkNewTransactionReply gdkTx) async {
          final blindedTxn = arg.asset.isBTC
              ? transaction.txReply
              : await ref
                  .read(liquidProvider)
                  .blindTransaction(transaction.txReply!);

          final signedGdkTx = await ref
              .read(sendTransactionExecutorProvider(arg))
              .signTransaction(
                transaction: blindedTxn!,
                network: network,
              );

          return signedGdkTx.transaction!;
        },
        gdkPsbt: (tx) => tx,
      );

      if (ref.read(featureFlagsProvider).fakeBroadcastsEnabled) {
        state = AsyncValue.data(
          SendAssetTransactionState.complete(
            args: SendAssetCompletionArguments(
              txId: '12345',
              network: network,
              asset: input.asset,
              createdAt: createdAt.microsecondsSinceEpoch,
              amountSats: input.amount,
              amountFiat: input.amountConversionDisplay,
              feeSats: transaction.txReply?.fee,
              feeAsset: input.feeAsset,
              serviceOrderId: input.serviceOrderId,
            ),
          ),
        );
        return;
      }

      final txId = await ref
          .read(sendTransactionExecutorProvider(arg))
          .broadcastTransaction(
            rawTx: signedRawTx!,
            network: network,
            useAquaNode: input.feeAsset == FeeAsset.tetherUsdt,
          );

      // Save transaction to db until it is detected by GDK
      await _saveTransactionData(input, txId, createdAt, transaction);

      // Mark any external metadata necessary
      await _markExternalMetadata(input, txId);

      // NOTE: This should be fixed with DiscountCT, but leaving UTXO caching in for a bit longer won't hurt
      // Cache used utxos for lowball double-spend issue
      if (!input.asset.isBTC) {
        _cacheUsedUtxos(transaction);
      }

      state = AsyncValue.data(SendAssetTransactionState.complete(
        args: SendAssetCompletionArguments(
          createdAt: createdAt.microsecondsSinceEpoch,
          txId: txId,
          network: network,
          asset: input.asset,
          amountSats: input.amount,
          amountFiat: input.amountConversionDisplay,
          feeSats: input.isUsdtFeeAsset
              ? input.taxiFeeSats
              : transaction.txReply?.fee,
          feeAsset: input.feeAsset,
          serviceOrderId: arg.asset.isLightning
              ? ref.read(boltzSubmarineSwapProvider)?.id
              : input.serviceOrderId,
        ),
      ));
    } on MempoolConflictTxBroadcastException {
      // Return exception directly so we can show a retry dialog
      state = AsyncValue.error(
        MempoolConflictTxBroadcastException(),
        StackTrace.current,
      );
    } catch (e, stackTrace) {
      String? errorMessage;
      if (e is DioException) {
        errorMessage = e.response?.data?.toString() ?? e.message;
      }
      _logger.error('[Send] Error', errorMessage ?? e.toString(), stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _saveTransactionData(
    SendAssetInputState input,
    String txId,
    DateTime createdAt,
    SendAssetOnchainTx transaction,
  ) async {
    TransactionDbModel transactionDbModel = TransactionDbModel(
      txhash: txId,
      assetId: arg.asset.id,
      type: input.transactionDbModelType,
      isGhost: arg.asset.isLightning || !arg.asset.isBTC,
      ghostTxnCreatedAt: createdAt,
      ghostTxnAmount: input.amount,
      ghostTxnFee: transaction.txReply?.fee,
      serviceOrderId: input.serviceOrderId,
    );

    if (input.isTopUp) {
      final topUp = await ref.read(topUpInvoiceProvider.future);
      final cards = await ref.read(moonCardsProvider.future);
      final card = cards.first;
      final cardNumber = card.pan.substring(card.pan.length - 4);
      transactionDbModel = transactionDbModel.copyWith(
        type: input.transactionDbModelType,
        serviceOrderId: topUp.invoice?.id,
        serviceAddress: cardNumber,
      );
    }
    await ref
        .read(transactionStorageProvider.notifier)
        .save(transactionDbModel);
  }

  Future<String?> executeTaxiTransaction() async {
    try {
      state = const AsyncLoading();

      final input = ref.read(sendAssetInputStateProvider(arg)).value!;
      final String? address;
      if (!input.asset.isAltUsdt) {
        address = input.addressFieldText;
      } else {
        final swapPair = SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAsset.fromAsset(input.asset),
        );
        final swapArgs = SwapArgs(pair: swapPair);
        final swapOrderState = ref.read(swapOrderProvider(swapArgs));
        address = swapOrderState.value?.order?.depositAddress;
      }

      if (address == null || address.isEmpty) {
        _logger.error('[Send][Taxi] address is null');
        throw AddressParsingException(AddressParsingExceptionType.emptyAddress);
      }

      final usdtAsset = ref.read(manageAssetsProvider).liquidUsdtAsset;
      final taxiState = ref.read(sideswapTaxiProvider).valueOrNull;
      if (taxiState is TaxiStateFinalSignedPset) {
        _logger.debug('[Send][Taxi] Final signed pset exists - returning');
        return taxiState.finalSignedPset;
      }

      final finalPset =
          await ref.read(sideswapTaxiProvider.notifier).createTaxiTransaction(
                taxiAsset: usdtAsset,
                amount: input.amount,
                sendAddress: address,
                sendAll: input.isSendAllFunds,
              );
      _logger.debug('[Send][Taxi] Final signed pset successfully created');
      state = AsyncValue.data(SendAssetTransactionState.created(
        tx: SendAssetOnchainTx.gdkPsbt(finalPset),
      ));
      return finalPset;
    } catch (e) {
      _logger.debug('[Send][Taxi] create taxi tx - error: $e');
      rethrow;
    }
  }

  //ANCHOR: - Used utxos caching
  void _cacheUsedUtxos(SendAssetOnchainTx transaction) {
    // NOTE: cache used utxos to fix lowball issue where spent utxos are not
    // seen until block is mined.
    // Without manually caching these, gdk will re-use these spent utxos if
    // another tx is formed before the this tx is mined
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

          logger.debug(
            '[Lowball] Caching used utxo: '
            'txhash: ${input.txhash}, '
            'ptIdx: ${input.ptIdx}, '
            'satoshi: ${input.satoshi}',
          );
          mappedUtxos[assetId]!.add(input);
        }

        return mappedUtxos;
      },
      // cannot easily parse utxos from psbt at this point
      gdkPsbt: (_) => null,
    );

    if (usedUtxos == null) return;
    ref.read(recentlySpentUtxosProvider.notifier).addUtxos(usedUtxos);
  }

  Future<void> _markExternalMetadata(
      SendAssetInputState input, String txId) async {
    if (input.asset.isLightning) {
      final swap = ref.watch(boltzSubmarineSwapProvider);
      if (swap != null) {
        await ref
            .read(boltzStorageProvider.notifier)
            .updateSubmarineOnBroadcast(boltzId: swap.id, txId: txId);
        _logger.debug("Success - cache tx hash for boltz: $txId");
      }
      return;
    }
  }
}
