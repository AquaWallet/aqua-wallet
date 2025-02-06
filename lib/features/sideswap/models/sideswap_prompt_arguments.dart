import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'sideswap_prompt_arguments.freezed.dart';

@freezed
class SideSwapPromptArguments with _$SideSwapPromptArguments {
  const factory SideSwapPromptArguments({
    required String orderId,
    required String sendAsset,
    required int sendAmount,
    required String recvAsset,
    required int recvAmount,
    required String uploadUrl,
  }) = _SideSwapPromptArguments;
}
