import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:decimal/decimal.dart';
import 'package:mocktail/mocktail.dart';

class MockConversionProvider extends Mock {
  SatoshiToFiatConversionModel? call((Asset, int) params);
}

extension MockConversionProviderX on MockConversionProvider {
  void mockConversionForAsset(
      Asset asset, SatoshiToFiatConversionModel conversion) {
    when(() => call((asset, any()))).thenReturn(conversion);
  }

  void mockConversionForAll(SatoshiToFiatConversionModel conversion) {
    when(() => call(any())).thenReturn(conversion);
  }

  void mockNoConversion() {
    when(() => call(any())).thenReturn(null);
  }

  // Mock conversion function
  static SatoshiToFiatConversionModel? mockConversion({String? formatted}) {
    return formatted != null
        ? SatoshiToFiatConversionModel(
            currencySymbol: '\$',
            decimal: Decimal.parse('50.00'),
            formatted: formatted,
            formattedWithCurrency: '\$$formatted',
          )
        : null;
  }
}
