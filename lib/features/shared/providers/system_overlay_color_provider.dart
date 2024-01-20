import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';

final systemOverlayColorProvider = Provider.autoDispose
    .family<SystemOverlayColor, BuildContext>(SystemOverlayColor.new);

class SystemOverlayColor {
  SystemOverlayColor(this.ref, this.context);

  final Ref ref;
  final BuildContext context;

  void themeBased() {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final theme = darkMode
        ? ref.read(darkThemeProvider(context))
        : ref.read(lightThemeProvider(context));

    _change(
      brightness: darkMode ? Brightness.light : Brightness.dark,
      color: theme.colorScheme.background,
    );
  }

  void forceLight() {
    final theme = ref.read(lightThemeProvider(context));

    _change(
      brightness: Brightness.dark,
      color: theme.colorScheme.background,
    );
  }

  void forceDark() {
    final theme = ref.read(darkThemeProvider(context));

    _change(
      brightness: Brightness.light,
      color: theme.colorScheme.background,
    );
  }

  void aqua() {
    _change(
      brightness: Brightness.light,
      color: AquaColors.backgroundGradientStartColor,
    );
  }

  void transparent() {
    _change(
      brightness: Brightness.light,
      color: Colors.transparent,
    );
  }

  void _change({
    required Brightness brightness,
    required Color color,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: brightness,
        statusBarColor: color,
      ),
    );
  }
}
