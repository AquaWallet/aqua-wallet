import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiveArguments.fromAsset', () {
    test('Liquid USDT has no swap pair', () {
      final args = ReceiveArguments.fromAsset(Asset.usdtLiquid());

      expect(args.swapPair, isNull);
    });

    test('BTC has no swap pair', () {
      final args = ReceiveArguments.fromAsset(Asset.btc());

      expect(args.swapPair, isNull);
    });

    test('alt USDT receive pairs are from deposit asset to LUSDT', () {
      final cases = <Asset, SwapAsset>{
        Asset.usdtEth(): SwapAssetExt.usdtEth,
        Asset.usdtTrx(): SwapAssetExt.usdtTrx,
        Asset.usdtBep(): SwapAssetExt.usdtBep,
        Asset.usdtSol(): SwapAssetExt.usdtSol,
        Asset.usdtPol(): SwapAssetExt.usdtPol,
        Asset.usdtTon(): SwapAssetExt.usdtTon,
      };

      for (final entry in cases.entries) {
        final args = ReceiveArguments.fromAsset(entry.key);
        expect(args.swapPair, isNotNull, reason: entry.key.id);
        expect(args.swapPair!.from, entry.value, reason: entry.key.id);
        expect(
          args.swapPair!.to,
          SwapAssetExt.usdtLiquid,
          reason: entry.key.id,
        );
      }
    });
  });
}
