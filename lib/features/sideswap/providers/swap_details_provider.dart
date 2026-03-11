import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';

final swapDetailsProvider = AutoDisposeNotifierProviderFamily<
    SwapDetailsNotifier,
    SwapSuccessModel,
    SwapStateSuccess>(SwapDetailsNotifier.new);

class SwapDetailsNotifier
    extends AutoDisposeFamilyNotifier<SwapSuccessModel, SwapStateSuccess> {
  @override
  SwapSuccessModel build(SwapStateSuccess arg) {
    final assets = ref.read(assetsProvider).asData?.value ?? [];
    final displayUnit = ref.watch(displayUnitsProvider).currentDisplayUnit;
    final formatter = ref.read(formatProvider);
    final delivered = (arg.swapOutgoingSatoshi as int).abs();
    final deliveredAsset =
        assets.firstWhere((asset) => asset.id == arg.swapOutgoingAssetId);
    final formattedDelivered = formatter.formatAssetAmount(
      amount: delivered,
      asset: deliveredAsset,
    );
    final deliveredTicker = deliveredAsset.getDisplayTicker(displayUnit);

    final feeAsset =
        assets.firstWhere((a) => deliveredAsset.isBTC ? a.isBTC : a.isLBTC);

    final received = arg.swapIncomingSatoshi as int;
    final receivedAsset =
        assets.firstWhere((asset) => asset.id == arg.swapIncomingAssetId);
    final formattedReceived = formatter.formatAssetAmount(
      amount: received,
      asset: receivedAsset,
    );
    final receivedTicker = receivedAsset.getDisplayTicker(displayUnit);

    final transactionId = arg.txhash ?? '-';

    final fee = arg.fee;
    final formattedFee = formatter.formatAssetAmount(
      amount: fee ?? 0,
      asset: feeAsset,
    );
    final feeTicker = feeAsset.getDisplayTicker(displayUnit);
    final feeText = '$formattedFee $feeTicker';
    final rate =
        deliveredAsset.isLBTC ? delivered / received : received / delivered;
    final currentRate = rate.toStringAsFixed(rate > 10000 ? 2 : 8);
    final feeRate =
        '1 ${deliveredAsset.ticker} = $currentRate ${receivedAsset.ticker}';

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
