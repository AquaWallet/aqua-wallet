import 'package:freezed_annotation/freezed_annotation.dart';

part 'mnemonic_keyboard_key.freezed.dart';

@freezed
class MnemonicKeyboardKey with _$MnemonicKeyboardKey {
  const factory MnemonicKeyboardKey.letter({
    @Default('') String text,
  }) = _MnemonicKeyboardLetterKey;

  factory MnemonicKeyboardKey.backspace() = _MnemonicKeyboardBackspaceKey;

  factory MnemonicKeyboardKey.capsLock() = _MnemonicKeyboardCapsLockKey;

  factory MnemonicKeyboardKey.fromRawValue(String value) {
    if (value.toLowerCase() == 'backspace') {
      return MnemonicKeyboardKey.backspace();
    } else {
      return MnemonicKeyboardKey.letter(text: value);
    }
  }
}

extension MnemonicKeyboardKeyExt on MnemonicKeyboardKey {
  bool get isBackspaceKey => this is _MnemonicKeyboardBackspaceKey;

  bool get isSpecialKey =>
      isBackspaceKey || this is _MnemonicKeyboardCapsLockKey;
}

extension MnemonicKeyboardKeysExt on List<MnemonicKeyboardKey> {
  bool get containsSpecialKeys => any((e) => e.isSpecialKey);
}

extension MnemonicKeyboardLetterExt on List<String> {
  List<MnemonicKeyboardKey> toMnemonicKeyboardKeys({
    required bool capitalized,
    bool withSpecialKeys = false,
  }) {
    return [
      if (withSpecialKeys) ...{
        MnemonicKeyboardKey.capsLock(),
      },
      ...map((char) {
        return MnemonicKeyboardKey.letter(
          text: capitalized ? char.toUpperCase() : char,
        );
      }),
      if (withSpecialKeys) ...{
        MnemonicKeyboardKey.backspace(),
      },
    ];
  }
}
