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
      statusBarColor: theme.colorScheme.background,
      navBarColor: theme.colorScheme.surface,
    );
  }

  void forceLight() {
    final theme = ref.read(lightThemeProvider(context));

    _change(
      brightness: Brightness.dark,
      statusBarColor: theme.colorScheme.background,
    );
  }

  void forceDark() {
    final theme = ref.read(darkThemeProvider(context));

    _change(
      brightness: Brightness.light,
      statusBarColor: theme.colorScheme.background,
    );
  }

  void aqua({bool aquaColorNav = false}) {
    _change(
      brightness: Brightness.light,
      statusBarColor: AquaColors.backgroundGradientStartColor,
      navBarColor: aquaColorNav
          ? AquaColors.backgroundGradientEndColor
          : ref.read(lightThemeProvider(context)).colorScheme.background,
    );
  }

  void transparent() {
    _change(
      brightness: Brightness.light,
      statusBarColor: Colors.transparent,
    );
  }

  void _change({
    required Brightness brightness,
    required Color statusBarColor,
    Color? navBarColor,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: brightness,
        statusBarColor: statusBarColor,
        systemNavigationBarColor: navBarColor,
      ),
    );
  }
}
