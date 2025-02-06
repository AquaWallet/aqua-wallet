import 'package:aqua/data/data.dart';
import 'package:mocktail/mocktail.dart';

class MockFeeEstimateClient extends Mock implements FeeEstimateClient {}

extension MockFeeEstimateClientX on MockFeeEstimateClient {
  void mockFetchBitcoinFeeRates(Map<TransactionPriority, double> fees) {
    when(() => fetchBitcoinFeeRates()).thenAnswer((_) async => fees);
  }

  void mockGetLiquidFeeRate(double fee) {
    when(() => getLiquidFeeRate()).thenAnswer((_) => fee);
  }
}
