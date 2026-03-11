import 'package:aqua/data/data.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';

class MockLiquidProvider extends Mock implements LiquidProvider {}

extension MockLiquidProviderX on MockLiquidProvider {
  void mockBitcoinRateCall({
    required double rate,
    String currency = kUsdCurrency,
  }) {
    const requestData = GdkConvertData(satoshi: 1);
    final responseData = GdkAmountData(
      fiatRate: rate.toString(),
      fiatCurrency: currency,
    );
    when(() => convertAmount(requestData))
        .thenAnswer((_) => Future.value(responseData));
  }

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
