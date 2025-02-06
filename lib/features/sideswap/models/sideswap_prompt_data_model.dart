import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideswap_prompt_data_model.freezed.dart';

@freezed
class SideSwapPromptDataModel with _$SideSwapPromptDataModel {
  const factory SideSwapPromptDataModel({
    required Asset sendAsset,
    required int sendAmount,
    required Asset recvAsset,
    required int recvAmount,
  }) = _SideSwapPromptDataModel;
}
