import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:rxdart/rxdart.dart';

final _logger = CustomLogger(FeatureFlag.swap);

const _kSideswapDomain = 'sideswap.io';

/// Whether [url] is an HTTPS endpoint on the SideSwap service origin. Used to
/// allowlist the order's `uploadUrl` before posting wallet inputs / a signed
/// PSET to it.
@visibleForTesting
bool isTrustedSideswapUploadUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host == _kSideswapDomain || host.endsWith('.$_kSideswapDomain');
}

/// Whether the server's [order] matches the assets and amount the user entered
/// in [input]. The PSET delta check trusts [order], but [order] is server-sent;
/// this anchors it to user intent. Only the user-edited side is bounded.
@visibleForTesting
bool isSwapOrderApproved({
  required SwapStartWebResult order,
  required SideswapInputState input,
}) {
  final send = input.userInputSendAmount;
  final recv = input.userInputReceiveAmount;
  // Require at least one user-entered amount to anchor against; otherwise we'd
  // be approving on asset match alone.
  if (send == null && recv == null) {
    return false;
  }
  return order.sendAsset == input.deliverAsset?.id &&
      order.recvAsset == input.receiveAsset?.id &&
      (send == null || order.sendAmount <= send) &&
      (recv == null || order.recvAmount >= recv);
}

/// Whether a swap PSET's effect on the wallet matches what the user approved.
///
/// [walletDelta] is GDK's signed per-asset effect on this wallet (from
/// `psbt_get_details`): negative = leaving, positive = arriving, computed only
/// over wallet-owned inputs/outputs. The swap is approved if the wallet
/// receives at least [order].recvAmount of the receive asset and no asset
/// leaves beyond [order].sendAmount of the send asset (plus [fee] for L-BTC).
@visibleForTesting
bool isSwapPsetDeltaApproved({
  required Map<String, int> walletDelta,
  required SwapStartWebResult order,
  required String lbtcId,
  required int fee,
}) {
  if (walletDelta.isEmpty) {
    return false;
  }
  final received = walletDelta[order.recvAsset] ?? 0;
  if (received < order.recvAmount) {
    return false;
  }
  for (final entry in walletDelta.entries) {
    final assetId = entry.key;
    final leaving = -entry.value; // positive = this asset is leaving the wallet

    // The only outflows the user authorised: the send asset up to sendAmount,
    // plus the L-BTC network fee (fees are always paid in L-BTC). Any other
    // asset, or more than this, must not leave the wallet.
    final allowedToLeave = (assetId == order.sendAsset ? order.sendAmount : 0) +
        (assetId == lbtcId ? fee : 0);

    if (leaving > allowedToLeave) {
      return false;
    }
  }
  return true;
}

final swapProvider =
    AutoDisposeAsyncNotifierProvider<SwapNotifier, SwapState>(SwapNotifier.new);

class SwapNotifier extends AutoDisposeAsyncNotifier<SwapState> {
  @override
  FutureOr<SwapState> build() => const SwapState.empty();

  void requestVerification(SwapStartWebResponse response) {
    state = AsyncData(SwapState.pendingVerification(data: response));
  }

  Future<void> processSwapCompletion(SwapDoneResponse response) async {
    final params = response.params!;
    final orderId = params.orderId!;
    final txId = params.txid!;

    final assets = await ref.read(assetsProvider.future);
    final receiveAsset = assets.firstWhere((a) => params.recvAsset == a.id);

    await ref.read(transactionStorageProvider.notifier).save(TransactionDbModel(
          txhash: txId,
          assetId: receiveAsset.id,
          serviceOrderId: orderId,
          ghostTxnCreatedAt: DateTime.now(),
          ghostTxnAmount: params.recvAmount,
          //NOTE - Only used for LBTC/USDT swaps.
          ghostTxnSideswapDeliverAmount: params.sendAmount,
          ghostTxnFee: params.networkFee,
          type: TransactionDbModelType.sideswapSwap,
        ));

    final successState = await ref
        .read(completedTransactionStreamProvider(txId).future)
        .then((transaction) => SwapState.createSuccessFromGdkTxn(
              asset: receiveAsset,
              orderId: orderId,
              transaction: transaction,
            ))
        .catchError((error, stackTrace) {
      _logger.error('Completed Txn Error', error, stackTrace);
      return SwapState.createSuccessFromSwapResponse(
        asset: receiveAsset,
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

        // verify the order matches what the user selected/entered before uploading any inputs
        if (!isSwapOrderApproved(
          order: result,
          input: ref.read(sideswapInputStateProvider),
        )) {
          throw SideSwapExecuteOrderMismatchException();
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

        _logger.debug('selected utxos: $selectedSendAssetUtxos');

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

        // only ever upload to / sign against a SideSwap origin, so a
        // tampered order can't redirect our inputs + PSET to an attacker server.
        if (!isTrustedSideswapUploadUrl(result.uploadUrl)) {
          throw SideSwapExecuteInvalidUploadUrlException();
        }
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

        // verify GDK's signed per-asset effect on the wallet matches the approved swap
        final approved = isSwapPsetDeltaApproved(
          walletDelta: psbtTx.satoshi ?? const <String, int>{},
          order: result,
          lbtcId: ref.read(manageAssetsProvider).lbtcAsset.id,
          fee: psbtTx.fee ?? 0,
        );
        if (!approved) {
          throw SideSwapExecutePsbtVerificationFailedException();
        }

        final signDetails = GdkSignPsbtDetails(psbt: pset, utxos: utxosGdk);

        final signedPsbtTx =
            await ref.read(liquidProvider).signPsbt(signDetails);

        if (signedPsbtTx?.psbt == null) {
          throw SideswapHttpProcessStartNullCreateDetailsReply();
        }

        _logger.debug('signedPset: ', signedPsbtTx!.psbt);

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
        SideSwapExecuteOrderMismatchException _ =>
          const SideswapHttpStateNetworkError(
              "Order does not match your request"),
        SideSwapExecuteInsufficientFundsException _ =>
          const SideswapHttpStateNetworkError("Insufficient funds"),
        SideSwapExecutePsbtVerificationFailedException _ =>
          const SideswapHttpStateNetworkError("Failed to verify pset"),
        SideSwapExecuteInvalidUploadUrlException _ =>
          const SideswapHttpStateNetworkError("Untrusted upload URL"),
        _ => SideswapHttpState.error(err, stackTrace)
      };

      state = AsyncValue.error(error, StackTrace.current);
      _logger.error('ExecuteTransaction Error', error, StackTrace.current);
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
  _logger.debug('Delay before subscribing to txn stream for txId: $txId');
  await Future.delayed(const Duration(seconds: 5));
  _logger.debug('Subscribing to txn stream for txId: $txId');

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

class SideSwapExecuteOrderMismatchException implements Exception {}

class SideSwapExecuteInsufficientFundsException implements Exception {}

class SideSwapExecutePsbtVerificationFailedException implements Exception {}

class SideSwapExecuteInvalidUploadUrlException implements Exception {}

class SideSwapExecuteBroadcastTxFetchException implements Exception {}
