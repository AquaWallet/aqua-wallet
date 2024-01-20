import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_review_arguments.freezed.dart';

@freezed
class SendReviewArguments with _$SendReviewArguments {
  const factory SendReviewArguments({
    required Asset asset,
    required String address,
    required String amount,
  }) = _SendReviewArguments;
}
