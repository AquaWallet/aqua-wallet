sealed class MnemonicKeyboardKey {
  static const _backspace = 'backspace';

  const MnemonicKeyboardKey();
  factory MnemonicKeyboardKey.letter({String text}) = MnemonicKeyboardLetterKey;
  factory MnemonicKeyboardKey.backspace() = MnemonicKeyboardBackspaceKey;

  factory MnemonicKeyboardKey.fromRawValue(String value) {
    return value.toLowerCase() == _backspace
        ? MnemonicKeyboardKey.backspace()
        : MnemonicKeyboardKey.letter(text: value);
  }
}

class MnemonicKeyboardLetterKey extends MnemonicKeyboardKey {
  final String text;

  const MnemonicKeyboardLetterKey({this.text = ''});

  @override
  String toString() => 'MnemonicKeyboardLetterKey(text: $text)';
}

class MnemonicKeyboardBackspaceKey extends MnemonicKeyboardKey {
  const MnemonicKeyboardBackspaceKey();
}

extension MnemonicKeyboardKeyExt on MnemonicKeyboardKey {
  bool get isBackspaceKey => this is MnemonicKeyboardBackspaceKey;

  bool get isSpecialKey => isBackspaceKey;
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
        // TODO: add caps lock key
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
