import 'package:aqua/data/data.dart';

extension GdkAmountDataX on GdkAmountData {
  //TODO: Temp solution since GDK doesn't return currency symbols
  String get currencySymbol => switch (fiatCurrency) {
        'EUR' => '€',
        'GBP' => '£',
        'CAD' => 'CA\$',
        'AUD' => 'A\$',
        _ => '\$',
      };
}
