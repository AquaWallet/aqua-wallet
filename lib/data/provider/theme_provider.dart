import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final darkThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((ref, context) {
  final isBotevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
  return isBotevMode
      ? ref.read(botevThemeProvider(context))
      : AppStyle.createDarkThemeData(context);
});

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
