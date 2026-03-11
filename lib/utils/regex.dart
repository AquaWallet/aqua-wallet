class AquaRegex {
  static final digitsOnly = RegExp(r'^\d*');

  static final decimalNumbers = RegExp(r'^\d*(\.|\,)?\d*');
  static final firstDecimal = RegExp(r'(?:\d+(?:[.,]\d+)?)');

  /// Matches descriptor checksum at the end (e.g., `#0dsvq5mw`)
  static final descriptorChecksum = RegExp(r'#[a-z0-9]+$');

  /// Matches receive-only derivation path `/0/*`
  static final receiveOnlyDerivationPath = RegExp(r'/0/\*');
}
