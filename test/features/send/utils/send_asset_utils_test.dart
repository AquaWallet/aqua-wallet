import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isDifferentAsset', () {
    test('should return true when assets have different IDs', () {
      final asset1 = Asset.unknown().copyWith(id: 'btc');
      final asset2 = Asset.unknown().copyWith(id: 'lbtc');

      expect(isDifferentAsset(asset1, asset2), true);
    });

    test('should return false when assets have same ID', () {
      final asset1 = Asset.unknown().copyWith(id: 'btc');
      final asset2 = Asset.unknown().copyWith(id: 'btc');

      expect(isDifferentAsset(asset1, asset2), false);
    });

    test('should return false when parsedAsset is null', () {
      final asset = Asset.unknown();

      expect(isDifferentAsset(asset, null), false);
    });
  });

  group('getSwapPair', () {
    test('should return null for unknown/regular assets', () {
      // For most assets, this will return null
      // The actual SwapPair creation is tested in integration with the provider
      final asset = Asset.unknown();

      final result = getSwapPair(asset);

      // Unknown asset should return null since it's not alt USDT
      expect(result, isNull);
    });
  });

  group('determineTransactionType', () {
    test('should return explicitly provided transaction type', () {
      final args = SendAssetArguments.fromAsset(Asset.unknown())
          .copyWith(transactionType: SendTransactionType.topUp);

      expect(
        determineTransactionType(args),
        SendTransactionType.topUp,
      );
    });

    test('should return privateKeySweep when external private key is provided',
        () {
      final args = SendAssetArguments.fromAsset(Asset.unknown())
          .copyWith(externalPrivateKey: 'somekey');

      expect(
        determineTransactionType(args),
        SendTransactionType.privateKeySweep,
      );
    });

    test('should return send as default', () {
      final args = SendAssetArguments.fromAsset(Asset.unknown());

      expect(determineTransactionType(args), SendTransactionType.send);
    });

    test('should prioritize explicit transaction type over private key', () {
      final args = SendAssetArguments.fromAsset(Asset.unknown()).copyWith(
        transactionType: SendTransactionType.topUp,
        externalPrivateKey: 'somekey',
      );

      expect(
        determineTransactionType(args),
        SendTransactionType.topUp,
      );
    });
  });

  group('switchAsset', () {
    test('should keep current asset when parsed asset is the same', () {
      final asset = Asset.unknown().copyWith(id: 'btc');

      final result = switchAsset(
        asset: asset,
        parsedAsset: asset,
        isLiquidButNotLBTC: (_) => false,
        isLBTC: (_) => false,
      );

      expect(result.id, asset.id);
    });

    test('should switch to parsed asset when different', () {
      final currentAsset = Asset.unknown().copyWith(id: 'btc');
      final parsedAsset = Asset.unknown().copyWith(id: 'lbtc');

      final result = switchAsset(
        asset: currentAsset,
        parsedAsset: parsedAsset,
        isLiquidButNotLBTC: (_) => false,
        isLBTC: (_) => false,
      );

      expect(result.id, parsedAsset.id);
    });

    test('should keep original when switching from non-LBTC Liquid to LBTC',
        () {
      final currentAsset = Asset.unknown().copyWith(id: 'usdt-liquid');
      final parsedAsset = Asset.unknown().copyWith(id: 'lbtc');

      final result = switchAsset(
        asset: currentAsset,
        parsedAsset: parsedAsset,
        isLiquidButNotLBTC: (Asset a) => a.id == 'usdt-liquid',
        isLBTC: (Asset a) => a.id == 'lbtc',
      );

      // Should keep the original USDt Liquid asset
      expect(result.id, currentAsset.id);
    });

    test('should switch from BTC to LBTC normally', () {
      final currentAsset = Asset.unknown().copyWith(id: 'btc');
      final parsedAsset = Asset.unknown().copyWith(id: 'lbtc');

      final result = switchAsset(
        asset: currentAsset,
        parsedAsset: parsedAsset,
        isLiquidButNotLBTC: (Asset a) => false,
        isLBTC: (Asset a) => a.id == 'lbtc',
      );

      // Should switch to LBTC
      expect(result.id, parsedAsset.id);
    });

    test('should return current asset when parsedAsset is null', () {
      final currentAsset = Asset.unknown().copyWith(id: 'btc');

      final result = switchAsset(
        asset: currentAsset,
        parsedAsset: null,
        isLiquidButNotLBTC: (_) => false,
        isLBTC: (_) => false,
      );

      expect(result.id, currentAsset.id);
    });
  });

  group('calculateParsedAmount', () {
    test('should return currentAmount when parsedAmount is null', () {
      final result = calculateParsedAmount(
        parsedAmount: null,
        parsedAsset: null,
        currentAmount: 1000,
        parseAssetAmountToSats: (amount, precision, asset) => 0,
      );

      expect(result, 1000);
    });

    test('should return 0 when both parsedAmount and currentAmount are null',
        () {
      final result = calculateParsedAmount(
        parsedAmount: null,
        parsedAsset: null,
        currentAmount: null,
        parseAssetAmountToSats: (amount, precision, asset) => 0,
      );

      expect(result, 0);
    });

    test('should return amount as-is for Lightning assets', () {
      final lightningAsset =
          Asset.lightning(); // Lightning asset has id == 'lightning'
      final result = calculateParsedAmount(
        parsedAmount: Decimal.fromInt(5000),
        parsedAsset: lightningAsset,
        currentAmount: 1000,
        parseAssetAmountToSats: (amount, precision, asset) =>
            throw Exception('Should not be called for Lightning'),
      );

      expect(result, 5000);
    });

    test('should call parseAssetAmountToSats for non-Lightning assets', () {
      final btcAsset = Asset.btc(); // BTC asset is not Lightning
      var callbackCalled = false;

      final result = calculateParsedAmount(
        parsedAmount: Decimal.parse('0.001'),
        parsedAsset: btcAsset,
        currentAmount: 1000,
        parseAssetAmountToSats: (amount, precision, asset) {
          callbackCalled = true;
          expect(amount, '0.001');
          expect(precision, 8);
          expect(asset?.id, btcAsset.id);
          return 100000; // 0.001 BTC in sats
        },
      );

      expect(result, 100000);
      expect(callbackCalled, true);
    });

    test('should handle assets with default precision', () {
      final assetWithDefaultPrecision = Asset.unknown().copyWith(precision: 0);

      final result = calculateParsedAmount(
        parsedAmount: Decimal.parse('100'),
        parsedAsset: assetWithDefaultPrecision,
        currentAmount: 0,
        parseAssetAmountToSats: (amount, precision, asset) {
          expect(precision, 0);
          return 100;
        },
      );

      expect(result, 100);
    });

    test('should handle null parsedAsset', () {
      final result = calculateParsedAmount(
        parsedAmount: Decimal.parse('0.5'),
        parsedAsset: null,
        currentAmount: 1000,
        parseAssetAmountToSats: (amount, precision, asset) {
          expect(asset, null);
          expect(precision, 0); // Should default to 0
          return 50000000;
        },
      );

      expect(result, 50000000);
    });
  });
}
