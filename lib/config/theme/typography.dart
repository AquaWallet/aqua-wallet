import 'package:aqua/config/colors/colors_schemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              fontSize: 57.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
        displayMedium: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 45.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
        displaySmall: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 36.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
        //ANCHOR - Headline
        headlineLarge: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
        headlineMedium: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
        headlineSmall: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
        //ANCHOR - Title
        titleLarge: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
        titleMedium: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
              letterSpacing: .15,
            ),
        titleSmall: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14.sp,
              color: colors.colorScheme.onBackground,
              fontWeight: FontWeight.bold,
              letterSpacing: .1,
            ),
        //ANCHOR - Label
        labelLarge: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onBackground,
            ),
        labelMedium: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12.sp,
              color: colors.colorScheme.onBackground,
            ),
        labelSmall: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11.sp,
            ),
        //ANCHOR - Body
        bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.colorScheme.onBackground,
              fontSize: 16.sp,
            ),
        bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.colorScheme.onBackground,
              fontSize: 14.sp,
            ),
        bodySmall: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.colorScheme.onBackground,
              fontSize: 12.sp,
            ),
      );

  TextStyle get bottomNavBarLabelStyle => appTextTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.bold,
      );
}
