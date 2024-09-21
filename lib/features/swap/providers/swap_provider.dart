import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:rxdart/rxdart.dart';

final swapProvider =
    AutoDisposeAsyncNotifierProvider<SwapNotifier, SwapState>(SwapNotifier.new);

class SwapNotifier extends AutoDisposeAsyncNotifier<SwapState> {
  @override
  FutureOr<SwapState> build() => const SwapState.empty();

  void requestVerification(SwapStartWebResponse response) {
    state = AsyncData(SwapState.pendingVerification(data: response));
  }

  Future<void> processSwapCompletion(SwapDoneResponse response) async {
    final orderId = response.params!.orderId!;
    final txId = response.params!.txid!;
    final recvAsset = response.params!.recvAsset;

    final assets = ref.read(assetsProvider).asData?.value ?? [];
    final asset = assets.firstWhere((asset) => recvAsset == asset.id);

    await ref.read(transactionStorageProvider.notifier).save(TransactionDbModel(
          txhash: txId,
          assetId: asset.id,
          serviceOrderId: orderId,
          type: TransactionDbModelType.sideswapSwap,
        ));

    final successState = await ref
        .read(completedTransactionStreamProvider(txId).future)
        .then((transaction) => SwapState.createSuccessFromGdkTxn(
              asset: asset,
              orderId: orderId,
              transaction: transaction,
            ))
        .catchError((error, stackTrace) {
      logger.e('[Swap] Completed Txn Error', error, stackTrace);
      return SwapState.createSuccessFromSwapResponse(
        asset: asset,
        orderId: orderId,
        response: response,
      );
    });

    state = AsyncData(successState);
  }

  throwOnErrorResponse(Map<String, dynamic> response) {
    if (response.containsKey('error')) {
      final errorBody = Error.fromJson(response);
      if (errorBody.error?.message != null) {
        final error = SideswapHttpStateNetworkError(errorBody.error!.message);
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
    }
  }

  Future<void> executeTransaction() async {
    try {
      final currentState = state.asData?.value;
      if (currentState is SwapStateVerify) {
        state = const AsyncValue.loading();
        final result = currentState.data.result!;

        if (result.sendAsset == result.recvAsset) {
          throw SideSwapExecuteInvalidAssetException();
        }

        if (result.sendAmount == 0 || result.recvAmount == 0) {
          throw SideSwapExecuteInvalidAmountException();
        }

        final allUtxos = await ref.read(liquidProvider).getUnspentOutputs();
        final sendAssetUtxos = allUtxos!.unsentOutputs![result.sendAsset];
        // sort utxos by amount in decreasing order
        sendAssetUtxos!.sort((a, b) => b.satoshi!.compareTo(a.satoshi!));
        final List<GdkUnspentOutputs> selectedSendAssetUtxos = [];
        var selectedUtxosSatsSum = 0;
        for (final utxo in sendAssetUtxos) {
          if (selectedUtxosSatsSum >= result.sendAmount) {
            break;
          }

          selectedSendAssetUtxos.add(utxo);
          selectedUtxosSatsSum = selectedUtxosSatsSum + utxo.satoshi!;
        }

        if (selectedUtxosSatsSum < result.sendAmount) {
          throw SideSwapExecuteInsufficientFundsException();
        }

        logger.d('[Swap] selected utxos: $selectedSendAssetUtxos');

        final receiveAddress =
            await ref.read(liquidProvider).getReceiveAddress();
        final changeAddress =
            await ref.read(liquidProvider).getReceiveAddress();

        if (receiveAddress == null || changeAddress == null) {
          throw 'Error';
        }

        final inputs = selectedSendAssetUtxos
            .map((utxo) => GdkCreatePsetInputs(
                asset: utxo.assetId,
                assetBf: utxo.assetBlinder,
                txid: utxo.txhash,
                value: utxo.satoshi,
                valueBf: utxo.amountBlinder,
                vout: utxo.ptIdx))
            .toList();

        final url = Uri.parse(result.uploadUrl);
        final responseBody =
            await ref.read(sideswapHttpProvider).httpStartWebParamsBody(
                HttpStartWebParams(
                  orderId: result.orderId,
                  inputs: inputs,
                  recvAddr: receiveAddress.address!,
                  changeAddr: changeAddress.address!,
                  sendAsset: result.sendAsset,
                  sendAmount: result.sendAmount,
                  recvAsset: result.recvAsset,
                  recvAmount: result.recvAmount,
                ),
                result,
                url);

        throwOnErrorResponse(responseBody);

        final bodyResult = responseBody["result"] as Map<String, dynamic>;
        final pset = bodyResult["pset"] as String;
        final submitId = bodyResult["submit_id"] as String;

        final utxosGdk = allUtxos.unsentOutputs!.entries.expand((entry) {
          return entry.value.map((output) => output.toJson());
        }).toList();

        final psbtTx = await ref
            .read(liquidProvider)
            .getDetailsPsbt(GdkPsbtGetDetails(psbt: pset, utxos: utxosGdk));
        if (psbtTx == null) {
          throw SideSwapExecutePsbtVerificationFailedException();
        }

        psbtTx.transactionOutputs?.firstWhere(
            (element) =>
                element['asset_id'] == result.recvAsset &&
                element['satoshi'] == result.recvAmount,
            orElse: () =>
                throw SideSwapExecutePsbtVerificationFailedException());

        final signDetails = GdkSignPsbtDetails(psbt: pset, utxos: utxosGdk);

        final signedPsbtTx =
            await ref.read(liquidProvider).signPsbt(signDetails);

        if (signedPsbtTx?.psbt == null) {
          throw SideswapHttpProcessStartNullCreateDetailsReply();
        }

        logger.d('[Swap] signedPset: ', signedPsbtTx!.psbt);

        if (ref.read(featureFlagsProvider).fakeBroadcastsEnabled) {
          return;
        }

        final signBody = await ref
            .read(sideswapHttpProvider)
            .httpBodySign(signedPsbtTx.psbt!, result, submitId, url);

        throwOnErrorResponse(signBody);
      }
    } catch (err, stackTrace) {
      final error = switch (err) {
        SideswapHttpProcessStartWrongData _ =>
          const SideswapHttpStateNetworkError('Wrong response data'),
        SideswapHttpProcessStartNullCreateDetailsReply _ =>
          const SideswapHttpStateNetworkError("Can't create pset"),
        SideSwapExecuteInvalidAssetException _ =>
          const SideswapHttpStateNetworkError("Invalid asset"),
        SideSwapExecuteInvalidAmountException _ =>
          const SideswapHttpStateNetworkError(
              "Send and receive amounts must be positive"),
        SideSwapExecuteInsufficientFundsException _ =>
          const SideswapHttpStateNetworkError("Insufficient funds"),
        SideSwapExecutePsbtVerificationFailedException _ =>
          const SideswapHttpStateNetworkError("Failed to verify pset"),
        _ => SideswapHttpState.error(err, stackTrace)
      };

      state = AsyncValue.error(error, StackTrace.current);
      logger.e('[Swap] ExecuteTransaction Error', error, StackTrace.current);
      throw error;
    }
  }
}

final completedTransactionStreamProvider = StreamProvider.autoDispose
    .family<GdkTransaction, String>((ref, txId) async* {
  //NOTE: This is a temporary remedy that reduces the possibility of a scenario
  // where gdk sends the event yet the transaction has not yet been cached,
  // resulting in an infinite loading state
  // TODO: Fix race-condition between GDK transaction event stream and txns
  logger.d('[Swap] Delay before subscribing to txn stream for txId: $txId');
  await Future.delayed(const Duration(seconds: 5));
  logger.d('[Swap] Subscribing to txn stream for txId: $txId');

  yield* ref
      .read(liquidProvider)
      .transactionEventSubject
      .whereNotNull()
      .where((event) => event.txhash == txId)
      .asyncMap((_) =>
          ref.read(liquidProvider).getTransactions(requiresRefresh: true))
      .whereNotNull()
      .map((txns) => txns.firstWhereOrNull((txn) => txId == txn.txhash))
      .whereNotNull()
      .timeout(const Duration(seconds: 30));
});

final completedTransactionProvider = FutureProvider.autoDispose
    .family<GdkTransaction, String>((ref, txId) async {
  final stream = ref.read(liquidProvider).transactionEventSubject;

  await for (var event in stream) {
    if (event != null && event.txhash == txId) {
      final transaction =
          await ref.read(_matchingTransactionProvider(txId).future);
      if (transaction == null) {
        throw SideSwapExecuteBroadcastTxFetchException();
      }
      return Future.value(transaction);
    }
  }
  throw Exception("Transaction with txId $txId not found");
});

final _matchingTransactionProvider = FutureProvider.autoDispose
    .family<GdkTransaction?, String>((ref, txnId) async {
  final transactions = await ref.read(liquidProvider).getTransactions() ?? [];
  return transactions.firstWhereOrNull((txn) => txnId == txn.txhash);
});

class SideSwapExecuteInvalidAssetException implements Exception {}

class SideSwapExecuteInvalidAmountException implements Exception {}

class SideSwapExecuteInsufficientFundsException implements Exception {}

class SideSwapExecutePsbtVerificationFailedException implements Exception {}

class SideSwapExecuteBroadcastTxFetchException implements Exception {}
