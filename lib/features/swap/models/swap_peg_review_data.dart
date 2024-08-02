import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/swap/swap.dart';

class SwapPegReviewModel {
  SwapPegReviewModel({
    required this.asset,
    required this.order,
    required this.transaction,
    required this.inputAmount,
    required this.feeAmount,
    required this.sendTxAmount,
    required this.receiveAmount,
    required this.isSendAll,
  });

  final Asset asset;
  final SwapStartPegResult order;
  final GdkNewTransactionReply transaction;
  final int inputAmount;
  final int feeAmount;

  /// The amount to send in the onchain tx to sideswap. Sideswap will then deduct their fee from this amount
  final int sendTxAmount;

  /// The amount the user will receive after sideswap deducts their fee
  final int receiveAmount;
  final bool isSendAll;
}

class SwapSuccessModel {
  const SwapSuccessModel({
    required this.deliverAmount,
    required this.deliverTicker,
    required this.receiveAmount,
    required this.receiveTicker,
    required this.networkFee,
    required this.feeRate,
    required this.transactionId,
    required this.sideswapOrderId,
    required this.time,
    required this.date,
    this.note,
  });

  final String receiveAmount;
  final String deliverAmount;
  final String receiveTicker;
  final String deliverTicker;
  final String networkFee;
  final String feeRate;
  final String? note;
  final String transactionId;
  final String sideswapOrderId;
  final String time;
  final String date;
}
