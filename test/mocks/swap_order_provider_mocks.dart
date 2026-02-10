import 'package:aqua/data/data.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';

class MockSwapOrderNotifierWithDbOrder extends SwapOrderNotifier {
  final SwapOrderDbModel? Function(SwapArgs)? mockBuilder;

  MockSwapOrderNotifierWithDbOrder({this.mockBuilder});

  @override
  Future<SwapOrderCreationState> build(SwapArgs arg) async {
    final dbOrder = mockBuilder?.call(arg);
    if (dbOrder == null) {
      throw StateError('Incomplete swap order state');
    }

    final swapOrder = dbOrder.toSwapOrder();
    final settleAmount = swapOrder.settleAmount;
    final depositAmount = swapOrder.depositAmount;
    final swapRate = SwapRate(
      rate: settleAmount != null && depositAmount != Decimal.zero
          ? (settleAmount / depositAmount) as Decimal
          : Decimal.one,
      min: Decimal.parse('0.1'),
      max: Decimal.parse('1000'),
    );

    return SwapOrderCreationState(
      order: swapOrder,
      rate: swapRate,
    );
  }
}
