import 'package:flutter/material.dart';

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
    colors: [lightColors.accentBrand, const Color(0xFF00C7F9)],
  );
}

class LightColors implements AquaColors {
  @override
  Color get textPrimary => const Color(0xFF080D11);
  @override
  Color get textSecondary => const Color(0xFF374550);
  @override
  Color get textTertiary => const Color(0xFF697E8D);
  @override
  Color get textInverse => const Color(0xFFFFFFFF);

  @override
  Color get surfacePrimary => const Color(0xFFFFFFFF);
  @override
  Color get surfaceBorderPrimary => const Color(0xFFF6F7F8);
  @override
  Color get surfaceSecondary => const Color(0xFFF6F7F8);
  @override
  Color get surfaceBorderSecondary => const Color(0xFFE5EBF0);
  @override
  Color get surfaceTertiary => const Color(0xFFE5EBF0);
  @override
  Color get surfaceInverse => const Color(0xFF121A20);
  @override
  Color get surfaceBackground => const Color(0xFFF6F7F8);
  @override
  Color get surfaceSelected => const Color(0xFFF5FBFD);
  @override
  Color get surfaceBorderSelected => const Color(0xFFC9F4FF);

  @override
  Color get glassSurface => const Color(0x80FFFFFF);
  @override
  Color get glassInverse => const Color(0xD9000000);
  @override
  Color get glassBackground => const Color(0x4DF6F7F8);

  @override
  Color get accentBrand => const Color(0xFF009AD6);
  @override
  Color get accentBrandTransparent => const Color(0xFFD6EFF8);
  @override
  Color get accentSuccess => const Color(0xFF008F85);
  @override
  Color get accentSuccessTransparent => const Color(0xFFD6F0EF);
  @override
  Color get accentWarning => const Color(0xFFE0A800);
  @override
  Color get accentWarningTransparent => const Color(0xFFFEF4D6);
  @override
  Color get accentDanger => const Color(0xFFE92424);
  @override
  Color get accentDangerTransparent => const Color(0xFFFFDEDE);

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
  Color get textPrimary => const Color(0xFFF6F7F8);
  @override
  Color get textSecondary => const Color(0xFFB2C4D2);
  @override
  Color get textTertiary => const Color(0xFF697E8D);
  @override
  Color get textInverse => const Color(0xFF000000);

  @override
  Color get surfacePrimary => const Color(0xFF172026);
  @override
  Color get surfaceBorderPrimary => const Color(0xFF1F2B33);
  @override
  Color get surfaceSecondary => const Color(0xFF1F2B33);
  @override
  Color get surfaceBorderSecondary => const Color(0xFF2C3A43);
  @override
  Color get surfaceTertiary => const Color(0xFF2C3A43);
  @override
  Color get surfaceInverse => const Color(0xFFF6F7F8);
  @override
  Color get surfaceBackground => const Color(0xFF080D11);
  @override
  Color get surfaceSelected => const Color(0x29009AD6);
  @override
  Color get surfaceBorderSelected => const Color(0xFF085370);

  @override
  Color get glassSurface => const Color(0x80172026);
  @override
  Color get glassInverse => const Color(0xD9FFFFFF);
  @override
  Color get glassBackground => const Color(0x4D080D11);

  @override
  Color get accentBrand => const Color(0xFF01B0E7);
  @override
  Color get accentBrandTransparent => const Color(0x29009AD6);
  @override
  Color get accentSuccess => const Color(0xFF12BCB2);
  @override
  Color get accentSuccessTransparent => const Color(0x2900A398);
  @override
  Color get accentWarning => const Color(0xFFFFC20A);
  @override
  Color get accentWarningTransparent => const Color(0xF7B90029);
  @override
  Color get accentDanger => const Color(0xFFFF4747);
  @override
  Color get accentDangerTransparent => const Color(0x29FF2E2E);

  // Custom Colors

  @override
  Color get chipSuccessBackgroundColor => accentSuccess.withOpacity(0.16);
  @override
  Color get chipErrorBackgroundColor => accentDanger.withOpacity(0.16);
  @override
  Color get chipSuccessForegroundColor => accentSuccess;
  @override
  Color get chipErrorForegroundColor => accentDanger;
}

class DeepOceanColors implements AquaColors {
  @override
  Color get textPrimary => const Color(0xFFF2F5F9);
  @override
  Color get textSecondary => const Color(0xFF9CAAC0);
  @override
  Color get textTertiary => const Color(0xFF5A6980);
  @override
  Color get textInverse => const Color(0xFF000000);

  @override
  Color get surfacePrimary => const Color(0xFF21293B);
  @override
  Color get surfaceBorderPrimary => const Color(0xFF273142);
  @override
  Color get surfaceSecondary => const Color(0xFF273142);
  @override
  Color get surfaceBorderSecondary => const Color(0xFF333E51);
  @override
  Color get surfaceTertiary => const Color(0xFF333E51);
  @override
  Color get surfaceInverse => const Color(0xFFF2F5F9);
  @override
  Color get surfaceBackground => const Color(0xFF131927);
  @override
  Color get surfaceSelected => const Color(0x29009AD6);
  @override
  Color get surfaceBorderSelected => const Color(0xFF085370);

  @override
  Color get glassSurface => const Color(0x8021293B);
  @override
  Color get glassInverse => const Color(0xD9FFFFFF);
  @override
  Color get glassBackground => const Color(0x4D131927);

  @override
  Color get accentBrand => const Color(0xFF01B0E7);
  @override
  Color get accentBrandTransparent => const Color(0x29009AD6);
  @override
  Color get accentSuccess => const Color(0xFF12BCB2);
  @override
  Color get accentSuccessTransparent => const Color(0x2900A398);
  @override
  Color get accentWarning => const Color(0xFFFFC20A);
  @override
  Color get accentWarningTransparent => const Color(0xF7B90029);
  @override
  Color get accentDanger => const Color(0xFFFF4747);
  @override
  Color get accentDangerTransparent => const Color(0x29FF2E2E);

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
