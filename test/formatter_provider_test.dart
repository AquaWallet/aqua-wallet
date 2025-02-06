import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua/data/provider/formatter_provider.dart';

void main() {
  final container = ProviderContainer();

  group('convertAssetAmountToDisplayUnit', () {
    test('1 BTC', () async {
      expect(
        container
            .read(formatterProvider)
            .convertAssetAmountToDisplayUnit(amount: 100000000, precision: 8),
        "1",
      );
    });

    test('10.1 BTC', () async {
      expect(
        container
            .read(formatterProvider)
            .convertAssetAmountToDisplayUnit(amount: 1010000000, precision: 8),
        "10.1",
      );
    });

    test('10,000.4536 BTC', () async {
      expect(
        container.read(formatterProvider).convertAssetAmountToDisplayUnit(
            amount: 1000045360000, precision: 8),
        "10000.4536",
      );
    });

    test('0.046292 BTC', () async {
      expect(
        container
            .read(formatterProvider)
            .convertAssetAmountToDisplayUnit(amount: 4629200, precision: 8),
        "0.046292",
      );
    });
  });

  group('parseAssetAmountDirect', () {
    test('simple positive number', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100",
              precision: 2,
            ),
        10000,
      );
    });

    test('negative number', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "-100",
              precision: 2,
            ),
        -10000,
      );
    });

    test('number with commas', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "2,000",
              precision: 2,
            ),
        200000,
      );
    });

    test('negative number with commas', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "-2,000",
              precision: 2,
            ),
        -200000,
      );
    });

    test('decimal number', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100.50",
              precision: 2,
            ),
        10050,
      );
    });

    test('number with spaces', () {
      expect(
        container.read(formatterProvider).parseAssetAmountDirect(
              amount: " 100.50 ",
              precision: 2,
            ),
        10050,
      );
    });

    test('throws on invalid precision (negative)', () {
      expect(
        () => container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100",
              precision: -1,
            ),
        throwsA(isA<ParseAmountWrongPrecissionException>()),
      );
    });

    test('throws on invalid precision (too large)', () {
      expect(
        () => container.read(formatterProvider).parseAssetAmountDirect(
              amount: "100",
              precision: 9,
            ),
        throwsA(isA<ParseAmountWrongPrecissionException>()),
      );
    });

    test('throws on invalid number format', () {
      expect(
        () => container.read(formatterProvider).parseAssetAmountDirect(
              amount: "abc",
              precision: 2,
            ),
        throwsA(isA<ParseAmountUnableParseFromStringWithPrecisionException>()),
      );
    });

    test('throws on empty string', () {
      expect(
        () => container.read(formatterProvider).parseAssetAmountDirect(
              amount: "",
              precision: 2,
            ),
        throwsA(isA<ParseAmountUnableParseFromStringWithPrecisionException>()),
      );
    });
  });
}
