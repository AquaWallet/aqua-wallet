import 'package:aqua/data/models/focus_action.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';

/// Emits [FocusAction] events based on mnemonic input changes to move focus
/// to the next input field.
///
/// The rule is simple:
/// 1. When the user selects a suggestion ( `isSuggestion == true` ), the focus
///    should automatically move to the next input field — provided the next
///    field is still empty.
/// 2. If the current field is the last one **or** the next field already
///    contains text, the current focus is simply cleared.
/// 3. When a suggestion is explicitly selected, focus always moves to the next
///    field (if valid), regardless of whether longer words exist. The user has
///    made their choice by tapping the suggestion.
///
/// Focus is NOT moved when typing a complete word - only when a suggestion
/// is explicitly tapped. This allows users to continue typing or make
/// corrections without losing focus.
///
/// Suggestions are validated against the word list to ensure they are valid
/// BIP-39 words before triggering auto-focus.
final focusActionProvider =
    AutoDisposeNotifierProvider<FocusActionNotifier, FocusAction?>(
  FocusActionNotifier.new,
);

class FocusActionNotifier extends AutoDisposeNotifier<FocusAction?> {
  @override
  FocusAction? build() {
    final wordList = ref.read(walletHintWordListProvider).value ?? [];

    for (var index = 0; index < kMnemonicLength; index++) {
      ref.listen(
        mnemonicWordInputStateProvider(index),
        (prev, next) => _onInputChanged(
          index: index,
          previous: prev,
          current: next,
          wordList: wordList,
        ),
      );
    }

    return null;
  }

  void _handleValidWord(int index, String currentText, List<String> wordList) {
    // When a suggestion is explicitly selected, always move to the next field
    // if it's a valid complete word, regardless of whether longer words exist.
    // The user has made their choice by tapping the suggestion.
    if (index < kMnemonicLength - 1) {
      final nextState = ref.read(mnemonicWordInputStateProvider(index + 1));
      state = nextState.text.isEmpty ? FocusAction.next() : FocusAction.clear();
    } else {
      state = FocusAction.clear();
    }
  }

  void _onInputChanged({
    required int index,
    required MnemonicWordInputState? previous,
    required MnemonicWordInputState current,
    required List<String> wordList,
  }) {
    // Ignore if text hasn't changed or is empty.
    if (previous == current) return;

    // Only auto-focus when selecting a suggestion, not when typing manually
    if (!current.isSuggestion) return;

    // Validate suggestion against word list before handling
    if (wordList.contains(current.text.toLowerCase())) {
      _handleValidWord(index, current.text, wordList);
    }
  }
}
