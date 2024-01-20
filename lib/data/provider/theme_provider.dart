import 'package:aqua/config/config.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final darkThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((_, context) {
  return AppStyle.createDarkThemeData(context);
});

final lightThemeProvider =
    Provider.autoDispose.family<ThemeData, BuildContext>((_, context) {
  return AppStyle.createLightThemeData(context);
});
