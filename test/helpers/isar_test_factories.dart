import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:boltz/boltz.dart' as boltz;

SwapOrderDbModel createSwapOrder({
  required String orderId,
  String? walletId,
  DateTime? createdAt,
  String fromAsset = 'BTC-LBTC',
  String toAsset = 'USDT',
  String depositAddress = 'deposit',
  String settleAddress = 'settle',
  String depositAmount = '100',
  String settleAmount = '50',
  SwapFeeType serviceFeeType = SwapFeeType.percentageFee,
  String serviceFeeValue = '0.05',
  SwapFeeCurrency serviceFeeCurrency = SwapFeeCurrency.usd,
  SwapOrderStatus status = SwapOrderStatus.processing,
  SwapOrderType type = SwapOrderType.variable,
  SwapServiceSource serviceType = SwapServiceSource.sideshift,
  String? onchainTxHash,
}) =>
    SwapOrderDbModel(
      orderId: orderId,
      walletId: walletId,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      fromAsset: fromAsset,
      toAsset: toAsset,
      depositAddress: depositAddress,
      settleAddress: settleAddress,
      depositAmount: depositAmount,
      settleAmount: settleAmount,
      serviceFeeType: serviceFeeType,
      serviceFeeValue: serviceFeeValue,
      serviceFeeCurrency: serviceFeeCurrency,
      status: status,
      type: type,
      serviceType: serviceType,
      onchainTxHash: onchainTxHash,
    );

TransactionDbModel createTransaction({
  required String txhash,
  TransactionDbModelType type = TransactionDbModelType.aquaSend,
  String assetId = 'btc',
  String? walletId,
  String? serviceOrderId,
  SwapServiceSource? swapServiceSource,
}) =>
    TransactionDbModel(
      txhash: txhash,
      type: type,
      assetId: assetId,
      walletId: walletId,
      serviceOrderId: serviceOrderId,
      swapServiceSource: swapServiceSource,
    );

PegOrderDbModel createPegOrder({
  required String orderId,
  bool isPegIn = true,
  int amount = 100000,
  String statusJson = '{}',
  DateTime? createdAt,
  String? walletId,
}) =>
    PegOrderDbModel(
      orderId: orderId,
      isPegIn: isPegIn,
      amount: amount,
      statusJson: statusJson,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      walletId: walletId,
    );

BoltzSwapDbModel createBoltzSwap({
  required String boltzId,
  String invoice = 'lnbc...',
  boltz.SwapType kind = boltz.SwapType.submarine,
  boltz.Chain network = boltz.Chain.liquidTestnet,
  String hashlock = 'hashlock',
  String receiverPubkey = 'receiver',
  String senderPubkey = 'sender',
  int outAmount = 50000,
  String blindingKey = 'blinding',
  int locktime = 123456,
  String scriptAddress = 'script',
  String? walletId,
}) =>
    BoltzSwapDbModel(
      boltzId: boltzId,
      invoice: invoice,
      kind: kind,
      network: network,
      hashlock: hashlock,
      receiverPubkey: receiverPubkey,
      senderPubkey: senderPubkey,
      outAmount: outAmount,
      blindingKey: blindingKey,
      locktime: locktime,
      scriptAddress: scriptAddress,
      walletId: walletId,
    );

SideshiftOrderDbModel createSideshiftOrder({
  int id = 1,
  required String orderId,
  DateTime? createdAt,
  String depositCoin = 'BTC-LBTC',
  String settleCoin = 'USDT',
  String depositAddress = 'deposit',
  String settleAddress = 'settle',
  String depositAmount = '100',
  String settleAmount = '50',
  DateTime? expiresAt,
  SideshiftOrderStatus status = SideshiftOrderStatus.processing,
  SideshiftOrderType type = SideshiftOrderType.variable,
  String? onchainTxHash,
}) =>
    SideshiftOrderDbModel(
      id: id,
      orderId: orderId,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      depositCoin: depositCoin,
      settleCoin: settleCoin,
      depositAddress: depositAddress,
      settleAddress: settleAddress,
      depositAmount: depositAmount,
      settleAmount: settleAmount,
      expiresAt: expiresAt,
      status: status,
      type: type,
      onchainTxHash: onchainTxHash,
    );
