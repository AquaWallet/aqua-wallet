// ignore_for_file: deprecated_member_use

import 'package:aqua/config/colors/colors_schemes.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';

// TEXT
class AppTypography {
  AppTypography._(
    this.context, {
    required this.colors,
    required this.isDark,
  });

  factory AppTypography.createDark(BuildContext context, AppColors colors) {
    return AppTypography._(context, colors: colors, isDark: true);
  }

  factory AppTypography.createLight(BuildContext context, AppColors colors) {
    return AppTypography._(context, colors: colors, isDark: false);
  }

  final BuildContext context;
  final AppColors colors;
  final bool isDark;

  TextTheme get appTextTheme => Theme.of(context).textTheme.copyWith(
        //ANCHOR - Display
        displayLarge: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 57.0,
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        displayMedium: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 45.0,
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        displaySmall: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 36.0,
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        //ANCHOR - Headline
        headlineLarge: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32.0,
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        headlineMedium: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28.0,
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        headlineSmall: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24.0,
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        //ANCHOR - Title
        titleLarge: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: context.adaptiveDouble(mobile: 22.0, wideMobile: 20.0),
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        titleMedium: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: context.adaptiveDouble(mobile: 16.0, wideMobile: 14.0),
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
              letterSpacing: .15,
            ),
        titleSmall: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: context.adaptiveDouble(mobile: 14.0, wideMobile: 12.0),
              color: colors.onBackground,
              fontWeight: FontWeight.bold,
              fontFamily: UiFontFamily.helveticaNeue,
              letterSpacing: .1,
            ),
        //ANCHOR - Label
        labelLarge: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: context.adaptiveDouble(mobile: 16.0, wideMobile: 14.0),
              color: colors.onBackground,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        labelMedium: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: context.adaptiveDouble(mobile: 14.0, wideMobile: 12.0),
              color: colors.onBackground,
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        labelSmall: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: context.adaptiveDouble(mobile: 11.0, wideMobile: 10.0),
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        //ANCHOR - Body
        bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.onBackground,
              fontSize: context.adaptiveDouble(mobile: 16.0, wideMobile: 14.0),
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onBackground,
              fontSize: context.adaptiveDouble(mobile: 14.0, wideMobile: 12.0),
              fontFamily: UiFontFamily.helveticaNeue,
            ),
        bodySmall: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onBackground,
              fontSize: context.adaptiveDouble(mobile: 12.0, wideMobile: 10.0),
              fontFamily: UiFontFamily.helveticaNeue,
            ),
      );

  TextStyle get bottomNavBarLabelStyle => appTextTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.bold,
        fontFamily: UiFontFamily.helveticaNeue,
        height: 1,
        letterSpacing: 0,
      );
}
