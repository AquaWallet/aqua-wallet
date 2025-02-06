import 'package:aqua/data/data.dart';
import 'package:mocktail/mocktail.dart';

class MockLiquidProvider extends Mock implements LiquidProvider {}

extension MockLiquidProviderX on MockLiquidProvider {
  void mockGetTransactionsCall() {
    when(() => getTransactions(
          requiresRefresh: any(named: 'requiresRefresh'),
          details: any(named: 'details'),
        )).thenAnswer((_) async => []);
  }

  void mockGetReceiveAddress({required String address}) {
    when(() => getReceiveAddress())
        .thenAnswer((_) async => GdkReceiveAddressDetails(address: address));
  }
}
