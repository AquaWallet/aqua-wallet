import 'package:aqua/data/models/database/sideshift_order_model.dart';
import 'package:aqua/features/sideshift/models/sideshift_assets.dart';
import 'package:aqua/features/sideshift/models/sideshift_order.dart';
import 'package:aqua/features/sideshift/models/sideshift_order_status.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';

extension SwapOrderToSideshiftOrderDbModel on SideshiftOrderDbModel {
  static SideshiftOrderDbModel fromSwapOrder(SwapOrder order) {
    return SideshiftOrderDbModel(
      orderId: order.id,
      createdAt: DateTime.now(),
      depositCoin: order.from.ticker,
      settleCoin: order.to.ticker,
      depositNetwork: SideshiftAssetExt.getNetworkString(order.from.id),
      settleNetwork: SideshiftAssetExt.getNetworkString(order.to.id),
      depositAddress: order.depositAddress,
      settleAddress: order.settleAddress,
      depositAmount: order.depositAmount.toString(),
      settleAmount: order.settleAmount?.toString(),
      expiresAt: order.expiresAt,
      status: SideshiftOrderStatusExt.fromSwapOrderStatus(order.status),
      type: SideshiftOrderTypeExt.fromSwapOrderType(order.type),
      depositMin: order.depositAmount.toString(),
      depositMax: null,
      updatedAt: DateTime.now(),
      depositHash: null,
      settleHash: null,
      depositReceivedAt: null,
      rate: null,
      onchainTxHash: null,
    );
  }
}

extension SideshiftOrderTypeExt on SideshiftOrderType {
  static SideshiftOrderType fromSwapOrderType(SwapOrderType type) {
    switch (type) {
      case SwapOrderType.variable:
        return SideshiftOrderType.variable;
      case SwapOrderType.fixed:
        return SideshiftOrderType.fixed;
      default:
        throw ArgumentError('Unknown SwapOrderType: $type');
    }
  }

  SwapOrderType toSwapOrderType() {
    switch (this) {
      case SideshiftOrderType.variable:
        return SwapOrderType.variable;
      case SideshiftOrderType.fixed:
        return SwapOrderType.fixed;
      default:
        throw ArgumentError('Unknown SideshiftOrderType: $this');
    }
  }
}
