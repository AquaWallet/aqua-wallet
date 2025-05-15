import 'package:aqua/features/account/account.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class Jan3AuthState with _$Jan3AuthState {
  const factory Jan3AuthState.authenticated({
    required ProfileResponse profile,
    @Default(false) bool pendingCardCreation,
  }) = Jan3UserAuthenticated;
  const factory Jan3AuthState.pendingOtpVerification() =
      Jan3UserPendingOtpVerification;
  const factory Jan3AuthState.unauthenticated() = Jan3UserUnauthenticated;
}

extension Jan3AuthStateX on Jan3AuthState {
  bool get isAuthenticated => when(
        authenticated: (_, __) => true,
        pendingOtpVerification: () => false,
        unauthenticated: () => false,
      );
}
