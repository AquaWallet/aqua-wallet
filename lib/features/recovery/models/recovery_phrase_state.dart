import 'package:freezed_annotation/freezed_annotation.dart';

part 'recovery_phrase_state.freezed.dart';

@freezed
class RecoveryPhraseRequestState with _$RecoveryPhraseRequestState {
  factory RecoveryPhraseRequestState.verificationFailed() = _VerificationFailed;
  factory RecoveryPhraseRequestState.authorized() = _Authorized;
}
