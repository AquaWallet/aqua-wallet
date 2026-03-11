import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bip21 amount conversion', () {
    test('encodeBip21AmountFromSats keeps precision for sats assets', () {
      const amountInSats = 123000000;
      final result = encodeBip21AmountFromSats(
        amountInSats: amountInSats,
        asset: Asset.btc(),
      );

      expect(result, '1.23');
    });

    test('encodeBip21AmountFromSats scales non-sats assets to base precision',
        () {
      const amountInSats = 100000000;
      final asset = Asset(
        id: 'test-asset',
        name: 'Test Asset',
        ticker: 'TEST',
        logoUrl: Svgs.unknownAsset,
        precision: 2,
      );

      final result = encodeBip21AmountFromSats(
        amountInSats: amountInSats,
        asset: asset,
      );

      expect(result, '0.000001');
    });

    test('decodeBip21AmountToSats keeps precision for sats assets', () {
      final result = decodeBip21AmountToSats(
        bip21Amount: Decimal.parse('1.23'),
        asset: Asset.btc(),
      );

      expect(result, 123000000);
    });

    test('decodeBip21AmountToSats scales non-sats assets to sats', () {
      final asset = Asset(
        id: 'test-asset',
        name: 'Test Asset',
        ticker: 'TEST',
        logoUrl: Svgs.unknownAsset,
        precision: 2,
      );

      final result = decodeBip21AmountToSats(
        bip21Amount: Decimal.parse('0.000001'),
        asset: asset,
      );

      expect(result, 100000000);
    });
  });

  group('validateBip21Amount', () {
    final btcAsset = Asset.btc();
    final asset = Asset(
      id: 'test-asset',
      name: 'Test Asset',
      ticker: 'TEST',
      logoUrl: Svgs.unknownAsset,
      precision: 2,
    );

    String buildAddress({
      String? amount,
      String? assetId,
    }) {
      final queryParams = <String>[];
      if (amount != null) {
        queryParams.add('amount=$amount');
      }
      if (assetId != null) {
        queryParams.add('assetid=$assetId');
      }
      if (queryParams.isEmpty) {
        return 'liquidnetwork:addr';
      }
      return 'liquidnetwork:addr?${queryParams.join('&')}';
    }

    test('returns true for non-bip21 addresses', () {
      final result = validateBip21Amount(
        amountInSats: 100,
        asset: asset,
        address: 'not-a-bip21-address',
      );

      expect(result, isTrue);
    });

    test('returns true when amount is missing', () {
      final result = validateBip21Amount(
        amountInSats: 100,
        asset: asset,
        address: buildAddress(assetId: asset.id),
      );

      expect(result, isTrue);
    });

    test('returns true when asset id is missing', () {
      final result = validateBip21Amount(
        amountInSats: 100,
        asset: asset,
        address: buildAddress(amount: '1.0'),
      );

      expect(result, isTrue);
    });

    test('returns false when asset id mismatches', () {
      final result = validateBip21Amount(
        amountInSats: 100,
        asset: asset,
        address: buildAddress(amount: '0.000001', assetId: 'other-asset'),
      );

      expect(result, isFalse);
    });

    test('returns true for bitcoin bip21 when amount matches', () {
      const amountInSats = 100000000;

      final result = validateBip21Amount(
        amountInSats: amountInSats,
        asset: btcAsset,
        address: 'bitcoin:addr?amount=1.0',
      );

      expect(result, isTrue);
    });

    test('returns false for bitcoin bip21 when amount mismatches', () {
      const amountInSats = 100000000;

      final result = validateBip21Amount(
        amountInSats: amountInSats,
        asset: btcAsset,
        address: 'bitcoin:addr?amount=2.0',
      );

      expect(result, isFalse);
    });

    test('returns false when bitcoin bip21 is used with non-btc asset', () {
      const amountInSats = 100000000;

      final result = validateBip21Amount(
        amountInSats: amountInSats,
        asset: asset,
        address: 'bitcoin:addr?amount=1.0',
      );

      expect(result, isFalse);
    });

    test('returns true when asset id and amount match', () {
      const amountInSats = 100000000;
      final amount = encodeBip21AmountFromSats(
        amountInSats: amountInSats,
        asset: asset,
      );

      final result = validateBip21Amount(
        amountInSats: amountInSats,
        asset: asset,
        address: buildAddress(amount: amount, assetId: asset.id),
      );

      expect(result, isTrue);
    });

    test('returns false when amount mismatches', () {
      const amountInSats = 100000000;

      final result = validateBip21Amount(
        amountInSats: amountInSats,
        asset: asset,
        address: buildAddress(amount: '0.000002', assetId: asset.id),
      );

      expect(result, isFalse);
    });
  });
}
