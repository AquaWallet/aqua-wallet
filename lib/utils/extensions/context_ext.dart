import 'dart:io';

import 'package:aqua/config/config.dart' hide AquaColors;
import 'package:aqua/features/shared/shared.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:ui_components/ui_components.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}

extension ThemeContextExt on BuildContext {
  @Deprecated('Use ui_components instead')
  AppColors get colors => Theme.of(this).colors;

  AquaColors get aquaColors =>
      Theme.of(this).isLight ? AquaColors.lightColors : AquaColors.darkColors;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;
}

extension ContextExt on BuildContext {
  Future<void> copyToClipboard(
    String value, {
    String? successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: value));

    // Android 13+ shows its own system notification, so skip our snackbar
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return;
      }
    }

    showAquaSnackbar(message: successMessage ?? loc.copiedToClipboard);
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

  void showAquaSnackbar({
    Key? key,
    required String message,
    Color? color,
    int? durationSeconds,
  }) {
    _showSnackbar(
      key: key,
      message: message,
      color: color,
      durationSeconds: durationSeconds,
    );
  }

  void _showSnackbar({
    Key? key,
    required String message,
    Color? color,
    int? durationSeconds,
  }) {
    AquaTooltip.show(
      this,
      key: key,
      colors: aquaColors,
      message: message,
      duration:
          durationSeconds != null ? Duration(seconds: durationSeconds) : null,
    );
  }
}
