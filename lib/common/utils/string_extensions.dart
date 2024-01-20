extension StringExtension on String {
  String removeBraces() {
    if (startsWith('{') && endsWith('}')) {
      return substring(1, length - 1);
    }
    return this;
  }
}
