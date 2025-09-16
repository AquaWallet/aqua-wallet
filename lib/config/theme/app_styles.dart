// ignore_for_file: deprecated_member_use

import 'package:coin_cz/config/colors/aqua_colors.dart';
import 'package:coin_cz/config/colors/colors_schemes.dart';
import 'package:coin_cz/config/theme/typography.dart';
import 'package:coin_cz/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class AppStyle {
  const AppStyle._();

  static final lightColors = LightThemeColors();
  static final darkColors = DarkThemeColors();
  static final botevColors = BotevThemeColors();

  static final roundedRectangleBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(32.0),
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment(0, -1),
    end: Alignment(0, 1),
    colors: [
      AquaColors.backgroundGradientStartColor,
      AquaColors.backgroundGradientEndColor
    ],
  );

  static const gridItemGradient = LinearGradient(
    begin: Alignment(0.00, -1.00),
    end: Alignment(0, 1),
    colors: [
      AquaColors.blueGreen,
      AquaColors.celadonBlue,
    ],
  );

  static ThemeData createLightThemeData(BuildContext context) {
    final typography = AppTypography.createLight(context, lightColors);
    return _create(lightColors, typography);
  }

  static ThemeData createDarkThemeData(BuildContext context) {
    final typography = AppTypography.createDark(context, darkColors);
    return _create(darkColors, typography);
  }

  static ThemeData createBotevThemeData(BuildContext context) {
    final typography = AppTypography.createDark(context, botevColors);
    return _create(botevColors, typography);
  }

  static ThemeData _create(AppColors colors, AppTypography typography) {
    return ThemeData(
      useMaterial3: false,
      fontFamily: UiFontFamily.helveticaNeue,
      colorScheme: colors.colorScheme,
      textTheme: typography.appTextTheme,
      dividerColor: colors.divider,
      scaffoldBackgroundColor: colors.background,
      //ANCHOR - ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.colorScheme.primary,
          foregroundColor: colors.colorScheme.onPrimary,
          disabledForegroundColor: colors.colorScheme.surface,
          disabledBackgroundColor:
              colors.disabledBackgroundColorAquaElevatedButton,
          textStyle: typography.appTextTheme.labelLarge,
          minimumSize: const Size(100.0, 52.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
      //ANCHOR - OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.colorScheme.secondaryContainer,
          backgroundColor: colors.colorScheme.surface,
          shape: roundedRectangleBorder,
          side: BorderSide(color: colors.colorScheme.surface),
          minimumSize: const Size(100.0, 48.0),
        ),
      ),
      //ANCHOR - TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.colorScheme.onPrimary,
          shape: roundedRectangleBorder,
        ),
      ),
      //ANCHOR - AppBar
      appBarTheme: AppBarTheme(
        iconTheme: IconThemeData(color: colors.background),
        backgroundColor: colors.background,
        shadowColor: Colors.transparent,
        titleTextStyle: typography.appTextTheme.titleMedium?.copyWith(
          fontSize: 18.0,
          letterSpacing: 0.15,
          color: colors.onBackground,
        ),
      ),
      //ANCHOR - Chip
      chipTheme: ChipThemeData(
        brightness: Brightness.dark,
        selectedColor: colors.colorScheme.secondary,
        backgroundColor: colors.background,
        secondarySelectedColor: colors.colorScheme.secondary,
        disabledColor: colors.background,
        padding: const EdgeInsets.all(0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      //ANCHOR - Text Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.colorScheme.secondaryContainer,
        selectionColor: colors.colorScheme.secondaryContainer,
        selectionHandleColor: colors.colorScheme.secondaryContainer,
      ),
      //ANCHOR - Card
      cardTheme: CardTheme(
        elevation: 4,
        color: colors.colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.colorScheme.surface,
        hintStyle: typography.appTextTheme.labelLarge?.copyWith(
          color: colors.onBackground,
          fontSize: 14.0,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
      ),
      //ANCHOR - Bottom Nav Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.colorScheme.surface,
        selectedItemColor: colors.onBackground,
        unselectedItemColor: colors.onBackground,
        selectedLabelStyle: typography.bottomNavBarLabelStyle,
        unselectedLabelStyle: typography.bottomNavBarLabelStyle,
      ),
    );
  }
}

extension ThemeDataEx on ThemeData {
  AppColors get colors => isLight
      ? AppStyle.lightColors
      : isBotevMode
          ? AppStyle.botevColors
          : AppStyle.darkColors;

  bool get isLight => brightness == Brightness.light;

  bool get isBotevMode => colorScheme.primary == AquaColors.fcBotevPrimary;

  bool get isDarkMode => colorScheme.brightness == Brightness.dark;

  TextStyle get richTextStyleNormal => textTheme.headlineLarge!.copyWith(
        fontSize: 26.0,
        fontWeight: FontWeight.normal,
        height: 1.25,
      );

  TextStyle get richTextStyleBold => richTextStyleNormal.copyWith(
        fontWeight: FontWeight.bold,
      );

  BoxDecoration get roundedShadowBoxDecoration => BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: colorScheme.shadow.withOpacity(0.2),
          ),
        ],
      );

  BoxDecoration get boxDecorationForMarketplaceCards => BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: isDarkMode
            ? null
            : Border.all(
                color: colors.cardOutlineColor,
                width: 2.0,
              ),
      );

  BoxDecoration get solidBorderDecoration => BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: colors.onBackground,
          // Make sure to define 'w' or replace it with a specific value
          width: 2.0,
        ),
      );

  InputDecoration get inputDecoration => InputDecoration(
        filled: true,
        fillColor: colors.inputBackground,
        border: InputBorder.none,
        focusedBorder: inputBorder,
      );

  InputDecoration get outlineInputDecoration => InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 21,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: colors.textFieldOutlineColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: colors.textFieldOutlineColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: colors.textFieldOutlineColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: colors.textFieldOutlineColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: colors.textFieldOutlineColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontFamily: UiFontFamily.inter,
          fontWeight: FontWeight.w500,
          height: 1.21,
        ),
      );

  InputBorder get inputBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide.none,
      );

  BoxShadow get shadow => BoxShadow(
        offset: Offset(0, 0.toDouble()),
        blurRadius: 6,
        spreadRadius: 0,
        color: colorScheme.shadow.withOpacity(0.2),
      );

  BoxShadow get swapScreenRateConversionBoxShadows => BoxShadow(
        offset: const Offset(0, 4),
        blurRadius: 4,
        spreadRadius: 0,
        color: colorScheme.shadow.withOpacity(0.1),
      );

  Gradient getFadeGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
    Color? color,
  }) =>
      LinearGradient(
        begin: begin,
        end: end,
        colors: [
          color?.withOpacity(0) ?? colors.menuSurface.withOpacity(0),
          color ?? colors.menuSurface,
        ],
      );
}
