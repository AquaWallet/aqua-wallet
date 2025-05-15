import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';

final mockSwapOrder1 = SwapOrderDbModel(
  id: 1,
  orderId: 'order1',
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  fromAsset: SwapAssetExt.btc.id,
  toAsset: SwapAssetExt.usdtEth.id,
  depositAddress: 'btcDepositAddress1',
  settleAddress: 'usdtSettleAddress1',
  depositAmount: Decimal.parse('0.5').toString(),
  serviceFeeType: SwapFeeType.flatFee,
  serviceFeeValue: Decimal.parse('0.01').toString(),
  serviceFeeCurrency: SwapFeeCurrency.sats,
  status: SwapOrderStatus.waiting,
  type: SwapOrderType.fixed,
  serviceType: SwapServiceSource.sideshift,
);

final mockSwapOrder2 = SwapOrderDbModel(
  id: 2,
  orderId: 'order2',
  createdAt: DateTime.now().subtract(const Duration(days: 2)),
  fromAsset: SwapAssetExt.usdtEth.id,
  toAsset: SwapAssetExt.btc.id,
  depositAddress: 'ethDepositAddress2',
  settleAddress: 'btcSettleAddress2',
  depositAmount: Decimal.parse('1.0').toString(),
  serviceFeeType: SwapFeeType.percentageFee,
  serviceFeeValue: Decimal.parse('0.02').toString(),
  serviceFeeCurrency: SwapFeeCurrency.usd,
  status: SwapOrderStatus.processing,
  type: SwapOrderType.variable,
  serviceType: SwapServiceSource.changelly,
);

final mockSwapOrder3 = SwapOrderDbModel(
  id: 3,
  orderId: 'order3',
  createdAt: DateTime.now().subtract(const Duration(days: 3)),
  fromAsset: SwapAssetExt.usdtEth.id,
  toAsset: SwapAssetExt.btc.id,
  depositAddress: 'usdtDepositAddress3',
  settleAddress: 'btcSettleAddress3',
  depositAmount: Decimal.parse('2.0').toString(),
  serviceFeeType: SwapFeeType.flatFee,
  serviceFeeValue: Decimal.parse('0.03').toString(),
  serviceFeeCurrency: SwapFeeCurrency.sats,
  status: SwapOrderStatus.completed,
  type: SwapOrderType.fixed,
  serviceType: SwapServiceSource.sideshift,
);
