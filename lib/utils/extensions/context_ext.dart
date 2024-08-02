import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}

extension ThemeContextExt on BuildContext {
  AppColors get colors => Theme.of(this).colors;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;
}

extension ContextExt on BuildContext {
  Future<void> copyToClipboard(String value) async {
    final text = AppLocalizations.of(this)!.copiedToClipboard;
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    showAquaSnackbar(text);
    await Clipboard.setData(ClipboardData(text: value));
  }

  Future<String?> checkClipboardContent() async {
    ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    return clipboardData?.text;
  }

  void showErrorSnackbar(String message) {
    _showSnackbar(message: message, color: Theme.of(this).colorScheme.error);
  }

  void showSuccessSnackbar(String message) {
    _showSnackbar(message: message, color: Colors.green);
  }

  void showAquaSnackbar(String message) {
    _showSnackbar(
      message: message,
      color: Theme.of(this).colorScheme.primary,
    );
  }

  void _showSnackbar({
    required String message,
    required Color color,
    int? durationSeconds,
  }) {
    final snackBar = SnackBar(
      backgroundColor: color,
      duration: Duration(seconds: durationSeconds ?? 4),
      content: Text(message),
    );

    ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }
}
