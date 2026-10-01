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

  const factory FeeStructure.boltzSend({
    required int onchainFeeRate,
    required int estimatedOnchainFee,
    // Percent value as returned by the swap provider (0.1 = 0.1%), same as
    // sideswap fees
    required double swapFeePercentage,
  }) = BoltzSendFee;

  const factory FeeStructure.usdtSwap({
    required double serviceFee,
    required double serviceFeePercentage,
    required double receiveNetworkFee,
    required double estimatedSendNetworkFee,
    required double totalFees,
    required String totalFeesCrypto,
  }) = USDtSwapFee;
}
