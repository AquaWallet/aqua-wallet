import 'package:aqua/features/receive/widgets/receive_swap_information.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getProviderTitle', () {
    test('Sideshift order with empty providerName returns SideShift', () {
      final order = SwapOrder(
        createdAt: DateTime.now(),
        id: 'test_sideshift_order',
        from: SwapAssetExt.usdtEth,
        to: SwapAssetExt.usdtLiquid,
        depositAddress: '0xDepositAddress',
        settleAddress: 'lq1SettleAddress',
        depositAmount: Decimal.parse('100'),
        settleAmount: Decimal.parse('99'),
        serviceFee: SwapFee(
          type: SwapFeeType.flatFee,
          value: Decimal.parse('1'),
          currency: SwapFeeCurrency.usd,
        ),
        status: SwapOrderStatus.waiting,
        serviceType: SwapServiceSource.sideshift,
      );

      final swapPair = SwapPair(
        from: SwapAssetExt.usdtEth,
        to: SwapAssetExt.usdtLiquid,
      );

      final result = ReceiveSwapInformation.getProviderTitle(order, swapPair);

      expect(result, 'SideShift');
    });

    test('Changelly order with empty providerName returns Changelly', () {
      final order = SwapOrder(
        createdAt: DateTime.now(),
        id: 'test_changelly_order',
        from: SwapAssetExt.usdtEth,
        to: SwapAssetExt.usdtLiquid,
        depositAddress: '0xDepositAddress',
        settleAddress: 'lq1SettleAddress',
        depositAmount: Decimal.parse('100'),
        settleAmount: Decimal.parse('99'),
        serviceFee: SwapFee(
          type: SwapFeeType.flatFee,
          value: Decimal.parse('1'),
          currency: SwapFeeCurrency.usd,
        ),
        status: SwapOrderStatus.waiting,
        serviceType: SwapServiceSource.changelly,
      );

      final swapPair = SwapPair(
        from: SwapAssetExt.usdtEth,
        to: SwapAssetExt.usdtLiquid,
      );

      final result = ReceiveSwapInformation.getProviderTitle(order, swapPair);

      // This verifies the bug fix - previously would have returned "Shift" because
      // providerName was hardcoded to return 'Shift' for all alt-USDT assets
      expect(result, 'Changelly');
      expect(result, isNot('Shift'));
    });

    test('Null order returns empty string', () {
      final swapPair = SwapPair(
        from: SwapAssetExt.usdtEth,
        to: SwapAssetExt.usdtLiquid,
      );

      final result = ReceiveSwapInformation.getProviderTitle(null, swapPair);

      expect(result, '');
    });
  });
}
