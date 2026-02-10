import 'package:flutter/material.dart';
import 'package:ui_components/config/colors.dart';

abstract class AquaColors {
  // Base Colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textInverse;
  Color get surfacePrimary;
  Color get surfaceBorderPrimary;
  Color get surfaceSecondary;
  Color get surfaceBorderSecondary;
  Color get surfaceTertiary;
  Color get surfaceInverse;
  Color get surfaceBackground;
  Color get surfaceSelected;
  Color get surfaceBorderSelected;
  Color get glassSurface;
  Color get glassInverse;
  Color get glassBackground;
  Color get accentBrand;
  Color get accentBrandTransparent;
  Color get accentSuccess;
  Color get accentSuccessTransparent;
  Color get accentWarning;
  Color get accentWarningTransparent;
  Color get accentDanger;
  Color get accentDangerTransparent;

  // Custom Colors
  Color get chipSuccessBackgroundColor;
  Color get chipErrorBackgroundColor;
  Color get chipSuccessForegroundColor;
  Color get chipErrorForegroundColor;

  static AquaColors lightColors = LightColors();
  static AquaColors darkColors = DarkColors();
  static AquaColors deepOceanColors = DeepOceanColors();

  static LinearGradient gradient = LinearGradient(
    begin: const Alignment(1, 0),
    end: const Alignment(0, 1),
    colors: [lightColors.accentBrand, AquaPrimitiveColors.aquaBlue300],
  );
}

class LightColors implements AquaColors {
  @override
  Color get textPrimary => AquaPrimitiveColors.gray1000;
  @override
  Color get textSecondary => AquaPrimitiveColors.gray700;
  @override
  Color get textTertiary => AquaPrimitiveColors.gray500;
  @override
  Color get textInverse => AquaPrimitiveColors.white;

  @override
  Color get surfacePrimary => AquaPrimitiveColors.white;
  @override
  Color get surfaceBorderPrimary => AquaPrimitiveColors.gray50;
  @override
  Color get surfaceSecondary => AquaPrimitiveColors.gray50;
  @override
  Color get surfaceBorderSecondary => AquaPrimitiveColors.gray100;
  @override
  Color get surfaceTertiary => AquaPrimitiveColors.gray200;
  @override
  Color get surfaceInverse => AquaPrimitiveColors.gray900;
  @override
  Color get surfaceBackground => AquaPrimitiveColors.gray50;
  @override
  Color get surfaceSelected => AquaPrimitiveColors.aquaBlue4;
  @override
  Color get surfaceBorderSelected => AquaPrimitiveColors.aquaBlue100;

  @override
  Color get glassSurface => const Color(0x80FFFFFF);
  @override
  Color get glassInverse => const Color(0xD9000000);
  @override
  Color get glassBackground => const Color(0x4DF6F7F8);

  @override
  Color get accentBrand => AquaPrimitiveColors.aquaBlue500;
  @override
  Color get accentBrandTransparent => AquaPrimitiveColors.aquaBlue16;
  @override
  Color get accentSuccess => AquaPrimitiveColors.aquaGreen600;
  @override
  Color get accentSuccessTransparent => AquaPrimitiveColors.aquaGreen16;
  @override
  Color get accentWarning => AquaPrimitiveColors.amber;
  @override
  Color get accentWarningTransparent => AquaPrimitiveColors.amber4;
  @override
  Color get accentDanger => AquaPrimitiveColors.vermillion500;
  @override
  Color get accentDangerTransparent => AquaPrimitiveColors.vermillion16;

  // Custom Colors

  @override
  Color get chipSuccessBackgroundColor => accentSuccessTransparent;
  @override
  Color get chipErrorBackgroundColor => accentDangerTransparent;
  @override
  Color get chipSuccessForegroundColor => accentSuccess;
  @override
  Color get chipErrorForegroundColor => accentDanger;
}

class DarkColors implements AquaColors {
  @override
  Color get textPrimary => AquaPrimitiveColors.gray50;
  @override
  Color get textSecondary => AquaPrimitiveColors.gray300;
  @override
  Color get textTertiary => AquaPrimitiveColors.gray500;
  @override
  Color get textInverse => AquaPrimitiveColors.black;

  @override
  Color get surfacePrimary => AquaPrimitiveColors.gray850;
  @override
  Color get surfaceBorderPrimary => AquaPrimitiveColors.gray800;
  @override
  Color get surfaceSecondary => AquaPrimitiveColors.gray800;
  @override
  Color get surfaceBorderSecondary => AquaPrimitiveColors.gray750;
  @override
  Color get surfaceTertiary => AquaPrimitiveColors.gray750;
  @override
  Color get surfaceInverse => AquaPrimitiveColors.gray50;
  @override
  Color get surfaceBackground => AquaPrimitiveColors.gray1000;
  @override
  Color get surfaceSelected => AquaPrimitiveColors.aquaGreen16;
  @override
  Color get surfaceBorderSelected => AquaPrimitiveColors.aquaBlue800;

  @override
  Color get glassSurface => const Color(0x80172026);
  @override
  Color get glassInverse => const Color(0xD9FFFFFF);
  @override
  Color get glassBackground => const Color(0x4D080D11);

  @override
  Color get accentBrand => AquaPrimitiveColors.aquaBlue300;
  @override
  Color get accentBrandTransparent => AquaPrimitiveColors.aquaGreen16;
  @override
  Color get accentSuccess => AquaPrimitiveColors.aquaGreen400;
  @override
  Color get accentSuccessTransparent => AquaPrimitiveColors.aquaGreen16;
  @override
  Color get accentWarning => AquaPrimitiveColors.amber400;
  @override
  Color get accentWarningTransparent => AquaPrimitiveColors.amber16;
  @override
  Color get accentDanger => AquaPrimitiveColors.vermillion400;
  @override
  Color get accentDangerTransparent => AquaPrimitiveColors.vermillion16;

  // Custom Colors

  @override
  Color get chipSuccessBackgroundColor => accentSuccessTransparent;
  @override
  Color get chipErrorBackgroundColor => accentDangerTransparent;
  @override
  Color get chipSuccessForegroundColor => accentSuccess;
  @override
  Color get chipErrorForegroundColor => accentDanger;
}

class DeepOceanColors implements AquaColors {
  @override
  Color get textPrimary => AquaPrimitiveColors.glaucous50;
  @override
  Color get textSecondary => AquaPrimitiveColors.glaucous300;
  @override
  Color get textTertiary => AquaPrimitiveColors.glaucous500;
  @override
  Color get textInverse => AquaPrimitiveColors.black;

  @override
  Color get surfacePrimary => AquaPrimitiveColors.glaucous850;
  @override
  Color get surfaceBorderPrimary => AquaPrimitiveColors.glaucous800;
  @override
  Color get surfaceSecondary => AquaPrimitiveColors.glaucous800;
  @override
  Color get surfaceBorderSecondary => AquaPrimitiveColors.glaucous750;
  @override
  Color get surfaceTertiary => AquaPrimitiveColors.glaucous750;
  @override
  Color get surfaceInverse => AquaPrimitiveColors.glaucous50;
  @override
  Color get surfaceBackground => AquaPrimitiveColors.glaucous950;
  @override
  Color get surfaceSelected => AquaPrimitiveColors.aquaGreen16;
  @override
  Color get surfaceBorderSelected => AquaPrimitiveColors.aquaBlue800;

  @override
  Color get glassSurface => const Color(0x8021293B);
  @override
  Color get glassInverse => const Color(0xD9FFFFFF);
  @override
  Color get glassBackground => const Color(0x4D131927);

  @override
  Color get accentBrand => AquaPrimitiveColors.aquaBlue300;
  @override
  Color get accentBrandTransparent => AquaPrimitiveColors.aquaGreen16;
  @override
  Color get accentSuccess => AquaPrimitiveColors.aquaGreen400;
  @override
  Color get accentSuccessTransparent => AquaPrimitiveColors.aquaGreen16;
  @override
  Color get accentWarning => AquaPrimitiveColors.amber400;
  @override
  Color get accentWarningTransparent => AquaPrimitiveColors.amber16;
  @override
  Color get accentDanger => AquaPrimitiveColors.vermillion400;
  @override
  Color get accentDangerTransparent => AquaPrimitiveColors.vermillion16;

  // Custom Colors

  @override
  Color get chipSuccessBackgroundColor => surfacePrimary;
  @override
  Color get chipErrorBackgroundColor => surfacePrimary;
  @override
  Color get chipSuccessForegroundColor => accentSuccess;
  @override
  Color get chipErrorForegroundColor => accentDanger;
}

extension AquaColorsX on AquaColors {
  Color get systemBackgroundColor => const Color(0xFFD0D5DC);
}
