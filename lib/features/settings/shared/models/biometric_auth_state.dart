import 'package:freezed_annotation/freezed_annotation.dart';

part 'biometric_auth_state.freezed.dart';
part 'biometric_auth_state.g.dart';

@freezed
class BiometricAuthState with _$BiometricAuthState {
  factory BiometricAuthState({
    @JsonKey(name: 'is_device_supported')
    @Default(false)
    bool isDeviceSupported,
    @JsonKey(name: 'available') @Default(false) bool available,
    @JsonKey(name: 'enabled') @Default(false) bool enabled,
  }) = _BiometricAuthState;

  factory BiometricAuthState.fromJson(Map<String, dynamic> json) =>
      _$BiometricAuthStateFromJson(json);
}
