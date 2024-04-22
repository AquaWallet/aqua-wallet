import 'dart:math';
import 'package:decimal/decimal.dart';

extension DecimalExt on Decimal {
  static Decimal fromDouble(double value, {int precision = 2}) {
    String formattedString = value.toStringAsFixed(precision);
    try {
      return Decimal.parse(formattedString);
    } catch (e) {
      throw FormatException("Error converting double to Decimal: $e");
    }
  }

  static Decimal fromAssetPrecision(int precision) {
    return Decimal.fromInt(pow(10, precision) as int);
  }

  /// Converts a "sats" amount to a Decimal. "sats" are sats for btc/l-btc,
  /// but for other assets on liquid this concept was overloaded.
  /// eg., For USDT if you have an amount of "$10", and the asset.precision is defined as 8, then
  /// when inputing this amount into a gdk transaction you you would multiply 10 by 10^8 to get 1000000000
  static Decimal satsToDecimal(int sats, int precision) {
    final amountWithoutPrecisionRational =
        Decimal.fromInt(sats) / DecimalExt.fromAssetPrecision(precision);
    return amountWithoutPrecisionRational.toDecimal();
  }

  int toInt() {
    return toBigInt().toInt();
  }
}
