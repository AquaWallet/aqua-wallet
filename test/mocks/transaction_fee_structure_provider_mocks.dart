import 'package:aqua/features/transactions/transactions.dart';

class MockTransactionFeeStructureNotifier
    extends TransactionFeeStructureNotifier {
  final FeeStructure? mockFeeStructure;

  MockTransactionFeeStructureNotifier({this.mockFeeStructure});

  @override
  Future<FeeStructure> build(FeeStructureArguments arg) async {
    if (mockFeeStructure != null) {
      return mockFeeStructure!;
    }

    // Default mock fee structure for USDt swaps
    return const FeeStructure.usdtSwap(
      serviceFee: 0.9,
      serviceFeePercentage: 0.9,
      receiveNetworkFee: 0.1,
      estimatedSendNetworkFee: 0.05,
      totalFees: 1.05,
      totalFeesCrypto: '0.00001050 USDt',
    );
  }
}
