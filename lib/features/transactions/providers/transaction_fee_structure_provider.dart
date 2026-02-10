import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:decimal/decimal.dart';

const kDefaultSideswapPegFeePercent = 0.1;
const kDefaultSideswapSwapFeePercent = 0.6;
const kEstimatedLiquidSendNetworkFee = 44.0;

final transactionFeeStructureProvider = AutoDisposeAsyncNotifierProviderFamily<
    TransactionFeeStructureNotifier,
    FeeStructure,
    FeeStructureArguments>(TransactionFeeStructureNotifier.new);

class TransactionFeeStructureNotifier extends AutoDisposeFamilyAsyncNotifier<
    FeeStructure, FeeStructureArguments> {
  @override
  FutureOr<FeeStructure> build(FeeStructureArguments arg) async {
    return arg.when(
      aquaSend: (args) async {
        if (args == null) {
          throw ArgumentError();
        }

        final feeState = await ref.watch(sendAssetFeeProvider(args).future);
        return feeState.map(
          bitcoin: (fee) => FeeStructure.bitcoinSend(
            feeRate: fee.feeRate,
            estimatedFee: fee.estimatedFee,
          ),
          liquid: (fee) {
            if (args.asset.isLightning) {
              return FeeStructure.boltzSend(
                onchainFeeRate: fee.feeRate,
                estimatedOnchainFee: fee.estimatedFee,
                swapFeePercentage: kBoltzSubmarinePercentFee,
              );
            }
            return FeeStructure.liquidSend(
              feeRate: fee.feeRate,
              estimatedFee: fee.estimatedFee,
            );
          },
          liquidTaxi: (fee) => FeeStructure.liquidTaxiSend(
            lbtcFeeRate: fee.lbtcFeeRate,
            estimatedLbtcFee: fee.estimatedLbtcFee,
            usdtFeeRate: fee.usdtFeeRate,
            estimatedUsdtFee: fee.estimatedUsdtFee,
          ),
        );
      },
      sideswap: () async {
        final input = ref.watch(sideswapInputStateProvider);
        final liquidFeeRate = ref.read(feeEstimateProvider).getLiquidFeeRate();

        if (input.isPeg) {
          final sideswap = ref.watch(sideswapStatusStreamResultStateProvider);
          final btcRates =
              await ref.read(feeEstimateProvider).fetchBitcoinFeeRates();
          final btcFeeRate = btcRates[TransactionPriority.high]!.toInt();
          final pegState = await ref.watch(pegProvider.future);
          final sendAssetNetworkFee = pegState.maybeMap(
            pendingVerification: (s) => s.data.firstOnchainFeeAmount,
            orElse: () => 0,
          );
          final receiveAssetNetworkFee = pegState.maybeMap(
            pendingVerification: (s) => s.data.secondOnchainFeeAmount,
            orElse: () => 0,
          );
          if (input.isPegIn) {
            return FeeStructure.sideswapPegIn(
              btcFeeRate: btcFeeRate,
              estimatedBtcFee: sendAssetNetworkFee,
              lbtcFeeRate: liquidFeeRate,
              estimatedLbtcFee: receiveAssetNetworkFee,
              swapFeePercentage: sideswap?.serverFeePercentPegIn ??
                  kDefaultSideswapPegFeePercent,
            );
          } else {
            return FeeStructure.sideswapPegOut(
              lbtcFeeRate: liquidFeeRate,
              estimatedLbtcFee: sendAssetNetworkFee,
              btcFeeRate: btcFeeRate,
              estimatedBtcFee: receiveAssetNetworkFee,
              swapFeePercentage: sideswap?.serverFeePercentPegOut ??
                  kDefaultSideswapPegFeePercent,
            );
          }
        } else {
          final estimatedFee = ref.read(sideswapPriceStreamResultStateProvider);
          return FeeStructure.sideswapInstantSwap(
            feeRate: liquidFeeRate,
            estimatedFee: estimatedFee?.fixedFee ?? 0,
            swapFeePercentage: kDefaultSideswapSwapFeePercent,
          );
        }
      },
      usdtSwap: (args) async {
        final deliverAsset = args.asset;
        if (!deliverAsset.isAltUsdt) {
          throw ArgumentError();
        }

        final swapServiceSource =
            ref.watch(preferredUsdtSwapServiceProvider).valueOrNull;
        if (swapServiceSource == null) {
          throw StateError('No swap service selected');
        }

        // Get the input state to check fee selection
        final inputState =
            ref.watch(sendAssetInputStateProvider(args)).valueOrNull;

        // Check if there's an actual transaction with real fee available
        final actualFee = await ref
            .watch(sendAssetFeeProvider(args).future)
            .then((value) => value.maybeMap(
                  liquid: (fee) => fee.estimatedFee,
                  orElse: () => null,
                ))
            .catchError((_) => null);

        final swapPair = SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAsset.fromAsset(deliverAsset),
        );
        final orderState =
            await ref.watch(swapOrderProvider(SwapArgs(pair: swapPair)).future);
        if (orderState.rate?.rate == null ||
            orderState.order?.depositAmount == null ||
            orderState.order?.settleAmount == null) {
          throw StateError('Incomplete swap order state');
        }

        final depositAmount = orderState.order?.depositAmount ?? Decimal.zero;
        final settleAmount = orderState.order?.settleAmount ?? Decimal.zero;
        final settleCoinNetworkFee =
            orderState.order?.settleCoinNetworkFee ?? Decimal.zero;

        return ref
            .read(usdtSwapFeeCalculatorServiceProvider)
            .calculateFeeStructure(
              swapServiceSource: swapServiceSource,
              depositAmount: depositAmount,
              settleAmount: settleAmount,
              settleCoinNetworkFee: settleCoinNetworkFee,
              sendNetworkFeeInSats: actualFee,
              isUsdtFeeAsset: inputState?.isUsdtFeeAsset ?? false,
              usdtFeeInSats: inputState?.taxiFeeSats,
            );
      },
    );
  }
}
