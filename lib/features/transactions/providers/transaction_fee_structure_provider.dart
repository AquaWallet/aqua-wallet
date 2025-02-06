import 'dart:async';

import 'package:aqua/common/decimal/decimal_ext.dart';
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
          final estimatedBtcFee = pegState.maybeMap(
            pendingVerification: (s) => s.data.firstOnchainFeeAmount,
            orElse: () => 0,
          );
          final estimatedLbtcFee = pegState.maybeMap(
            pendingVerification: (s) => s.data.secondOnchainFeeAmount,
            orElse: () => 0,
          );
          if (input.isPegIn) {
            return FeeStructure.sideswapPegIn(
              btcFeeRate: btcFeeRate,
              estimatedBtcFee: estimatedBtcFee,
              lbtcFeeRate: liquidFeeRate,
              estimatedLbtcFee: estimatedLbtcFee,
              swapFeePercentage: sideswap?.serverFeePercentPegIn ??
                  kDefaultSideswapPegFeePercent,
            );
          } else {
            return FeeStructure.sideswapPegOut(
              lbtcFeeRate: liquidFeeRate,
              estimatedLbtcFee: estimatedLbtcFee,
              btcFeeRate: btcFeeRate,
              estimatedBtcFee: estimatedBtcFee,
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

        final swapPair = SwapPair(
            from: SwapAssetExt.usdtLiquid,
            to: SwapAsset.fromAsset(deliverAsset));
        final orderState =
            await ref.watch(swapOrderProvider(SwapArgs(pair: swapPair)).future);
        if (orderState.rate?.rate == null ||
            orderState.order?.depositAmount == null ||
            orderState.order?.settleAmount == null) {
          throw StateError('Incomplete swap order state');
        }

        final depositAmount = orderState.order?.depositAmount ?? Decimal.zero;
        final settleAmount = orderState.order?.settleAmount ?? Decimal.zero;

        switch (swapServiceSource) {
          case SwapServiceSource.sideshift:
            // Sideshift: Fixed 1% service fee, network fee is the remainder
            final serviceFee = depositAmount * DecimalExt.fromDouble(0.01);
            final totalFees = depositAmount - settleAmount;
            final networkFees = totalFees - serviceFee;

            return FeeStructure.usdtSwap(
              serviceFee: serviceFee.truncate(scale: 2).toDouble(),
              serviceFeePercentage: 1.0,
              networkFee: networkFees.truncate(scale: 2).toDouble(),
              totalFees: totalFees.truncate(scale: 2).toDouble(),
            );

          case SwapServiceSource.changelly:
            // Changelly: Network fees provided in response, service fee is the remainder. Service fee percentage is calculated from total fees
            //TODO: Network fee is not being substracted from settleAmount for Changelly. Need to revise. For now set to 0.
            final networkFees = Decimal.zero;
            // final settleCoinNetworkFee = orderState.order?.settleCoinNetworkFee;
            // final depositCoinNetworkFee = orderState.order?.depositCoinNetworkFee ?? Decimal.zero;
            // final networkFees = (settleCoinNetworkFee ?? Decimal.zero) +
            //     depositCoinNetworkFee;

            final totalFees = depositAmount - settleAmount;
            final serviceFee = totalFees - networkFees;
            final serviceFeePercentage =
                (serviceFee / depositAmount).toDouble() * 100;

            return FeeStructure.usdtSwap(
              serviceFee: serviceFee.truncate(scale: 2).toDouble(),
              serviceFeePercentage:
                  double.parse(serviceFeePercentage.toStringAsFixed(2)),
              networkFee: networkFees.truncate(scale: 2).toDouble(),
              totalFees: totalFees.truncate(scale: 2).toDouble(),
            );
        }
      },
    );
  }
}
