extension StringExtension on String? {
  bool get isValidUrl =>
      this != null && (Uri.tryParse(this!)?.isAbsolute ?? false);
}
