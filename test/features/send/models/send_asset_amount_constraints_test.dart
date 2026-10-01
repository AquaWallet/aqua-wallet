import 'package:aqua/constants.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SendAssetAmountConstraints.lightning', () {
    const boltzMinimal = 1000;
    const boltzMaximal = 500000;
    const batchedMin = 50;

    test(
      'falls back to Boltz minimal (not GDK min) when minimalBatched is unavailable',
      () {
        expect(
          boltzMinimal,
          greaterThan(kGdkMinSendAmountLbtcSats),
          reason: 'test assumes Boltz minimal is above GDK min',
        );

        final constraints = SendAssetAmountConstraints.lightning(
          submarineFees: _submarineFees(
            minimal: boltzMinimal,
            maximal: boltzMaximal,
          ),
        );

        expect(constraints.minSats, boltzMinimal);
        expect(constraints.minSats, isNot(kGdkMinSendAmountLbtcSats));
        expect(constraints.maxSats, boltzMaximal);
      },
    );

    test('uses minimalBatched when Boltz provides it', () {
      const batchedAboveGdk = 250;
      expect(
        batchedAboveGdk,
        greaterThan(kGdkMinSendAmountLbtcSats),
      );

      final constraints = SendAssetAmountConstraints.lightning(
        submarineFees: _submarineFees(
          minimal: boltzMinimal,
          maximal: boltzMaximal,
          minimalBatched: batchedAboveGdk,
        ),
      );

      expect(constraints.minSats, batchedAboveGdk);
    });

    test('floors minimalBatched at GDK min when batched min is lower', () {
      expect(batchedMin, lessThan(kGdkMinSendAmountLbtcSats));

      final constraints = SendAssetAmountConstraints.lightning(
        submarineFees: _submarineFees(
          minimal: boltzMinimal,
          maximal: boltzMaximal,
          minimalBatched: batchedMin,
        ),
      );

      expect(constraints.minSats, kGdkMinSendAmountLbtcSats);
    });

    test('raises min to LNURL minSendable when it is higher', () {
      const lnurlMinSats = 5000;
      final constraints = SendAssetAmountConstraints.lightning(
        submarineFees: _submarineFees(
          minimal: boltzMinimal,
          maximal: boltzMaximal,
        ),
        lnurlPayParams: LNURLPayParams(
          minSendable: lnurlMinSats * 1000,
          maxSendable: boltzMaximal * 1000,
        ),
      );

      expect(constraints.minSats, lnurlMinSats);
    });
  });
}

SubmarineFeesAndLimits _submarineFees({
  required int minimal,
  required int maximal,
  int? minimalBatched,
}) {
  final limits = SwapLimits(
    minimal: BigInt.from(minimal),
    maximal: BigInt.from(maximal),
    minimalBatched: minimalBatched != null ? BigInt.from(minimalBatched) : null,
  );
  final fees = SubSwapFees(percentage: 0, minerFees: BigInt.zero);
  return SubmarineFeesAndLimits(
    btcLimits: limits,
    lbtcLimits: limits,
    btcFees: fees,
    lbtcFees: fees,
  );
}
