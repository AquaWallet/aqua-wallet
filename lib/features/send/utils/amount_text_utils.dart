/// Utility functions for amount text manipulation and formatting
library;

/// Trims text to the allowed precision by removing excess decimal places.
/// Handles any decimal separator character generically.
///
/// Examples:
/// - `trimToPrecision('0.123456789', 8)` → `'0.12345678'`
/// - `trimToPrecision('123,4567', 2)` → `'123,45'`
/// - `trimToPrecision('100', 8)` → `'100'` (no change for integers)
String trimToPrecision(String text, int precision) {
  if (text.isEmpty) return text;

  // Find the first non-digit character (the decimal separator)
  int separatorIndex = -1;
  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    if (char.codeUnitAt(0) < 48 || char.codeUnitAt(0) > 57) {
      separatorIndex = i;
      break;
    }
  }

  // If no separator found, it's an integer - return as is
  if (separatorIndex == -1) return text;

  final decimalPlaces = text.length - separatorIndex - 1;

  // If within precision limit, return original text
  if (decimalPlaces <= precision) return text;

  // Trim to precision (separator index + 1 for the separator + precision digits)
  return text.substring(0, separatorIndex + 1 + precision);
}

/// Normalizes text that starts with a decimal separator by prepending "0".
/// Handles any non-digit character as decimal separator.
///
/// Examples:
/// - `normalizeDecimalStart('.')` → `'0.'`
/// - `normalizeDecimalStart(',5')` → `'0,5'`
/// - `normalizeDecimalStart('5.0')` → `'5.0'` (no change)
String normalizeDecimalStart(String text) {
  if (text.isEmpty) return text;

  final firstChar = text[0];
  final isFirstCharDigit =
      firstChar.codeUnitAt(0) >= 48 && firstChar.codeUnitAt(0) <= 57;

  // If first character is not a digit (likely a decimal separator), prepend "0"
  if (!isFirstCharDigit) {
    return '0$text';
  }

  return text;
}
