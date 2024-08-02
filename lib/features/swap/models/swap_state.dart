import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_state.freezed.dart';

@freezed
class SwapState with _$SwapState {
  const factory SwapState.empty() = SwapStateEmpty;
  const factory SwapState.pendingVerification({
    required SwapStartWebResponse data,
  }) = SwapStateVerify;
  const factory SwapState.success({
    required Asset asset,
    required String orderId,
    required String? txhash,
    required int? fee,
    required int? swapOutgoingSatoshi,
    required String? swapOutgoingAssetId,
    required int? swapIncomingSatoshi,
    required String? swapIncomingAssetId,
    int? createdAtTs,
    String? memo,
  }) = SwapStateSuccess;

  static SwapStateSuccess createSuccessFromGdkTxn({
    required Asset asset,
    required String orderId,
    required GdkTransaction transaction,
  }) {
    return SwapStateSuccess(
      asset: asset,
      orderId: orderId,
      txhash: transaction.txhash,
      fee: transaction.fee,
      createdAtTs: transaction.createdAtTs,
      swapOutgoingSatoshi: transaction.swapOutgoingSatoshi,
      swapOutgoingAssetId: transaction.swapOutgoingAssetId,
      swapIncomingSatoshi: transaction.swapIncomingSatoshi,
      swapIncomingAssetId: transaction.swapIncomingAssetId,
      memo: transaction.memo,
    );
  }

  static SwapStateSuccess createSuccessFromSwapResponse({
    required Asset asset,
    required String orderId,
    required SwapDoneResponse response,
  }) {
    return SwapStateSuccess(
      asset: asset,
      orderId: orderId,
      txhash: response.params?.txid,
      fee: response.params?.networkFee,
      swapOutgoingSatoshi: response.params?.sendAmount,
      swapOutgoingAssetId: response.params?.sendAsset,
      swapIncomingSatoshi: response.params?.recvAmount,
      swapIncomingAssetId: response.params?.recvAsset,
    );
  }
}

extension SwapStateExt on SwapState? {
  bool get isSuccess => this is SwapStateSuccess;
}
