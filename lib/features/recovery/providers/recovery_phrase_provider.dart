import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/recovery/recovery.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';

final recoveryPhraseRequestProvider = StateNotifierProvider.autoDispose<
    RecoveryPhraseRequestNotifier,
    RecoveryPhraseRequestState?>(RecoveryPhraseRequestNotifier.new);

class RecoveryPhraseRequestNotifier
    extends StateNotifier<RecoveryPhraseRequestState?> {
  RecoveryPhraseRequestNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<void> requestRecoveryPhrase() async {
    final biometricAuth = await _ref.read(biometricAuthProvider.future);

    if (biometricAuth.enabled) {
      final reason = _ref.read(appLocalizationsProvider).authenticationMessage;
      final authenticated = await _ref
          .read(biometricAuthProvider.notifier)
          .authenticate(reason: reason);

      state = authenticated
          ? RecoveryPhraseRequestState.authorized()
          : RecoveryPhraseRequestState.verificationFailed();
    } else {
      state = RecoveryPhraseRequestState.authorized();
    }
  }
}
