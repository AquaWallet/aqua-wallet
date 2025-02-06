import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:mocktail/mocktail.dart';

class MockSideshiftHttpProvider extends Mock implements SideshiftHttpProvider {}

extension MockSideshiftHttpProviderX on MockSideshiftHttpProvider {
  void mockFetchSideShiftAssetPair(SideShiftAssetPairInfo value) {
    when(() => fetchSideShiftAssetPair(any(), any()))
        .thenAnswer((_) async => value);
  }
}

class MockSideshiftService extends Mock implements SideshiftService {}

extension MockSideshiftServiceX on MockSideshiftService {
  void mockGetRate(SwapRate value) {
    when(() => getRate(
          any(),
          amount: any(named: 'amount'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => value);
  }

  void mockCreateSendOrder(SwapOrder order, [SwapOrderRequest? request]) {
    when(() => createSendOrder(any())).thenAnswer((_) async {
      return request != null
          ? order.copyWith(depositAmount: request.amount!)
          : order;
    });
  }

  void mockCacheOrderToDatabase() {
    when(() => cacheOrderToDatabase(any(), any())).thenAnswer((_) async {});
  }
}
