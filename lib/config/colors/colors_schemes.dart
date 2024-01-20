import 'package:aqua/config/colors/aqua_colors.dart';
import 'package:flutter/material.dart';

//ANCHOR - Theme Colors

abstract class AppColors {
  Color get divider;

  Color get notificationButtonBackground;

  Color get iconBackground;

  Color get iconForeground;

  Color get inputBackground;

  Color get addressHistoryItemBackground;

  Color get menuBackground;

  Color get menuSurface;

  Color get receiveAddressCopySurface;

  Color get receiveContentBoxBorder;

  Color get altScreenBackground;

  Color get altScreenSurface;

  Color get hintTextColor;

  Color get usdContainerColor;

  Color get headerUsdContainerColor;

  Color get headerUsdContainerTextColor;

  Color get sendAssetPriorityUnselectedBorder;

  Color get sendAssetPrioritySelectedText;

  Color get swapAssetPickerPopUpItemBackground;

  Color get roundedButtonOutlineColor;

  Color get listItemRoundedIconBackground;

  Color get tabSelectedBackground;

  Color get tabSelectedForeground;

  Color get tabUnselectedBackground;

  Color get tabUnselectedForeground;

  Color get cardOutlineColor;

  Color get headerSubtitle;

  Color get redBTCDeltaColor;

  Color get greenBTCDeltaColor;

  Color get walletTabButtonBackgroundColor;

  Color get appBarIconBackgroundColor;

  Color get usdContainerBackgroundColor;

  Color get usdContainerSendRecieveAssets;

  Color get appBarIconOutlineColor;

  Color get helpScreenLogoColor;

  Color get disabledBackgroundColorAquaElevatedButton;

  ColorScheme get colorScheme;
}

//ANCHOR - Dark Theme Colors

class DarkThemeColors implements AppColors {
  @override
  Color get divider => AquaColors.seaBlue;

  @override
  Color get notificationButtonBackground => AquaColors.blueGreen;

  @override
  Color get iconBackground => AquaColors.eerieBlack;

  @override
  Color get iconForeground => Colors.white;

  @override
  Color get inputBackground => AquaColors.eerieBlack;

  @override
  Color get addressHistoryItemBackground => AquaColors.eerieBlack;

  @override
  Color get menuBackground => AquaColors.blueGreen;

  @override
  Color get menuSurface => AquaColors.eerieBlack;

  @override
  Color get receiveAddressCopySurface => AquaColors.eerieBlack;

  @override
  Color get receiveContentBoxBorder => AquaColors.eerieBlack;

  @override
  Color get altScreenBackground => AquaColors.charlestonGreen;

  @override
  Color get altScreenSurface => AquaColors.eerieBlack;

  @override
  Color get hintTextColor => AquaColors.quickSilver;

  @override
  Color get usdContainerColor => AquaColors.eerieBlack;

  @override
  Color get headerUsdContainerColor => AquaColors.lotion;

  @override
  Color get headerUsdContainerTextColor => AquaColors.blueGreen;

  @override
  Color get sendAssetPriorityUnselectedBorder => AquaColors.charlestonGreen;

  @override
  Color get sendAssetPrioritySelectedText => Colors.white;

  @override
  Color get swapAssetPickerPopUpItemBackground => AquaColors.eerieBlack;

  @override
  Color get roundedButtonOutlineColor => AquaColors.brightGray;

  @override
  Color get listItemRoundedIconBackground => AquaColors.eerieBlack;

  @override
  Color get tabSelectedBackground => AquaColors.charlestonGreen;

  @override
  Color get tabSelectedForeground => Colors.white;

  @override
  Color get tabUnselectedBackground => Colors.black;

  @override
  Color get tabUnselectedForeground => Colors.white;

  @override
  Color get cardOutlineColor => Colors.transparent;

  @override
  Color get headerSubtitle => AquaColors.brightGray;

  @override
  Color get redBTCDeltaColor => Colors.red;

  @override
  Color get greenBTCDeltaColor => Colors.green;

  @override
  Color get walletTabButtonBackgroundColor => AquaColors.robinEggBlue;

  @override
  Color get usdContainerBackgroundColor => AquaColors.brightGray;

  @override
  Color get usdContainerSendRecieveAssets => AquaColors.charcoal;

  @override
  Color get appBarIconOutlineColor => AquaColors.gray;

  @override
  Color get appBarIconBackgroundColor => AquaColors.robinEggBlue;

  @override
  Color get helpScreenLogoColor => Colors.white;

  @override
  Color get disabledBackgroundColorAquaElevatedButton => AquaColors.linkWater;

  @override
  ColorScheme get colorScheme => ColorScheme(
        brightness: Brightness.dark,
        primary: AquaColors.blueGreen,
        onPrimary: Colors.white,
        secondary: AquaColors.robinEggBlue,
        onSecondary: Colors.white,
        secondaryContainer: AquaColors.lightSilver,
        onSecondaryContainer: Colors.white,
        tertiary: Colors.indigo.shade200,
        onTertiary: AquaColors.eerieBlack,
        surface: AquaColors.charlestonGreen,
        onSurface: AquaColors.cadetGrey,
        background: AquaColors.eerieBlack,
        onBackground: Colors.white,
        error: AquaColors.portlandOrange,
        onError: Colors.white,
      );
}

//ANCHOR - Light Theme Colors

class LightThemeColors implements AppColors {
  @override
  Color get divider => AquaColors.brightGray;

  @override
  Color get notificationButtonBackground => Colors.white;

  @override
  Color get iconBackground => AquaColors.eerieBlack;

  @override
  Color get iconForeground => Colors.white;

  @override
  Color get inputBackground => Colors.white;

  @override
  Color get addressHistoryItemBackground => Colors.white;

  @override
  Color get menuBackground => AquaColors.antiFlashWhite;

  @override
  Color get menuSurface => AquaColors.lotion;

  @override
  Color get receiveAddressCopySurface => AquaColors.lotion;

  @override
  Color get receiveContentBoxBorder => AquaColors.brightGray;

  @override
  Color get altScreenBackground => AquaColors.lotion;

  @override
  Color get altScreenSurface => Colors.white;

  @override
  Color get hintTextColor => AquaColors.quickSilver;

  @override
  Color get usdContainerColor => AquaColors.antiFlashWhite;

  @override
  Color get headerUsdContainerColor => AquaColors.antiFlashWhite;

  @override
  Color get headerUsdContainerTextColor => AquaColors.eerieBlack;

  @override
  Color get sendAssetPriorityUnselectedBorder => AquaColors.brightGray;

  @override
  Color get sendAssetPrioritySelectedText => Colors.white;

  @override
  Color get swapAssetPickerPopUpItemBackground => AquaColors.cultured;

  @override
  Color get roundedButtonOutlineColor => AquaColors.lightSilver;

  @override
  Color get listItemRoundedIconBackground => AquaColors.brightGray;

  @override
  Color get tabSelectedBackground => Colors.white;

  @override
  Color get tabSelectedForeground => AquaColors.eerieBlack;

  @override
  Color get tabUnselectedBackground => AquaColors.brightGray;

  @override
  Color get tabUnselectedForeground => AquaColors.eerieBlack;

  @override
  Color get cardOutlineColor => AquaColors.chineseWhite;

  @override
  Color get headerSubtitle => AquaColors.graniteGray;

  @override
  Color get redBTCDeltaColor => Colors.red;

  @override
  Color get greenBTCDeltaColor => Colors.green;

  @override
  Color get walletTabButtonBackgroundColor => AquaColors.splashGrey;

  @override
  Color get usdContainerBackgroundColor => AquaColors.cloudGrey;

  @override
  Color get usdContainerSendRecieveAssets => AquaColors.cloudGrey;

  @override
  Color get appBarIconOutlineColor => AquaColors.lightSilver;

  @override
  Color get appBarIconBackgroundColor => AquaColors.antiFlashWhite;

  @override
  Color get helpScreenLogoColor => AquaColors.eerieBlack;

  @override
  Color get disabledBackgroundColorAquaElevatedButton => AquaColors.linkWater;

  @override
  ColorScheme get colorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: AquaColors.blueGreen,
        onPrimary: Colors.white,
        secondary: AquaColors.robinEggBlue,
        onSecondary: AquaColors.eerieBlack,
        secondaryContainer: AquaColors.lightSilver,
        onSecondaryContainer: Colors.white,
        primaryContainer: AquaColors.antiFlashWhite,
        onPrimaryContainer: AquaColors.eerieBlack,
        tertiary: AquaColors.indigo,
        onTertiary: AquaColors.eerieBlack,
        surface: Colors.white,
        onSurface: AquaColors.cadetGrey,
        background: AquaColors.lotion,
        onBackground: AquaColors.eerieBlack,
        error: AquaColors.portlandOrange,
        onError: Colors.white,
      );
}
