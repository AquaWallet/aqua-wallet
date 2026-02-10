extension StringExtension on String {
  String removeBraces() {
    if (startsWith('{') && endsWith('}')) {
      return substring(1, length - 1);
    }
    return this;
  }

  String toEmoji() {
    return String.fromCharCode(
      int.parse(
        replaceFirst("U+", ""),
        radix: 16,
      ),
    );
  }

  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}
