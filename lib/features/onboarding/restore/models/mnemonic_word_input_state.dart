import 'package:freezed_annotation/freezed_annotation.dart';

part 'mnemonic_word_input_state.freezed.dart';

@freezed
class MnemonicWordInputState with _$MnemonicWordInputState {
  const factory MnemonicWordInputState.value({
    required bool isSuggestion,
    required String text,
  }) = _MnemonicWordInputState;

  factory MnemonicWordInputState.empty() => const _MnemonicWordInputState(
        isSuggestion: false,
        text: '',
      );
}
