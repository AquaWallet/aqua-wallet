import 'dart:async';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';

typedef Swap = (Asset, GdkTransaction);

final swapDetailsProvider = AutoDisposeAsyncNotifierProviderFamily<
    SwapDetailsNotifier, SwapSuccessModel, Swap>(SwapDetailsNotifier.new);

class SwapDetailsNotifier
    extends AutoDisposeFamilyAsyncNotifier<SwapSuccessModel, Swap> {
  @override
  FutureOr<SwapSuccessModel> build(Swap arg) async {
    state = const AsyncValue.loading();

    final transaction = arg.$2;

    final assets = ref.read(assetsProvider).asData?.value ?? [];

    final delivered = (transaction.swapOutgoingSatoshi as int).abs();
    final deliveredAsset = assets
        .firstWhere((asset) => asset.id == transaction.swapOutgoingAssetId);
    final formattedDelivered =
        ref.read(formatterProvider).formatAssetAmountDirect(
              amount: delivered,
              precision: deliveredAsset.precision,
            );

    final feeAsset =
        assets.firstWhere((a) => deliveredAsset.isBTC ? a.isBTC : a.isLBTC);

    final deliveredTicker = deliveredAsset.ticker;

    final received = transaction.swapIncomingSatoshi as int;
    final receivedAsset = assets
        .firstWhere((asset) => asset.id == transaction.swapIncomingAssetId);
    final formattedReceived =
        ref.read(formatterProvider).formatAssetAmountDirect(
              amount: received,
              precision: receivedAsset.precision,
            );
    final receivedTicker = receivedAsset.ticker;

    final transactionId = transaction.txhash ?? '-';

    final fee = transaction.fee;
    final formattedFee = ref.read(formatterProvider).signedFormatAssetAmount(
          amount: -(fee ?? 0),
          precision: feeAsset.precision,
        );
    final feeText = '$formattedFee ${feeAsset.ticker}';
    final rate =
        deliveredAsset.isLBTC ? delivered / received : received / delivered;
    final currentRate = rate.toStringAsFixed(rate > 10000 ? 2 : 8);
    final feeRate = '1 $deliveredTicker = $currentRate $receivedTicker';

    final timestamp = transaction.createdAtTs;
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
      networkFee: feeText,
      feeRate: feeRate,
      note: transaction.memo,
    );
  }
}
