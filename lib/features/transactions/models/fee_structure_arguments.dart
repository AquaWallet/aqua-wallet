import 'package:coin_cz/features/send/send.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fee_structure_arguments.freezed.dart';

@freezed
class FeeStructureArguments with _$FeeStructureArguments {
  const factory FeeStructureArguments.aquaSend({
    SendAssetArguments? sendAssetArgs,
  }) = _AquaSendFeeStructureArguments;

  const factory FeeStructureArguments.usdtSwap({
    required SendAssetArguments sendAssetArgs,
  }) = _USDtSwapFeeStructureArguments;

  const factory FeeStructureArguments.sideswap() =
      _SideswapFeeStructureArguments;
}
