import 'package:aqua/features/transactions/transactions.dart';
import 'package:mocktail/mocktail.dart';

class MockFiatAmountProvider extends Mock {
  Future<String> call(TransactionUiModel model) async => '';
}

extension MockFiatAmountProviderX on MockFiatAmountProvider {
  void mockFiatAmountForModel(TransactionUiModel model, String fiatAmount) {
    when(() => call(model)).thenAnswer((_) async => fiatAmount);
  }

  void mockFiatAmountForAll(String fiatAmount) {
    when(() => call(any())).thenAnswer((_) async => fiatAmount);
  }

  // Mock fiat amount function for testing
  static Future<String> mockFiatAmount(String amount) async => amount;
}
