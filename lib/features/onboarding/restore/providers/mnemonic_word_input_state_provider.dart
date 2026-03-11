import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';

final mnemonicKeyboardCapsLockStatusProvider = StateProvider((_) => false);

final mnemonicWordInputStateProvider = StateNotifierProvider.family
    .autoDispose<_MnemonicStateNotifier, MnemonicWordInputState, int>((ref, _) {
  return _MnemonicStateNotifier(ref);
});

class _MnemonicStateNotifier extends StateNotifier<MnemonicWordInputState> {
  _MnemonicStateNotifier(this.ref) : super(MnemonicWordInputState.empty());

  final Ref ref;

  void update({
    required String text,
    bool isSuggestion = false,
  }) {
    final capsLockEnabled = ref.read(mnemonicKeyboardCapsLockStatusProvider);
    state = MnemonicWordInputState.value(
      text: isSuggestion && capsLockEnabled ? text.toUpperCase() : text,
      isSuggestion: isSuggestion,
    );
  }

  void clear() {
    state = MnemonicWordInputState.empty();
  }

  void onKeyPressed(MnemonicKeyboardKey key) {
    final capsLockEnabled = ref.read(mnemonicKeyboardCapsLockStatusProvider);
    key.when(
      letter: (text) {
        final char = capsLockEnabled ? text.toUpperCase() : text;
        // Always set isSuggestion to false when typing manually
        state = state.copyWith(
          text: state.text + char,
          isSuggestion: false,
        );
      },
      backspace: () {
        // Always set isSuggestion to false when deleting manually
        state = state.copyWith(
          text: state.text.isNotEmpty
              ? state.text.substring(0, state.text.length - 1)
              : state.text,
          isSuggestion: false,
        );
      },
      capsLock: () {
        ref.read(mnemonicKeyboardCapsLockStatusProvider.notifier).state =
            !capsLockEnabled;
      },
    );
  }
}
