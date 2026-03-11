import 'package:flutter/material.dart';
import 'package:ui_components/config/theme_colors.dart';

extension ColorSchemeX on ColorScheme {
  Color get warning => brightness == Brightness.dark
      ? AquaColors.darkColors.accentWarning
      : AquaColors.lightColors.accentWarning;
}
