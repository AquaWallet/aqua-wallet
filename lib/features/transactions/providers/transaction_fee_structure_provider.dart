import 'dart:async';

import 'package:coin_cz/common/decimal/decimal_ext.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideshift/models/sideshift_fees.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
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
            // Sideshift: Fixed 0.9% service fee, network fee is the remainder
            final serviceFee = depositAmount *
                DecimalExt.fromDouble(kSideshiftServiceFee, precision: 3);
            final totalFees = depositAmount - settleAmount;
            final networkFees = totalFees - serviceFee;

            return FeeStructure.usdtSwap(
              serviceFee: serviceFee.truncate(scale: 2).toDouble(),
              serviceFeePercentage: kSideshiftServiceFee * 100,
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
