import 'package:flutter_test/flutter_test.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/config/constants/svgs.dart';
import 'package:decimal/decimal.dart';

void main() {
  group('SwapAssetExt', () {
    test('toAsset converts SwapAsset to Asset correctly', () {
      const swapAsset =
          SwapAsset(id: AssetIds.btc, name: 'Bitcoin', ticker: 'BTC');
      final asset = swapAsset.toAsset();

      expect(asset.id, equals(AssetIds.btc));
      expect(asset.name, equals('Bitcoin'));
      expect(asset.ticker, equals('BTC'));
      expect(asset.logoUrl, equals(Svgs.btcAsset));
      expect(asset.isDefaultAsset, isFalse);
      expect(asset.isLiquid, isFalse);
      expect(asset.isLBTC, isFalse);
      expect(asset.isUSDt, isFalse);
    });

    test('isUSDt correctly identifies USDt assets', () {
      expect(SwapAssetExt.usdtEth.isUSDt(), isTrue);
      expect(SwapAssetExt.usdtTrx.isUSDt(), isTrue);
      expect(SwapAssetExt.usdtBep.isUSDt(), isTrue);
      expect(SwapAssetExt.usdtSol.isUSDt(), isTrue);
      expect(SwapAssetExt.usdtPol.isUSDt(), isTrue);
      expect(SwapAssetExt.usdtTon.isUSDt(), isTrue);
      expect(SwapAssetExt.usdtLiquid.isUSDt(), isTrue);
      expect(SwapAssetExt.btc.isUSDt(), isFalse);
      expect(SwapAssetExt.lbtc.isUSDt(), isFalse);
    });

    test('getLogoUrl returns correct logo for various assets', () {
      expect(SwapAssetExt.btc.getLogoUrl(), equals(Svgs.btcAsset));
      expect(SwapAssetExt.usdtEth.getLogoUrl(), equals(Svgs.ethUsdtAsset));
      expect(SwapAssetExt.usdtTrx.getLogoUrl(), equals(Svgs.tronUsdtAsset));
      expect(SwapAssetExt.usdtBep.getLogoUrl(), equals(Svgs.bepUsdtAsset));
      expect(SwapAssetExt.usdtSol.getLogoUrl(), equals(Svgs.solUsdtAsset));
      expect(SwapAssetExt.usdtPol.getLogoUrl(), equals(Svgs.polUsdtAsset));
      expect(SwapAssetExt.usdtTon.getLogoUrl(), equals(Svgs.tonUsdtAsset));
      expect(SwapAssetExt.usdtLiquid.getLogoUrl(), equals(Svgs.usdtAsset));
      expect(SwapAssetExt.lbtc.getLogoUrl(), equals(Svgs.unknownAsset));
    });

    test('fromAsset creates SwapAsset correctly', () {
      final asset = Asset(
        id: AssetIds.btc,
        name: 'Bitcoin',
        ticker: 'BTC',
        logoUrl: Svgs.btcAsset,
        isDefaultAsset: false,
        isLiquid: false,
        isLBTC: false,
        isUSDt: false,
      );
      final swapAsset = SwapAssetExt.fromAsset(asset);

      expect(swapAsset.id, equals(AssetIds.btc));
      expect(swapAsset.name, equals('Bitcoin'));
      expect(swapAsset.ticker, equals('BTC'));
    });

    test('fromId creates SwapAsset correctly for known assets', () {
      expect(SwapAssetExt.fromId(AssetIds.btc), equals(SwapAssetExt.btc));
      expect(
          SwapAssetExt.fromId(AssetIds.usdtEth), equals(SwapAssetExt.usdtEth));
      expect(
          SwapAssetExt.fromId(AssetIds.usdtTrx), equals(SwapAssetExt.usdtTrx));
    });

    test('fromId creates unknown SwapAsset for unknown id', () {
      final unknownAsset = SwapAssetExt.fromId('unknown_id');
      expect(unknownAsset.id, equals('unknown_id'));
      expect(unknownAsset.name, equals('Unknown'));
      expect(unknownAsset.ticker, equals('Unknown'));
    });
  });

  group('SwapFeeExtension', () {
    test('displayFee formats flat fee correctly', () {
      final flatFee = SwapFee(
        type: SwapFeeType.flatFee,
        value: Decimal.parse('10.5'),
        currency: SwapFeeCurrency.usd,
      );
      expect(flatFee.displayFee(), equals('10.50 USD'));
    });

    test('displayFee formats percentage fee correctly', () {
      final percentageFee = SwapFee(
        type: SwapFeeType.percentageFee,
        value: Decimal.parse('0.025'),
        currency: SwapFeeCurrency.usd,
      );
      expect(percentageFee.displayFee(), equals('2.50%'));
    });

    test('displayFee formats flat fee in sats correctly', () {
      final flatFeeSats = SwapFee(
        type: SwapFeeType.flatFee,
        value: Decimal.parse('1000'),
        currency: SwapFeeCurrency.sats,
      );
      expect(flatFeeSats.displayFee(), equals('1000 sats'));
    });
  });

  group('NetworkFeeExtension', () {
    const mockSwapAsset = SwapAsset(
      id: 'mock_id',
      name: 'Mock Asset',
      ticker: 'MOCK',
    );

    final mockSwapFee = SwapFee(
      type: SwapFeeType.flatFee,
      value: Decimal.parse('0.1'),
      currency: SwapFeeCurrency.usd,
    );

    test('displayNetworkFeeForUSDt formats fee correctly', () {
      final order = SwapOrder(
        createdAt: DateTime.now(),
        id: 'mock_order_id',
        from: mockSwapAsset,
        to: mockSwapAsset,
        depositAddress: 'mock_deposit_address',
        settleAddress: 'mock_settle_address',
        depositAmount: Decimal.parse('100'),
        serviceFee: mockSwapFee,
        status: SwapOrderStatus.waiting,
        serviceType: SwapServiceSource.sideshift,
        settleCoinNetworkFee: Decimal.parse('1.23'),
      );
      expect(order.displayNetworkFeeForUSDt, equals('1.23'));
    });

    test('displayNetworkFeeForUSDt handles null fee', () {
      final order = SwapOrder(
        createdAt: DateTime.now(),
        id: 'mock_order_id',
        from: mockSwapAsset,
        to: mockSwapAsset,
        depositAddress: 'mock_deposit_address',
        settleAddress: 'mock_settle_address',
        depositAmount: Decimal.parse('100'),
        serviceFee: mockSwapFee,
        status: SwapOrderStatus.waiting,
        serviceType: SwapServiceSource.sideshift,
        settleCoinNetworkFee: null,
      );
      expect(order.displayNetworkFeeForUSDt, equals('0.00'));
    });
  });

  group('SwapServiceTypeExtension', () {
    test('displayName returns correct names', () {
      expect(SwapServiceSource.sideshift.displayName, equals('SideShift'));
      expect(SwapServiceSource.changelly.displayName, equals('Changelly'));
    });

    group('serviceUrl', () {
      test('returns correct URL for SideShift without orderId', () {
        expect(SwapServiceSource.sideshift.serviceUrl(),
            equals('https://sideshift.ai/'));
      });

      test('returns correct URL for SideShift with orderId', () {
        expect(
          SwapServiceSource.sideshift.serviceUrl(orderId: 'test123'),
          equals('https://sideshift.ai/?orderId=test123'),
        );
      });

      test('returns correct URL for Changelly without orderId', () {
        expect(
          SwapServiceSource.changelly.serviceUrl(),
          equals('https://changelly.com'),
        );
      });

      test('returns correct URL for Changelly with orderId', () {
        expect(
          SwapServiceSource.changelly.serviceUrl(orderId: 'test123'),
          equals('https://changelly.com/faq/submit-a-ticket/?orderid=test123'),
        );
      });
    });
  });
}
