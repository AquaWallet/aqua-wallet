import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

extension TextEditingControllerX on TextEditingController {
  // Works as a bridge between the numpad and the amount controller
  void addKey(
    MnemonicKeyboardKey key, {
    String decimalSeparator = MnemonicKeyboardKey.kDecimalCharacter,
    int? precision,
  }) {
    if (key.isBackspaceKey) {
      if (text.isNotEmpty) {
        text = text.substring(0, text.length - 1);
      }
    } else if (key is MnemonicKeyboardLetterKey) {
      if (key.text == decimalSeparator) {
        if (!text.contains(decimalSeparator)) {
          // If text is empty or just whitespace, prepend "0"
          text = normalizeDecimalStart('$text$decimalSeparator');
        }
      } else {
        if (text == '0' && key.text == '0') return;

        // Check precision limit before adding digit
        final newText = text + key.text;
        if (precision != null && newText.contains(decimalSeparator)) {
          // Find the decimal separator position
          final decimalIndex = newText.lastIndexOf(decimalSeparator);

          // Extract decimal part (everything after the decimal separator)
          final decimalPart = newText.substring(decimalIndex + 1);
          final decimalPlaces = decimalPart.length;

          if (decimalPlaces > precision) {
            // Don't add the digit if it exceeds precision
            return;
          }
        }

        text += key.text;
      }
    }
    debugPrint('[Numpad] Amount: $text');
  }
}
