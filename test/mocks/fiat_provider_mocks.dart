import 'package:aqua/data/data.dart';
import 'package:decimal/decimal.dart';
import 'package:mocktail/mocktail.dart';

class MockFiatProvider extends Mock implements FiatProvider {}

extension MockFiatProviderX on MockFiatProvider {
  void mockFormatSatsToFiatWithRateDisplayCall({
    required String returnValue,
  }) {
    when(() => formatSatsToFiatWithRateDisplay(
          asset: any(named: 'asset'),
          satoshi: any(named: 'satoshi'),
          rate: any(named: 'rate'),
          currencyCode: any(named: 'currencyCode'),
        )).thenReturn(returnValue);
  }

  void mockSatoshiToFiatCall({
    required Decimal returnValue,
  }) {
    when(() => satoshiToFiat(
          any(),
          any(),
          any(),
        )).thenReturn(returnValue);
  }

  void mockFormatFiatCall({
    required String returnValue,
  }) {
    when(() => formatFiat(
          any(),
          any(),
          withSymbol: any(),
        )).thenReturn(returnValue);
  }

  void mockFiatToSatoshi({
    required Decimal returnValue,
  }) {
    when(() => fiatToSatoshi(
          any(),
          any(),
        )).thenAnswer((_) async => returnValue);
  }
}
