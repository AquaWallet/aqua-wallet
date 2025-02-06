import 'package:freezed_annotation/freezed_annotation.dart';

part 'fee_structure_model.freezed.dart';

@freezed
class FeeStructure with _$FeeStructure {
  const factory FeeStructure.bitcoinSend({
    required int feeRate,
    required int estimatedFee,
  }) = BitcoinSendFee;

  const factory FeeStructure.liquidSend({
    required int feeRate,
    required int estimatedFee,
  }) = LiquidSendFee;

  const factory FeeStructure.liquidTaxiSend({
    required int lbtcFeeRate,
    required int estimatedLbtcFee,
    required double usdtFeeRate,
    required double estimatedUsdtFee,
  }) = LiquidTaxiSendFee;

  const factory FeeStructure.sideswapInstantSwap({
    required double feeRate,
    required int estimatedFee,
    required double swapFeePercentage,
  }) = SideswapInstantSwapFee;

  const factory FeeStructure.sideswapPegIn({
    required int btcFeeRate,
    required int estimatedBtcFee,
    required double lbtcFeeRate,
    required int estimatedLbtcFee,
    required double swapFeePercentage,
  }) = SideswapPegInFee;

  const factory FeeStructure.sideswapPegOut({
    required double lbtcFeeRate,
    required int estimatedLbtcFee,
    required int btcFeeRate,
    required int estimatedBtcFee,
    required double swapFeePercentage,
  }) = SideswapPegOutFee;

  const factory FeeStructure.boltzReceive({
    required int lightningFeeRate,
    required int estimatedLightningFee,
    required double swapFeePercentage,
  }) = BoltzReceiveFee;

  const factory FeeStructure.boltzSend({
    required int onchainFeeRate,
    required int estimatedOnchainFee,
    required double swapFeePercentage,
  }) = BoltzSendFee;

  const factory FeeStructure.usdtSwap({
    required double serviceFee,
    required double serviceFeePercentage,
    required double networkFee,
    required double totalFees,
  }) = USDtSwapFee;
}
