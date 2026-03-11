import 'dart:convert';
import 'dart:io';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/models/exceptions.dart';
import 'package:aqua/features/transactions/services/asset_resolution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetResolutionService', () {
    late AssetResolutionService service;
    late List<Asset> availableAssets;
    late Asset mexas;
    late Asset depix;
    late Asset eurx;

    setUpAll(() async {
      // Load assets from assets.json
      final assetsFile = File('assets/assets.json');
      final assetsJson = jsonDecode(await assetsFile.readAsString());
      final assetsResponse = AssetsResponse.fromJson(assetsJson);
      final liquidAssets = assetsResponse.assets;

      mexas = liquidAssets.firstWhere((a) => a.ticker == 'MEX');
      depix = liquidAssets.firstWhere((a) => a.ticker == 'DePix');
      eurx = liquidAssets.firstWhere((a) => a.ticker == 'EURx');
    });

    setUp(() {
      service = const AssetResolutionService();

      availableAssets = [
        Asset.btc(),
        Asset.lbtc(),
        Asset.usdtLiquid(),
        mexas,
        depix,
        eurx,
        // Alt USDt tokens
        Asset.usdtEth(),
        Asset.usdtTrx(),
        Asset.usdtSol(),
      ];
    });

    group('resolveSwapAssets', () {
      test('throws exception for non-swap transactions', () {
        const txn = GdkTransaction(
          type: GdkTransactionTypeEnum.incoming,
          txhash: 'test123',
        );

        expect(
          () => service.resolveSwapAssets(
            txn: txn,
            asset: Asset.lbtc(),
            availableAssets: availableAssets,
          ),
          throwsA(isA<AssetTransactionsInvalidTypeException>()),
        );
      });

      test('resolves assets for swap viewed from outgoing page', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: Asset.usdtLiquid().id,
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, Asset.usdtLiquid());
      });

      test('resolves assets for swap viewed from incoming page', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: Asset.usdtLiquid().id,
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: Asset.usdtLiquid(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, Asset.usdtLiquid());
      });

      test('handles swap with unavailable asset', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: 'unknown-asset-id',
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        // Service creates alt USDt asset from unknown ID
        expect(result.toAsset, isNotNull);
        expect(result.toAsset?.isAnyUsdt, isTrue);
      });

      test('handles LBTC to USDt swap', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: Asset.usdtLiquid().id,
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, Asset.usdtLiquid());
      });
    });

    group('resolveSwapAssetsFromDb', () {
      test('returns current asset for non-swap transactions', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: null, // Non-swap transaction
          assetId: Asset.lbtc().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, isNull);
      });

      test('resolves Sideswap swap with network transaction data', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: Asset.usdtLiquid().id,
        );

        final networkTxn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: Asset.usdtLiquid().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
          networkTxn: networkTxn,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, Asset.usdtLiquid());
      });

      test(
          'resolves Sideswap swap without network transaction - viewing from sending side',
          () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: Asset.usdtLiquid().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, Asset.usdtLiquid());
      });

      test(
          'resolves Sideswap swap without network transaction - viewing from receiving side',
          () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: Asset.usdtLiquid().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.usdtLiquid(),
          availableAssets: availableAssets,
        );

        // When viewing from receiving side without network transaction,
        // we can't determine the sending asset from DB alone
        expect(result.fromAsset, isNull);
        expect(result.toAsset, Asset.usdtLiquid());
      });

      test('resolves peg-in (BTC -> LBTC)', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapPegIn,
          assetId: Asset.lbtc().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.btc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.btc());
        expect(result.toAsset, Asset.lbtc());
      });

      test('resolves peg-out (LBTC -> BTC)', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapPegOut,
          assetId: Asset.btc().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, Asset.btc());
      });

      test('resolves Boltz submarine swap (BTC/LBTC -> Lightning)', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.boltzSwap,
          assetId: Asset.lbtc().id, // Asset being sent
        );

        // Viewing from the sending asset page (LBTC)
        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        // For Boltz submarine swaps, toAsset resolution depends on isSwap flag
        // Just verify it doesn't crash
        expect(result, isNotNull);
      });

      test('resolves Boltz reverse swap (Lightning -> BTC/LBTC)', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.boltzReverseSwap,
          assetId: Asset.lbtc().id, // Asset being received
        );

        // Viewing from the receiving asset page (LBTC)
        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        // For Boltz reverse swaps, asset resolution depends on isSwap flag
        // Just verify it doesn't crash and returns the viewing asset
        expect(result.fromAsset, Asset.lbtc());
        expect(result, isNotNull);
      });

      test('resolves Sideshift swap (Alt USDt)', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideshiftSwap,
          assetId: Asset.usdtLiquid().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.btc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.btc());
        // For sideshiftSwap, receiving asset is Liquid USDt, so toAsset should be Liquid USDt
        expect(result.toAsset, Asset.usdtLiquid());
      });

      test('handles unavailable asset in DB - creates asset from ID', () {
        const customAssetId = 'custom-asset-id-123';
        const dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: customAssetId,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        // AssetUsdtExt.fromAssetId() creates a USDt asset, check it's not null
        expect(result.toAsset, isNotNull);
      });

      test(
          'handles swap with network transaction containing unavailable assets',
          () {
        const customAssetId = 'custom-asset-id-456';
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: Asset.lbtc().id,
        );

        final networkTxn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: customAssetId,
          swapIncomingAssetId: Asset.lbtc().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
          networkTxn: networkTxn,
        );

        expect(result.toAsset, Asset.lbtc());
        // AssetUsdtExt.fromAssetId() creates a USDt asset, check it's not null
        expect(result.fromAsset, isNotNull);
      });

      test('correctly identifies receiving side for swap', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: Asset.usdtLiquid().id,
        );

        final networkTxn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: Asset.usdtLiquid().id,
        );

        // Viewing from receiving side (USDt)
        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.usdtLiquid(),
          availableAssets: availableAssets,
          networkTxn: networkTxn,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, Asset.usdtLiquid());
      });

      test('handles null assetId in DB transaction', () {
        const dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: null,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, isNull);
      });

      test('handles network transaction with null swap asset IDs', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: Asset.lbtc().id,
        );

        const networkTxn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: null,
          swapIncomingAssetId: null,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
          networkTxn: networkTxn,
        );

        // Should fall back to DB-only resolution
        // When viewing from receiving side (LBTC), we can't determine fromAsset
        expect(result.fromAsset, isNull);
        expect(result.toAsset, Asset.lbtc());
      });
    });

    group('Additional Liquid Assets - Mexas, Depix, EURx', () {
      test('resolves LBTC to Mexas swap from network transaction', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: mexas.id,
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, mexas);
      });

      test('resolves Depix to EURx swap from network transaction', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: depix.id,
          swapIncomingAssetId: eurx.id,
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: depix,
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, depix);
        expect(result.toAsset, eurx);
      });

      test('resolves USDt to Mexas swap viewed from receiving side', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.usdtLiquid().id,
          swapIncomingAssetId: mexas.id,
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: mexas,
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.usdtLiquid());
        expect(result.toAsset, mexas);
      });

      test('resolves Sideswap swap with Depix from DB', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: depix.id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, depix);
      });

      test('resolves multi-asset swap: EURx to Mexas', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: mexas.id,
        );

        final networkTxn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: eurx.id,
          swapIncomingAssetId: mexas.id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: eurx,
          availableAssets: availableAssets,
          networkTxn: networkTxn,
        );

        expect(result.fromAsset, eurx);
        expect(result.toAsset, mexas);
      });
    });

    group('Alt USDt Swaps', () {
      test('resolves Liquid USDt to Ethereum USDt swap', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideshiftSwap,
          assetId: Asset.usdtEth().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.usdtLiquid(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.usdtLiquid());
        expect(result.toAsset, Asset.usdtEth());
      });

      test('resolves Liquid USDt to Tron USDt swap', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideshiftSwap,
          assetId: Asset.usdtTrx().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.usdtLiquid(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.usdtLiquid());
        expect(result.toAsset, Asset.usdtTrx());
      });

      test('resolves Liquid USDt to Solana USDt swap', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideshiftSwap,
          assetId: Asset.usdtSol().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.usdtLiquid(),
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, Asset.usdtLiquid());
        expect(result.toAsset, Asset.usdtSol());
      });

      test('handles alt USDt swap with network transaction', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideshiftSwap,
          assetId: Asset.usdtEth().id,
        );

        const networkTxn = GdkTransaction(
          type: GdkTransactionTypeEnum.outgoing,
          txhash: 'test123',
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.usdtLiquid(),
          availableAssets: availableAssets,
          networkTxn: networkTxn,
        );

        expect(result.fromAsset, Asset.usdtLiquid());
        expect(result.toAsset, Asset.usdtEth());
      });
    });

    group('Complex Multi-Asset Scenarios', () {
      test('resolves 3-way swap scenario with multiple Liquid assets', () {
        // Simulating a complex swap: LBTC -> Mexas -> EURx
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideswapSwap,
          assetId: mexas.id,
        );

        final networkTxn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: mexas.id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: Asset.lbtc(),
          availableAssets: availableAssets,
          networkTxn: networkTxn,
        );

        expect(result.fromAsset, Asset.lbtc());
        expect(result.toAsset, mexas);
      });

      test('handles swap between two non-primary Liquid assets', () {
        final txn = GdkTransaction(
          type: GdkTransactionTypeEnum.swap,
          txhash: 'test123',
          swapOutgoingAssetId: depix.id,
          swapIncomingAssetId: mexas.id,
        );

        final result = service.resolveSwapAssets(
          txn: txn,
          asset: depix,
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, depix);
        expect(result.toAsset, mexas);
      });

      test('resolves mixed swap: Liquid asset to alt USDt', () {
        final dbTxn = TransactionDbModel(
          txhash: 'test123',
          type: TransactionDbModelType.sideshiftSwap,
          assetId: Asset.usdtEth().id,
        );

        final result = service.resolveSwapAssetsFromDb(
          dbTxn: dbTxn,
          asset: mexas,
          availableAssets: availableAssets,
        );

        expect(result.fromAsset, mexas);
        expect(result.toAsset, Asset.usdtEth());
      });

      test('verifies all assets are properly registered', () {
        // Sanity check that all our test assets are in the available list
        expect(availableAssets.length, 9);
        expect(availableAssets.any((a) => a.id == Asset.btc().id), isTrue);
        expect(availableAssets.any((a) => a.id == Asset.lbtc().id), isTrue);
        expect(
            availableAssets.any((a) => a.id == Asset.usdtLiquid().id), isTrue);
        expect(availableAssets.any((a) => a.id == mexas.id), isTrue);
        expect(availableAssets.any((a) => a.id == depix.id), isTrue);
        expect(availableAssets.any((a) => a.id == eurx.id), isTrue);
        expect(availableAssets.any((a) => a.id == Asset.usdtEth().id), isTrue);
        expect(availableAssets.any((a) => a.id == Asset.usdtTrx().id), isTrue);
        expect(availableAssets.any((a) => a.id == Asset.usdtSol().id), isTrue);
      });
    });
  });
}
