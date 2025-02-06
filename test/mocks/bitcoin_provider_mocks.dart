import 'package:aqua/data/data.dart';
import 'package:mocktail/mocktail.dart';

import '../features/send/providers/new/send_asset_input_provider_test.dart';

class MockBitcoinProvider extends Mock implements BitcoinProvider {}

extension MockBitcoinProviderX on MockBitcoinProvider {
  void mockBitcoinRateCall({
    required int rate,
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
}
