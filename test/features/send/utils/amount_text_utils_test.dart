import 'package:aqua/features/send/utils/amount_text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('trimToPrecision', () {
    test('should trim BTC amount to 8 decimals', () {
      expect(trimToPrecision('0.123456789012', 8), '0.12345678');
    });

    test('should trim USD amount to 2 decimals', () {
      expect(trimToPrecision('123.45678', 2), '123.45');
    });

    test('should trim EUR amount with comma separator to 2 decimals', () {
      expect(trimToPrecision('123,45678', 2), '123,45');
    });

    test('should not trim amounts within precision limit', () {
      expect(trimToPrecision('0.12345678', 8), '0.12345678');
      expect(trimToPrecision('0.123', 8), '0.123');
      expect(trimToPrecision('123.45', 2), '123.45');
      expect(trimToPrecision('123.4', 2), '123.4');
    });

    test('should handle amounts without decimal separator', () {
      expect(trimToPrecision('123', 8), '123');
      expect(trimToPrecision('100', 2), '100');
    });

    test('should handle empty text', () {
      expect(trimToPrecision('', 8), '');
    });

    test('should handle just decimal separator', () {
      expect(trimToPrecision('.', 8), '.');
      expect(trimToPrecision(',', 2), ',');
    });

    test('should work with any non-digit separator', () {
      // Arabic decimal separator
      expect(trimToPrecision('123٫45678', 2), '123٫45');
    });
  });

  group('normalizeDecimalStart', () {
    test('should prepend "0" when text starts with dot', () {
      expect(normalizeDecimalStart('.5'), '0.5');
      expect(normalizeDecimalStart('.'), '0.');
    });

    test('should prepend "0" when text starts with comma', () {
      expect(normalizeDecimalStart(',5'), '0,5');
      expect(normalizeDecimalStart(','), '0,');
    });

    test('should not modify text starting with a digit', () {
      expect(normalizeDecimalStart('5.0'), '5.0');
      expect(normalizeDecimalStart('123.45'), '123.45');
      expect(normalizeDecimalStart('0.5'), '0.5');
    });

    test('should handle empty text', () {
      expect(normalizeDecimalStart(''), '');
    });

    test('should work with any non-digit separator', () {
      expect(normalizeDecimalStart('٫5'), '0٫5');
    });
  });

  group('Combined usage', () {
    test('should handle normalize then trim', () {
      final normalized = normalizeDecimalStart('.123456789');
      expect(normalized, '0.123456789');

      final trimmed = trimToPrecision(normalized, 8);
      expect(trimmed, '0.12345678');
    });

    test('should handle trim then normalize', () {
      final trimmed = trimToPrecision('.123456789', 8);
      expect(trimmed, '.12345678');

      final normalized = normalizeDecimalStart(trimmed);
      expect(normalized, '0.12345678');
    });
  });
}
