import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_prompt_arguments.freezed.dart';

@freezed
class SendPromptArguments with _$SendPromptArguments {
  const factory SendPromptArguments({
    required String id,
    required Asset asset,
  }) = _SendPromptArguments;
}
