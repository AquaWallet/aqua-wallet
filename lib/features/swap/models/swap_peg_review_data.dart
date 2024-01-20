import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/swap/swap.dart';

class SwapPegReviewModel {
  SwapPegReviewModel({
    required this.asset,
    required this.order,
    required this.transaction,
    required this.deliverAmount,
    required this.feeAmount,
    required this.finalAmount,
    required this.isSendAll,
  });

  final Asset asset;
  final SwapStartPegResult order;
  final GdkNewTransactionReply transaction;
  final int deliverAmount;
  final int feeAmount;
  final int finalAmount;
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
  final String time;
  final String date;
}
