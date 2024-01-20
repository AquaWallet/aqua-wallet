import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_assets_arguments.freezed.dart';

@freezed
class SendAssetsArguments with _$SendAssetsArguments {
  const factory SendAssetsArguments({
    required String address,
    Asset? asset,
    String? amount,
    String? label,
    String? message,
  }) = _SendAssetsArguments;
}
