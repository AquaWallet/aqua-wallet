import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mocks.dart';

void main() {
  group('Aqua Send', () {
    final container = ProviderContainer(overrides: []);
    test('throws argument error if send asset args are not provided', () async {
      const args = FeeStructureArguments.aquaSend();

      expect(
        expectAsync0(
          () => container.read(transactionFeeStructureProvider(args).future),
        ),
        throwsArgumentError,
      );
    });
    test('returns correct fee structure when BTC send', () async {
      const kFeeRate = 100;
      const kEstimatedFee = 1000;
      final asset = Asset.btc();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.btc(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.bitcoin(
          feeRate: kFeeRate,
          estimatedFee: kEstimatedFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<BitcoinSendFee>()
            .having((s) => s.feeRate, 'feeRate', kFeeRate)
            .having((s) => s.estimatedFee, 'estimatedFee', kEstimatedFee),
      );
    });
    test('returns correct fee structure when L-BTC send', () async {
      const kFeeRate = 200;
      const kEstimatedFee = 2000;
      final asset = Asset.liquidTest();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.liquid(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquid(
          feeRate: kFeeRate,
          estimatedFee: kEstimatedFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<LiquidSendFee>()
            .having((s) => s.feeRate, 'feeRate', kFeeRate)
            .having((s) => s.estimatedFee, 'estimatedFee', kEstimatedFee),
      );
    });
    test('returns correct fee structure when L-BTC taxi send', () async {
      const kLbtcFeeRate = 50;
      const kEstimatedLbtcFee = 500;
      const kUsdtFeeRate = 0.1;
      const kEstimatedUsdtFee = 100.0;
      final asset = Asset.liquidTest();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.liquidUsdt(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquidTaxi(
          lbtcFeeRate: kLbtcFeeRate,
          estimatedLbtcFee: kEstimatedLbtcFee,
          usdtFeeRate: kUsdtFeeRate,
          estimatedUsdtFee: kEstimatedUsdtFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<LiquidTaxiSendFee>()
            .having((s) => s.lbtcFeeRate, 'lbtcFeeRate', kLbtcFeeRate)
            .having((s) => s.estimatedLbtcFee, 'lbtcFee', kEstimatedLbtcFee)
            .having((s) => s.usdtFeeRate, 'usdtFeeRate', kUsdtFeeRate)
            .having((s) => s.estimatedUsdtFee, 'usdtFee', kEstimatedUsdtFee),
      );
    });
    test('returns correct fee structure when Lightning send', () async {
      const kFeeRate = 200;
      const kEstimatedFee = 2000;
      final asset = Asset.lightning();
      final args = FeeStructureArguments.aquaSend(
        sendAssetArgs: SendAssetArguments.lightningBtc(asset),
      );
      final mockSendAssetFeeNotifier = MockSendAssetFeeNotifier(
        const SendAssetFeeState.liquid(
          feeRate: kFeeRate,
          estimatedFee: kEstimatedFee,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          sendAssetFeeProvider.overrideWith(() => mockSendAssetFeeNotifier),
        ],
      );

      final state =
          await container.read(transactionFeeStructureProvider(args).future);

      expect(
        state,
        isA<BoltzSendFee>()
            .having((s) => s.onchainFeeRate, 'onchainFeeRate', kFeeRate)
            .having((s) => s.estimatedOnchainFee, 'onchainFee', kEstimatedFee)
            .having(
              (s) => s.swapFeePercentage,
              'swapFeePercentage',
              kBoltzSubmarinePercentFee,
            ),
      );
    });
  });

  group('Sideswap', () {
    const swapInput = SideswapInputState(
      assets: [],
      deliverAsset: null,
      receiveAsset: null,
      deliverAssetBalance: '',
      receiveAssetBalance: '',
    );

    test('returns correct fee when input is peg in', () async {
      const kOnchainFee = 5;
      const kSideswapFeePercentage = 0.1;
      const kSideswapFee = 10;
      final kDeliverAsset = Asset.btc();
      final kReceiveAsset = Asset.liquidTest().copyWith(isLBTC: true);
      final input = swapInput.copyWith(
        deliverAsset: kDeliverAsset,
        receiveAsset: kReceiveAsset,
      );
      final pegState = PegState.pendingVerification(
        data: SwapPegReviewModel(
          asset: kDeliverAsset,
          order: const SwapStartPegResult(
            orderId: '',
            pegAddress: '',
          ),
          transaction: const GdkNewTransactionReply(
            fee: kOnchainFee,
          ),
          inputAmount: 0,
          sendTxAmount: 0,
          receiveAmount: 0,
          firstOnchainFeeAmount: kOnchainFee,
          secondOnchainFeeAmount: kOnchainFee,
          isSendAll: false,
        ),
      );
      final mockFeeEstimateClient = MockFeeEstimateClient();
      final container = ProviderContainer(overrides: [
        pegProvider.overrideWith(() => MockPegNotifier(pegState)),
        feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
        sideswapStatusStreamResultStateProvider.overrideWith(
          (_) => const ServerStatusResult(
            serverFeePercentPegIn: kSideswapFeePercentage,
          ),
        ),
        sideswapInputStateProvider
            .overrideWith((_) => MockSideswapInputStateNotifier(input)),
      ]);
      mockFeeEstimateClient.mockFetchBitcoinFeeRates({
        TransactionPriority.high: kOnchainFee.toDouble(),
      });
      mockFeeEstimateClient.mockGetLiquidFeeRate(kSideswapFee.toDouble());
      const args = FeeStructureArguments.sideswap();
      final provider = transactionFeeStructureProvider(args);

      expect(
        await container.read(provider.future),
        isA<SideswapPegInFee>()
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.estimatedBtcFee),
              'estimatedBtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.estimatedLbtcFee),
              'estimatedLbtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.btcFeeRate),
              'btcFeeRate',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.lbtcFeeRate),
              'lbtcFeeRate',
              kSideswapFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegIn: (s) => s.swapFeePercentage),
              'swapFeePercentage',
              kSideswapFeePercentage,
            ),
      );
    });
    test('returns correct fee when input is peg out', () async {
      const kOnchainFee = 15;
      const kSideswapFeePercentage = 0.1;
      const kSideswapFee = 5;
      final kDeliverAsset = Asset.liquidTest().copyWith(isLBTC: true);
      final kReceiveAsset = Asset.btc();
      final input = swapInput.copyWith(
        deliverAsset: kDeliverAsset,
        receiveAsset: kReceiveAsset,
      );
      final pegState = PegState.pendingVerification(
        data: SwapPegReviewModel(
          asset: kDeliverAsset,
          order: const SwapStartPegResult(
            orderId: '',
            pegAddress: '',
          ),
          transaction: const GdkNewTransactionReply(
            fee: kOnchainFee,
          ),
          inputAmount: 0,
          sendTxAmount: 0,
          receiveAmount: 0,
          firstOnchainFeeAmount: kOnchainFee,
          secondOnchainFeeAmount: kOnchainFee,
          isSendAll: false,
        ),
      );
      final mockFeeEstimateClient = MockFeeEstimateClient();
      final container = ProviderContainer(overrides: [
        pegProvider.overrideWith(() => MockPegNotifier(pegState)),
        feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
        sideswapStatusStreamResultStateProvider.overrideWith(
          (_) => const ServerStatusResult(
            serverFeePercentPegIn: kSideswapFeePercentage,
          ),
        ),
        sideswapInputStateProvider
            .overrideWith((_) => MockSideswapInputStateNotifier(input)),
      ]);
      mockFeeEstimateClient.mockFetchBitcoinFeeRates({
        TransactionPriority.high: kOnchainFee.toDouble(),
      });
      mockFeeEstimateClient.mockGetLiquidFeeRate(kSideswapFee.toDouble());
      const args = FeeStructureArguments.sideswap();
      final provider = transactionFeeStructureProvider(args);

      expect(
        await container.read(provider.future),
        isA<SideswapPegOutFee>()
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.estimatedBtcFee),
              'estimatedBtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.estimatedLbtcFee),
              'estimatedLbtcFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.btcFeeRate),
              'btcFeeRate',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.lbtcFeeRate),
              'lbtcFeeRate',
              kSideswapFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapPegOut: (s) => s.swapFeePercentage),
              'swapFeePercentage',
              kSideswapFeePercentage,
            ),
      );
    });
    test('returns correct fee when input is instant swap', () async {
      const kOnchainFee = 25;
      const kSideswapFeePercentage = 0.6;
      const kSideswapFee = 5;
      final kDeliverAsset = Asset.liquidTest().copyWith(isLBTC: true);
      final kReceiveAsset = Asset.usdtEth();
      final input = swapInput.copyWith(
        deliverAsset: kDeliverAsset,
        receiveAsset: kReceiveAsset,
      );
      final mockFeeEstimateClient = MockFeeEstimateClient();
      final container = ProviderContainer(overrides: [
        feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
        sideswapPriceStreamResultStateProvider.overrideWith(
          (_) => const PriceStreamResult(
            fixedFee: kOnchainFee,
          ),
        ),
        sideswapInputStateProvider
            .overrideWith((_) => MockSideswapInputStateNotifier(input)),
      ]);
      mockFeeEstimateClient.mockGetLiquidFeeRate(kSideswapFee.toDouble());
      const args = FeeStructureArguments.sideswap();
      final provider = transactionFeeStructureProvider(args);

      expect(
        await container.read(provider.future),
        isA<SideswapInstantSwapFee>()
            .having(
              (s) => s.mapOrNull(sideswapInstantSwap: (s) => s.estimatedFee),
              'estimatedFee',
              kOnchainFee,
            )
            .having(
              (s) => s.mapOrNull(sideswapInstantSwap: (s) => s.feeRate),
              'feeRate',
              kSideswapFee,
            )
            .having(
              (s) =>
                  s.mapOrNull(sideswapInstantSwap: (s) => s.swapFeePercentage),
              'swapFeePercentage',
              kSideswapFeePercentage,
            ),
      );
    });
  });
}
