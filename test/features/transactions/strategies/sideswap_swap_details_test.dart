import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';
import 'transaction_details_test_helper.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Asset.lbtc());
    registerFallbackValue(Asset.usdtLiquid());
    registerFallbackValue(MockAppLocalizations());
  });

  group('SideswapSwapTransactionUiModelCreator - Details Methods', () {
    late StrategyDetailsTestSetup setup;
    late ProviderContainer container;
    late SideswapSwapTransactionUiModelCreator strategy;

    setUp(() {
      setup = StrategyDetailsTestSetup();
      setup.setUp();
      container = setup.createContainer();

      strategy = container.read(sideswapSwapTransactionUiModelsProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('createPendingDetails', () {
      test('creates pending swap details', () async {
        when(() => setup.mockAssetResolutionService.resolveSwapAssetsFromDb(
              dbTxn: any(named: 'dbTxn'),
              asset: any(named: 'asset'),
              networkTxn: any(named: 'networkTxn'),
              availableAssets: any(named: 'availableAssets'),
            )).thenReturn((
          fromAsset: Asset.lbtc(),
          toAsset: Asset.usdtLiquid(),
        ));

        final dbTxn = createMockDbTransaction(
          txhash: 'pending_swap',
          assetId: Asset.lbtc().id,
          type: TransactionDbModelType.sideswapSwap,
          isGhost: true,
          ghostTxnAmount: -50000000,
          ghostTxnCreatedAt: DateTime.now(),
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc(), Asset.usdtLiquid()],
          dbTransaction: dbTxn,
        );

        final result = await strategy.createPendingDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be swap'),
          receive: (_) => fail('Should be swap'),
          swap: (details) {
            expect(details.transactionId, 'pending_swap');
            expect(details.isPending, true);
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.receiveAsset.id, Asset.usdtLiquid().id);
          },
          peg: (_) => fail('Should be swap'),
          redeposit: (_) => fail('Should be swap'),
        );
      });
    });

    group('createConfirmedDetails', () {
      test('creates confirmed swap details with network transaction', () async {
        final networkTxn = createMockNetworkTransaction(
          txhash: 'confirmed_swap',
          type: GdkTransactionTypeEnum.swap,
          blockHeight: 100,
          swapOutgoingAssetId: Asset.lbtc().id,
          swapIncomingAssetId: Asset.usdtLiquid().id,
          swapOutgoingSatoshi: -50000000,
          swapIncomingSatoshi: 100000000000,
          fee: 1000,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [Asset.lbtc(), Asset.usdtLiquid()],
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNotNull);
        result!.map(
          send: (_) => fail('Should be swap'),
          receive: (_) => fail('Should be swap'),
          swap: (details) {
            expect(details.transactionId, 'confirmed_swap');
            expect(details.confirmationCount, 2);
            expect(details.deliverAsset.id, Asset.lbtc().id);
            expect(details.receiveAsset.id, Asset.usdtLiquid().id);
          },
          peg: (_) => fail('Should be swap'),
          redeposit: (_) => fail('Should be swap'),
        );
      });

      test('returns null when not a swap transaction', () async {
        final networkTxn = createMockNetworkTransaction(
          type: GdkTransactionTypeEnum.incoming,
        );

        final args = TransactionDetailsStrategyArgs(
          asset: Asset.lbtc(),
          availableAssets: [],
          networkTransaction: networkTxn,
        );

        final result = await strategy.createConfirmedDetails(args);

        expect(result, isNull);
      });
    });
  });
}
