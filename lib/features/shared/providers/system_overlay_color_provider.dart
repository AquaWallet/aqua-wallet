import 'package:aqua/config/config.dart' hide AquaColors;
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:ui_components/ui_components.dart' as ui_components;
import 'package:ui_components/ui_components.dart';

final systemOverlayColorProvider = Provider.autoDispose
    .family<SystemOverlayColor, BuildContext>(SystemOverlayColor.new);

class SystemOverlayColor {
  SystemOverlayColor(this.ref, this.context);

  final Ref ref;
  final BuildContext context;

  void themeBased() {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    // Note: Context.aquaColors here is delayed, we need to use this variable to get the proper theme.
    final colors = darkMode ? AquaColors.darkColors : AquaColors.lightColors;

    _change(
      brightness: darkMode ? Brightness.light : Brightness.dark,
      statusBarColor: colors.surfaceBackground,
      navBarColor: colors.surfaceBackground,
    );
  }

  void forceLight() {
    final theme = ref.read(lightThemeProvider(context));

    _change(
      brightness: Brightness.dark,
      statusBarColor: theme.colors.background,
    );
  }

  void forceDark() {
    final theme = ref.read(darkThemeProvider(context));

    _change(
      brightness: Brightness.light,
      statusBarColor: theme.colors.background,
    );
  }

  void aqua({bool aquaColorNav = false}) {
    _change(
      brightness: Brightness.light,
      statusBarColor: AquaColors.lightColors.accentBrand,
      navBarColor: aquaColorNav
          ? AquaColors.lightColors.accentBrand
          : ref.read(lightThemeProvider(context)).colors.background,
    );
  }

  void transparent() {
    _change(
      brightness: Brightness.light,
      statusBarColor: Colors.transparent,
      navBarColor: Colors.transparent,
    );
  }

  void modalColor(ui_components.AquaColors aquaColors) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    _change(
      brightness: darkMode ? Brightness.light : Brightness.dark,
      statusBarColor: aquaColors.surfacePrimary,
      navBarColor: aquaColors.surfacePrimary,
    );
  }

  void custom({
    required Color statusBarColor,
    Color? navBarColor,
    Brightness? brightness,
  }) {
    _change(
      brightness: brightness ?? Brightness.light,
      statusBarColor: statusBarColor,
      navBarColor: navBarColor ?? statusBarColor,
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
        systemNavigationBarIconBrightness: brightness,
        systemStatusBarContrastEnforced: false,
      ),
    );
  }
}
