import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/shared/shared.dart';

final recoveryPhraseRequestProvider = StateNotifierProvider.autoDispose<
    RecoveryPhraseRequestNotifier, RecoveryPhraseRequestState?>((ref) {
  return RecoveryPhraseRequestNotifier();
});

class RecoveryPhraseRequestNotifier
    extends StateNotifier<RecoveryPhraseRequestState?> {
  RecoveryPhraseRequestNotifier() : super(null);

  Future<void> requestRecoveryPhrase() async {
    state = RecoveryPhraseRequestState.authorized();
  }
}
