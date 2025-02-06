import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

final verificationRequestProvider = StateNotifierProvider.autoDispose<
    VerificationRequestNotifier,
    VerificationRequestState?>(VerificationRequestNotifier.new);

class VerificationRequestNotifier
    extends StateNotifier<VerificationRequestState?> {
  VerificationRequestNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<void> requestVerification({String? message}) async {
    final biometricAuth = await _ref.read(biometricAuthProvider.future);
    final pinEnabled =
        _ref.read(pinAuthProvider).asData?.value != PinAuthState.disabled;

    if (biometricAuth.enabled) {
      final reason =
          message ?? _ref.read(appLocalizationsProvider).authenticationMessage;
      final authenticated = await _ref
          .read(biometricAuthProvider.notifier)
          .authenticate(reason: reason);

      state = authenticated
          ? VerificationRequestState.authorized()
          : VerificationRequestState.verificationFailed();
    } else if (pinEnabled) {
      final success = await _ref.read(routerProvider).push(
          CheckPinScreen.routeName,
          extra: CheckPinScreenArguments(
              onSuccessAction: CheckAction.pull, canCancel: true)) as bool?;
      state = success == true
          ? VerificationRequestState.authorized()
          : VerificationRequestState.verificationFailed();
    } else {
      state = VerificationRequestState.authorized();
    }
  }
}
