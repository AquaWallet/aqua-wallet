import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';

final _lightTheme = AquaLightTheme();
final _darkTheme = AquaDarkTheme();
// final _deepOceanTheme = AquaDeepOceanTheme();

@Deprecated('Use AquaTheme from ui_components instead')
final darkThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((ref, context) {
  final isBotevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
  return isBotevMode
      ? ref.read(botevThemeProvider(context))
      : AppStyle.createDarkThemeData(context);
});

@Deprecated('Use AquaTheme from ui_components instead')
final lightThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((ref, context) {
  final isBotevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
  return isBotevMode
      ? ref.read(botevThemeProvider(context))
      : AppStyle.createLightThemeData(context);
});

final botevThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((_, context) {
  return AppStyle.createBotevThemeData(context);
});

// NOTE: We do not want to disrupt the existing designs, so we are keeping the
//old providers for now. The new themes will be explicitly applie to redesigned
//screens til we are ready to completely migrate to the new themes.
final newDarkThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((ref, context) {
  return _darkTheme.themeData;
});

final newLightThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((ref, context) {
  return _lightTheme.themeData;
});
