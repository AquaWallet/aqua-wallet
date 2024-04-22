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

    test('1 INF', () async {
      expect(
        container
            .read(formatterProvider)
            .convertAssetAmountToDisplayUnit(amount: 100, precision: 2),
        "1",
      );
    });
  });
}
