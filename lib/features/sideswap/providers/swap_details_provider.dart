import 'package:coin_cz/data/provider/formatter_provider.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/utils/utils.dart';

final swapDetailsProvider = AutoDisposeNotifierProviderFamily<
    SwapDetailsNotifier,
    SwapSuccessModel,
    SwapStateSuccess>(SwapDetailsNotifier.new);

class SwapDetailsNotifier
    extends AutoDisposeFamilyNotifier<SwapSuccessModel, SwapStateSuccess> {
  @override
  SwapSuccessModel build(SwapStateSuccess arg) {
    final assets = ref.read(assetsProvider).asData?.value ?? [];

    final delivered = (arg.swapOutgoingSatoshi as int).abs();
    final deliveredAsset =
        assets.firstWhere((asset) => asset.id == arg.swapOutgoingAssetId);
    final formattedDelivered =
        ref.read(formatterProvider).formatAssetAmountDirect(
              amount: delivered,
              precision: deliveredAsset.precision,
            );

    final feeAsset =
        assets.firstWhere((a) => deliveredAsset.isBTC ? a.isBTC : a.isLBTC);

    final deliveredTicker = deliveredAsset.ticker;

    final received = arg.swapIncomingSatoshi as int;
    final receivedAsset =
        assets.firstWhere((asset) => asset.id == arg.swapIncomingAssetId);
    final formattedReceived =
        ref.read(formatterProvider).formatAssetAmountDirect(
              amount: received,
              precision: receivedAsset.precision,
            );
    final receivedTicker = receivedAsset.ticker;

    final transactionId = arg.txhash ?? '-';

    final fee = arg.fee;
    final formattedFee = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: fee ?? 0,
          precision: feeAsset.precision,
        );
    final feeText = '$formattedFee ${feeAsset.ticker}';
    final rate =
        deliveredAsset.isLBTC ? delivered / received : received / delivered;
    final currentRate = rate.toStringAsFixed(rate > 10000 ? 2 : 8);
    final feeRate = '1 $deliveredTicker = $currentRate $receivedTicker';

    final timestamp = arg.createdAtTs;
    final formattedDate = timestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(timestamp).ddMMMMyyyy()
        : '-';
    final formattedTime = timestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(timestamp).HHmma()
        : '-';

    return SwapSuccessModel(
      date: formattedDate,
      time: formattedTime,
      deliverAmount: formattedDelivered,
      receiveAmount: formattedReceived,
      deliverTicker: deliveredTicker,
      receiveTicker: receivedTicker,
      transactionId: transactionId,
      sideswapOrderId: arg.orderId,
      networkFee: feeText,
      feeRate: feeRate,
      note: arg.memo,
    );
  }
}
