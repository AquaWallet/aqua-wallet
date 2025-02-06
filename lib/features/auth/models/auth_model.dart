import 'package:aqua/features/pin/pin_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'auth_model.freezed.dart';

@freezed
class AuthDepsData with _$AuthDepsData {
  const factory AuthDepsData({
    required PinAuthState pinState,
    required bool canAuthenticateWithBiometric,
  }) = _AuthDepsData;
}
