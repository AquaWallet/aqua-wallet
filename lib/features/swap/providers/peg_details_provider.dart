import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';

final pegDetailsProvider = AutoDisposeNotifierProviderFamily<PegDetailsNotifier,
    SwapSuccessModel, PegStateSuccess>(PegDetailsNotifier.new);

class PegDetailsNotifier
    extends AutoDisposeFamilyNotifier<SwapSuccessModel, PegStateSuccess> {
  @override
  SwapSuccessModel build(PegStateSuccess arg) {
    final GdkNewTransactionReply transaction = arg.txn;

    final assets = ref.read(assetsProvider).asData?.value ?? [];

    final fee = transaction.fee ?? 0;
    final received = (transaction.satoshi![arg.asset.id] as int).abs();
    final delivered = received + fee;

    final deliveredAsset =
        assets.firstWhere((asset) => asset.id == arg.asset.id);
    final receivedAsset = assets.firstWhere(
        (asset) => deliveredAsset.isBTC ? asset.isLBTC : asset.isBTC);
    final feeAsset = assets.firstWhere(
        (asset) => deliveredAsset.isBTC ? asset.isBTC : asset.isLBTC);

    final formattedDelivered =
        ref.read(formatterProvider).formatAssetAmountDirect(
              amount: delivered,
              precision: deliveredAsset.precision,
            );
    final formattedReceived =
        ref.read(formatterProvider).formatAssetAmountDirect(
              amount: received,
              precision: receivedAsset.precision,
            );
    final formattedFee = ref.read(formatterProvider).formatAssetAmountDirect(
          amount: fee,
          precision: feeAsset.precision,
        );
    final feeText = '$formattedFee ${feeAsset.ticker}';
    final receivedTicker = receivedAsset.ticker;
    final transactionId = transaction.txhash ?? '-';
    final rate =
        deliveredAsset.isLBTC ? delivered / received : received / delivered;
    final currentRate = rate.toStringAsFixed(rate > 10000 ? 2 : 8);
    final deliveredTicker = deliveredAsset.ticker;
    final feeRate = '1 $deliveredTicker = $currentRate $receivedTicker';

    final timestamp = transaction.createdAt?.microsecondsSinceEpoch;
    final formattedDate = timestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(timestamp).ddMMMMyyyy()
        : '-';
    final formattedTime = timestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(timestamp).HHmmaUTC()
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
      note: transaction.memo,
    );
  }
}
