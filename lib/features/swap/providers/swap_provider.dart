import 'dart:async';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';

final swapProvider =
    AutoDisposeAsyncNotifierProvider<SwapNotifier, SwapState>(SwapNotifier.new);

class SwapNotifier extends AutoDisposeAsyncNotifier<SwapState> {
  @override
  FutureOr<SwapState> build() => const SwapState.empty();

  void requestVerification(SwapStartWebResponse response) {
    state = AsyncData(SwapState.pendingVerification(data: response));
  }

  Future<void> markSwapSuccess(SwapDoneResponse response) async {
    final txId = response.params!.txid!;
    final recvAsset = response.params!.recvAsset;

    final assets = ref.read(assetsProvider).asData?.value ?? [];
    final asset = assets.firstWhere((asset) => recvAsset == asset.id);
    final transaction = await ref.read(_assetTransactionsProvider(txId).future);

    await ref.read(transactionStorageProvider.notifier).save(TransactionDbModel(
          txhash: txId,
          assetId: asset.id,
          type: TransactionDbModelType.sideswapSwap,
          serviceOrderId: response.params!.orderId,
        ));

    state = AsyncData(SwapState.success(
      asset: asset,
      transaction: transaction!,
    ));
  }

  Future<void> executeTransaction() async {
    try {
      final currentState = state.asData?.value;
      if (currentState is SwapStateVerify) {
        state = const AsyncValue.loading();
        final data = currentState.data;
        final result = data.result!;
        final reply =
            await ref.read(sideswapHttpProvider).createPsetDetailsReply(result);
        final url = Uri.parse(result.uploadUrl!);
        final responseBody = await ref
            .read(sideswapHttpProvider)
            .httpStartWebParamsBody(reply, result, url);

        if (responseBody.containsKey('error')) {
          final errorBody = Error.fromJson(responseBody);
          if (errorBody.error?.message != null) {
            final error =
                SideswapHttpStateNetworkError(errorBody.error!.message);
            state = AsyncValue.error(error, StackTrace.current);
            throw error;
          }
        }

        final signBody = await ref
            .read(sideswapHttpProvider)
            .httpBodySign(responseBody, result, url);

        if (signBody.containsKey('error')) {
          final errorBody = Error.fromJson(signBody);
          if (errorBody.error?.message != null) {
            final error =
                SideswapHttpStateNetworkError(errorBody.error!.message);
            state = AsyncValue.error(error, StackTrace.current);
            throw error;
          }
        }
      }
    } catch (err, stackTrace) {
      if (err is SideswapHttpProcessStartWrongData) {
        const error = SideswapHttpStateNetworkError('Wrong response data');
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
      if (err is SideswapHttpProcessStartNullCreateDetailsReply) {
        const error = SideswapHttpStateNetworkError("Can't create pset");
        state = AsyncValue.error(error, StackTrace.current);
        throw error;
      }
      final error = SideswapHttpState.error(err, stackTrace);
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
  }
}

final _assetTransactionEventsProvider =
    StreamProvider.autoDispose<void>((ref) async* {
  yield* ref.read(liquidProvider).transactionEventSubject;
});

final _assetTransactionsProvider = FutureProvider.autoDispose
    .family<GdkTransaction?, String>((ref, txnId) async {
  await ref.read(_assetTransactionEventsProvider.future);

  final transactions = await ref.read(liquidProvider).getTransactions() ?? [];
  return transactions.firstWhereOrNull((txn) => txnId == txn.txhash);
});
