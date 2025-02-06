import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification_request_state.freezed.dart';

@freezed
class VerificationRequestState with _$VerificationRequestState {
  factory VerificationRequestState.verificationFailed() = _VerificationFailed;
  factory VerificationRequestState.authorized() = _Authorized;
}
