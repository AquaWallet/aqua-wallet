import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

abstract class AquaTheme {
  ThemeData get themeData;
  ColorScheme get colorScheme;
}

class AquaLightTheme extends AquaTheme {
  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: false,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AquaColors.lightColors.surfaceBackground,
      );

  @override
  ColorScheme get colorScheme => ColorScheme.light(
        primary: AquaColors.lightColors.accentBrand,
        onPrimary: AquaColors.lightColors.textInverse,
        primaryContainer: AquaColors.lightColors.accentBrand,
        onPrimaryContainer: AquaColors.lightColors.textInverse,
        secondary: AquaColors.lightColors.surfaceInverse,
        onSecondary: AquaColors.lightColors.textInverse,
        secondaryContainer: AquaColors.lightColors.surfaceInverse,
        onSecondaryContainer: AquaColors.lightColors.textInverse,
        tertiary: AquaColors.lightColors.surfaceInverse,
        onTertiary: AquaColors.lightColors.textInverse,
        tertiaryContainer: AquaColors.lightColors.surfaceInverse,
        onTertiaryContainer: AquaColors.lightColors.textInverse,
        error: AquaColors.lightColors.accentDanger,
        onError: AquaColors.lightColors.textInverse,
        errorContainer: AquaColors.lightColors.accentDanger,
        onErrorContainer: AquaColors.lightColors.textInverse,
        surface: AquaColors.lightColors.surfacePrimary,
        onSurface: AquaColors.lightColors.textPrimary,
        onSurfaceVariant: AquaColors.lightColors.textPrimary,
        surfaceContainerHighest: AquaColors.lightColors.surfaceTertiary,
        surfaceContainerHigh: AquaColors.lightColors.surfaceSecondary,
        surfaceContainer: AquaColors.lightColors.surfacePrimary,
        surfaceContainerLow: AquaColors.lightColors.surfaceBackground,
        surfaceContainerLowest: AquaColors.lightColors.surfaceBackground,
        inverseSurface: AquaColors.lightColors.surfaceInverse,
        onInverseSurface: AquaColors.lightColors.textInverse,
        surfaceTint: AquaColors.lightColors.accentBrand,
        outline: AquaColors.lightColors.surfaceBorderPrimary,
        outlineVariant: AquaColors.lightColors.surfaceBorderSecondary,
      );
}

class AquaDarkTheme extends AquaTheme {
  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: false,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AquaColors.darkColors.surfaceBackground,
      );

  @override
  ColorScheme get colorScheme => ColorScheme.dark(
        primary: AquaColors.darkColors.accentBrand,
        onPrimary: AquaColors.darkColors.textInverse,
        primaryContainer: AquaColors.darkColors.accentBrand,
        onPrimaryContainer: AquaColors.darkColors.textInverse,
        secondary: AquaColors.darkColors.surfaceInverse,
        onSecondary: AquaColors.darkColors.textInverse,
        secondaryContainer: AquaColors.darkColors.surfaceInverse,
        onSecondaryContainer: AquaColors.darkColors.textInverse,
        tertiary: AquaColors.darkColors.surfaceInverse,
        onTertiary: AquaColors.darkColors.textInverse,
        tertiaryContainer: AquaColors.darkColors.surfaceInverse,
        onTertiaryContainer: AquaColors.darkColors.textInverse,
        error: AquaColors.darkColors.accentDanger,
        onError: AquaColors.darkColors.textInverse,
        errorContainer: AquaColors.darkColors.accentDanger,
        onErrorContainer: AquaColors.darkColors.textInverse,
        surface: AquaColors.darkColors.surfacePrimary,
        onSurface: AquaColors.darkColors.textPrimary,
        onSurfaceVariant: AquaColors.darkColors.textPrimary,
        surfaceContainerHighest: AquaColors.darkColors.surfaceTertiary,
        surfaceContainerHigh: AquaColors.darkColors.surfaceSecondary,
        surfaceContainer: AquaColors.darkColors.surfacePrimary,
        surfaceContainerLow: AquaColors.darkColors.surfaceBackground,
        surfaceContainerLowest: AquaColors.darkColors.surfaceBackground,
        inverseSurface: AquaColors.darkColors.surfaceInverse,
        onInverseSurface: AquaColors.darkColors.textInverse,
        surfaceTint: AquaColors.darkColors.accentBrand,
        outline: AquaColors.darkColors.surfaceBorderPrimary,
        outlineVariant: AquaColors.darkColors.surfaceBorderSecondary,
      );
}

class AquaDeepOceanTheme extends AquaTheme {
  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: false,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AquaColors.deepOceanColors.surfaceBackground,
      );

  @override
  ColorScheme get colorScheme => ColorScheme.dark(
        primary: AquaColors.deepOceanColors.accentBrand,
        onPrimary: AquaColors.deepOceanColors.textInverse,
        primaryContainer: AquaColors.deepOceanColors.accentBrand,
        onPrimaryContainer: AquaColors.deepOceanColors.textInverse,
        secondary: AquaColors.deepOceanColors.surfaceInverse,
        onSecondary: AquaColors.deepOceanColors.textInverse,
        secondaryContainer: AquaColors.deepOceanColors.surfaceInverse,
        onSecondaryContainer: AquaColors.deepOceanColors.textInverse,
        tertiary: AquaColors.deepOceanColors.surfaceInverse,
        onTertiary: AquaColors.deepOceanColors.textInverse,
        tertiaryContainer: AquaColors.deepOceanColors.surfaceInverse,
        onTertiaryContainer: AquaColors.deepOceanColors.textInverse,
        error: AquaColors.deepOceanColors.accentDanger,
        onError: AquaColors.deepOceanColors.textInverse,
        errorContainer: AquaColors.deepOceanColors.accentDanger,
        onErrorContainer: AquaColors.deepOceanColors.textInverse,
        surface: AquaColors.deepOceanColors.surfacePrimary,
        onSurface: AquaColors.deepOceanColors.textPrimary,
        onSurfaceVariant: AquaColors.deepOceanColors.textPrimary,
        surfaceContainerHighest: AquaColors.deepOceanColors.surfaceTertiary,
        surfaceContainerHigh: AquaColors.deepOceanColors.surfaceSecondary,
        surfaceContainer: AquaColors.deepOceanColors.surfacePrimary,
        surfaceContainerLow: AquaColors.deepOceanColors.surfaceBackground,
        surfaceContainerLowest: AquaColors.deepOceanColors.surfaceBackground,
        inverseSurface: AquaColors.deepOceanColors.surfaceInverse,
        onInverseSurface: AquaColors.deepOceanColors.textInverse,
        surfaceTint: AquaColors.deepOceanColors.accentBrand,
        outline: AquaColors.deepOceanColors.surfaceBorderPrimary,
        outlineVariant: AquaColors.deepOceanColors.surfaceBorderSecondary,
      );
}
