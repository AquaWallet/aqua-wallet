// ignore_for_file: deprecated_member_use

import 'package:aqua/config/colors/aqua_colors.dart';
import 'package:flutter/material.dart';

//ANCHOR - Theme Colors

abstract class AppColors {
  Color get background;

  Color get onBackground;

  Color get divider;

  Color get horizontalDivider;

  Color get link;

  Color get walletHeaderDivider;

  Color get dottedDivider;

  Color get bottomNavBarBorder;

  Color get bottomNavBarIconUnselected;

  Color get bottomNavBarIconSelected;

  Color get notificationButtonBackground;

  Color get iconBackground;

  Color get iconForeground;

  Color get settingsIcon;

  Color get inputBackground;

  Color get addressHistoryItemBackground;

  Color get menuBackground;

  Color get menuSurface;

  Color get dropdownMenuBackground;

  Color get receiveAddressCopySurface;

  Color get receiveContentBoxBorder;

  Color get altScreenBackground;

  Color get altScreenSurface;

  Color get hintTextColor;

  Color get usdContainerColor;

  Color get headerUsdContainerColor;

  Color get headerUsdContainerTextColor;

  Color get usdPillTextColor;

  Color get sendAssetPriorityUnselectedBorder;

  Color get sendAssetPrioritySelectedBorder;

  Color get sendAssetPrioritySelectedText;

  Color get swapAssetPickerPopUpItemBackground;

  Color get roundedButtonOutlineColor;

  Color get listItemBackground;

  Color get listItemRoundedIconBackground;

  Color get tabSelectedBackground;

  Color get tabSelectedForeground;

  Color get tabUnselectedBackground;

  Color get tabUnselectedForeground;

  Color get cardOutlineColor;

  Color get headerSubtitle;

  Color get neutraBTCDeltaColor;

  Color get redBTCDeltaColor;

  Color get greenBTCDeltaColor;

  Color get walletTabButtonBackgroundColor;

  Color get appBarBackgroundColor;

  Color get appBarIconBackgroundColor;

  Color get appBarIconBackgroundColorAlt;

  Color get usdContainerBackgroundColor;

  Color get usdPillBackgroundColor;

  Color get usdContainerSendRecieveAssets;

  Color get appBarIconOutlineColor;

  Color get appBarIconOutlineColorAlt;

  Color get helpScreenLogoColor;

  Color get disabledBackgroundColorAquaElevatedButton;

  Color get addressHistoryBackgroundColor;

  Color get addressHistoryHintTextColor;

  Color get addressHistoryNoHistoryIconColor;

  Color get addressHistoryNoHistoryTextColor;

  Color get addressHistoryTabBarSelected;

  Color get addressHistoryTabBarUnSelected;

  Color get addressHistoryTabBarTextSelected;

  Color get addressHistoryTabBarTextUnSelected;

  Color get popUpMenuButtonSwapScreenTextColor;

  Color get popUpMenuButtonSwapScreenBorderColor;

  Color get success;

  Color get keyboardBackground;

  Color get inverseSurfaceColor;

  Color get sendMaxButtonBackgroundColor;

  Color get addressFieldContainerBackgroundColor;

  Color get textFieldOutlineColor;

  Color get usdCenterPillBackgroundColor;

  Color get swapConversionRateViewTextColor;

  Color get swapReviewScreenBackgroundColor;

  Color get walletRemoveTextColor;

  Color get recieveOtherAssetsTabBarSepratorColor;

  Color get headerBackgroundColor;

  Color get transactionAppBarBackgroundColor;

  Color get conversionRateSwapScreenColor;

  Color get conversionRateSwapScreenBackgroundColor;

  Color get versionBackground;

  Color get versionForeground;

  Color get copayableTextColor;

  Color get swapButtonForeground;

  Color get swapButtonBackground;

  Color get debitCardBackground;

  Color get debitCardAvailableAmountLabelColor;

  Color get debitCardUsedAmountLabelColor;

  Color get debitCardTransactionTitleColor;

  Color get debitCardTransactionSubtitleColor;

  Color get walletAmountLabel;

  Color get selectedFeeCard;

  Color get unselectedFeeCard;

  Color get debitCardAddBalanceMinMaxAmountLabelColor;

  Color get topUpTransactionAmountSubtitleColor;

  ColorScheme get colorScheme;
}

//ANCHOR - Dark Theme Colors

class DarkThemeColors implements AppColors {
  @override
  Color get divider => AquaColors.charcoal;

  @override
  Color get horizontalDivider => Colors.white;

  @override
  Color get link => Colors.white;

  @override
  Color get walletHeaderDivider => Colors.black;

  @override
  Color get dottedDivider => AquaColors.platinum;

  @override
  Color get bottomNavBarBorder => Colors.transparent;

  @override
  Color get bottomNavBarIconUnselected => AquaColors.dustyGrey;

  @override
  Color get bottomNavBarIconSelected => Colors.white;

  @override
  Color get notificationButtonBackground => Colors.white;

  @override
  Color get iconBackground => AquaColors.eerieBlack;

  @override
  Color get iconForeground => Colors.white;

  @override
  Color get settingsIcon => Colors.white;

  @override
  Color get inputBackground => AquaColors.eerieBlack;

  @override
  Color get addressHistoryItemBackground => AquaColors.eerieBlack;

  @override
  Color get menuBackground => AquaColors.blueGreen;

  @override
  Color get menuSurface => Colors.black;

  @override
  Color get dropdownMenuBackground => AquaColors.darkJungleGreen;

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
  Color get usdContainerColor => AquaColors.heavyMetal;

  @override
  Color get headerUsdContainerColor => AquaColors.lotion;

  @override
  Color get headerUsdContainerTextColor => Colors.white;

  @override
  Color get usdPillTextColor => Colors.white;

  @override
  Color get sendAssetPriorityUnselectedBorder => AquaColors.charlestonGreen;

  @override
  Color get sendAssetPrioritySelectedBorder => AquaColors.vividSkyBlue;

  @override
  Color get sendAssetPrioritySelectedText => Colors.white;

  @override
  Color get swapAssetPickerPopUpItemBackground => AquaColors.charcoal;

  @override
  Color get roundedButtonOutlineColor => AquaColors.brightGray;

  @override
  Color get listItemRoundedIconBackground => AquaColors.eerieBlack;

  @override
  Color get listItemBackground => AquaColors.charcoal;

  @override
  Color get tabSelectedBackground => AquaColors.charcoal;

  @override
  Color get tabSelectedForeground => Colors.white;

  @override
  Color get tabUnselectedBackground => AquaColors.darkJungleGreen;

  @override
  Color get tabUnselectedForeground => Colors.white;

  @override
  Color get cardOutlineColor => Colors.transparent;

  @override
  Color get headerSubtitle => AquaColors.brightGray;

  @override
  Color get neutraBTCDeltaColor => AquaColors.dustyGrey;

  @override
  Color get redBTCDeltaColor => Colors.red;

  @override
  Color get greenBTCDeltaColor => Colors.green;

  @override
  Color get walletTabButtonBackgroundColor => AquaColors.robinEggBlue;

  @override
  Color get usdContainerBackgroundColor => Colors.black;

  @override
  Color get usdPillBackgroundColor => Colors.black;

  @override
  Color get usdContainerSendRecieveAssets => AquaColors.charcoal;

  @override
  Color get appBarIconOutlineColor => AquaColors.antiFlashWhite;

  @override
  Color get appBarIconOutlineColorAlt => AquaColors.antiFlashWhite;

  @override
  Color get appBarBackgroundColor => AquaColors.charcoal;

  @override
  Color get appBarIconBackgroundColor => AquaColors.robinEggBlue;

  @override
  Color get appBarIconBackgroundColorAlt => AquaColors.jet;

  @override
  Color get helpScreenLogoColor => Colors.white;

  @override
  Color get disabledBackgroundColorAquaElevatedButton => AquaColors.linkWater;

  @override
  Color get addressHistoryBackgroundColor => Colors.black;

  @override
  Color get addressHistoryHintTextColor => Colors.white;

  @override
  Color get addressHistoryNoHistoryIconColor => Colors.white;

  @override
  Color get addressHistoryNoHistoryTextColor => Colors.white;

  @override
  Color get addressHistoryTabBarSelected => AquaColors.darkJungleGreen;

  @override
  Color get addressHistoryTabBarUnSelected => AquaColors.lightSilver;

  @override
  Color get addressHistoryTabBarTextSelected => Colors.white;

  @override
  Color get addressHistoryTabBarTextUnSelected => AquaColors.darkJungleGreen;

  @override
  Color get popUpMenuButtonSwapScreenTextColor => Colors.white;

  @override
  Color get popUpMenuButtonSwapScreenBorderColor => AquaColors.eerieBlack;

  @override
  Color get success => Colors.green;

  @override
  Color get keyboardBackground => AquaColors.brightGray;

  @override
  Color get inverseSurfaceColor => Colors.black;

  @override
  Color get sendMaxButtonBackgroundColor => AquaColors.heavyMetal;

  @override
  Color get addressFieldContainerBackgroundColor => AquaColors.charcoal;

  @override
  Color get textFieldOutlineColor => Colors.white;

  @override
  Color get usdCenterPillBackgroundColor => AquaColors.charcoal;

  @override
  Color get swapConversionRateViewTextColor => Colors.white;

  @override
  Color get swapReviewScreenBackgroundColor => AquaColors.darkJungleGreen;

  @override
  Color get walletRemoveTextColor => const Color(0xFFFF4B2B);

  @override
  Color get recieveOtherAssetsTabBarSepratorColor => Colors.white;

  @override
  Color get headerBackgroundColor => AquaColors.jet;

  @override
  Color get transactionAppBarBackgroundColor => Colors.transparent;

  @override
  Color get conversionRateSwapScreenColor => AquaColors.blueGreen;

  @override
  Color get conversionRateSwapScreenBackgroundColor => AquaColors.blueGreen;

  @override
  Color get versionBackground => AquaColors.charcoal;

  @override
  Color get versionForeground => Colors.white;

  @override
  Color get copayableTextColor => Colors.white;

  @override
  Color get swapButtonForeground => Colors.white;

  @override
  Color get swapButtonBackground => AquaColors.charcoal;

  @override
  Color get background => Colors.black;

  @override
  Color get onBackground => Colors.white;

  @override
  Color get debitCardBackground => AquaColors.jet;

  @override
  Color get debitCardAvailableAmountLabelColor => AquaColors.dimMarble;

  @override
  Color get debitCardUsedAmountLabelColor => Colors.white;

  @override
  Color get debitCardTransactionTitleColor => Colors.white;

  @override
  Color get debitCardTransactionSubtitleColor => AquaColors.dimMarble;

  @override
  Color get walletAmountLabel => AquaColors.dimMarble;

  @override
  Color get selectedFeeCard => AquaColors.aquaLightBlue;

  @override
  Color get unselectedFeeCard => Colors.transparent;

  @override
  Color get debitCardAddBalanceMinMaxAmountLabelColor => AquaColors.dimMarble;

  @override
  Color get topUpTransactionAmountSubtitleColor => AquaColors.gray;

  @override
  ColorScheme get colorScheme => ColorScheme(
        brightness: Brightness.dark,
        primary: AquaColors.backgroundSkyBlue,
        onPrimary: Colors.white,
        onPrimaryContainer: Colors.white,
        secondary: AquaColors.robinEggBlue,
        onSecondary: Colors.white,
        secondaryContainer: AquaColors.lightSilver,
        onSecondaryContainer: Colors.white,
        tertiary: Colors.indigo.shade200,
        onTertiary: AquaColors.eerieBlack,
        surface: AquaColors.eerieBlack,
        onSurface: AquaColors.cadetGrey,
        onTertiaryContainer: Colors.white,
        error: AquaColors.portlandOrange,
        onError: Colors.white,
      );
}

//ANCHOR - Light Theme Colors

class LightThemeColors implements AppColors {
  @override
  Color get divider => AquaColors.brightGray;

  @override
  Color get horizontalDivider => AquaColors.dustyGrey;

  @override
  Color get link => AquaColors.aquaBlue;

  @override
  Color get walletHeaderDivider => AquaColors.platinum;

  @override
  Color get dottedDivider => AquaColors.platinum;

  @override
  Color get bottomNavBarBorder => AquaColors.platinum;

  @override
  Color get bottomNavBarIconUnselected => AquaColors.dustyGrey;

  @override
  Color get bottomNavBarIconSelected => Colors.black;

  @override
  Color get notificationButtonBackground => Colors.black;

  @override
  Color get iconBackground => AquaColors.eerieBlack;

  @override
  Color get iconForeground => Colors.white;

  @override
  Color get settingsIcon => Colors.black;

  @override
  Color get inputBackground => Colors.white;

  @override
  Color get addressHistoryItemBackground => Colors.white;

  @override
  Color get menuBackground => AquaColors.lotion;

  @override
  Color get menuSurface => AquaColors.antiFlashWhite;

  @override
  Color get dropdownMenuBackground => AquaColors.darkJungleGreen;

  @override
  Color get receiveAddressCopySurface => AquaColors.splashGrey;

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
  Color get usdPillTextColor => AquaColors.eerieBlack;

  @override
  Color get sendAssetPriorityUnselectedBorder => AquaColors.brightGray;

  @override
  Color get sendAssetPrioritySelectedBorder => AquaColors.vividSkyBlue;

  @override
  Color get sendAssetPrioritySelectedText => Colors.black;

  @override
  Color get swapAssetPickerPopUpItemBackground => AquaColors.cultured;

  @override
  Color get roundedButtonOutlineColor => AquaColors.lightSilver;

  @override
  Color get listItemRoundedIconBackground => AquaColors.brightGray;

  @override
  Color get listItemBackground => Colors.white;

  @override
  Color get tabSelectedBackground => Colors.white;

  @override
  Color get tabSelectedForeground => AquaColors.charcoal;

  @override
  Color get tabUnselectedBackground => AquaColors.darkGray;

  @override
  Color get tabUnselectedForeground => AquaColors.charcoal;

  @override
  Color get cardOutlineColor => AquaColors.platinum;

  @override
  Color get headerSubtitle => AquaColors.graniteGray;

  @override
  Color get neutraBTCDeltaColor => AquaColors.dustyGrey;

  @override
  Color get redBTCDeltaColor => Colors.red;

  @override
  Color get greenBTCDeltaColor => Colors.green;

  @override
  Color get walletTabButtonBackgroundColor => AquaColors.splashGrey;

  @override
  Color get usdContainerBackgroundColor => AquaColors.periglacialBlue;

  @override
  Color get usdPillBackgroundColor => AquaColors.periglacialBlue;

  @override
  Color get usdContainerSendRecieveAssets => AquaColors.cloudGrey;

  @override
  Color get appBarIconOutlineColor => AquaColors.lightSilver;

  @override
  Color get appBarIconOutlineColorAlt => AquaColors.lightSilver;

  @override
  Color get appBarBackgroundColor => Colors.white;

  @override
  Color get appBarIconBackgroundColor => Colors.white;

  @override
  Color get appBarIconBackgroundColorAlt => Colors.white;

  @override
  Color get helpScreenLogoColor => AquaColors.eerieBlack;

  @override
  Color get disabledBackgroundColorAquaElevatedButton => AquaColors.linkWater;

  @override
  Color get addressHistoryBackgroundColor => AquaColors.splashGrey;

  @override
  Color get addressHistoryHintTextColor => AquaColors.cadetGrey;

  @override
  Color get addressHistoryNoHistoryIconColor => AquaColors.dustyGrey;

  @override
  Color get addressHistoryNoHistoryTextColor => AquaColors.charcoal;

  @override
  Color get addressHistoryTabBarSelected => Colors.white;

  @override
  Color get addressHistoryTabBarUnSelected => AquaColors.dustyGrey;

  @override
  Color get addressHistoryTabBarTextSelected => AquaColors.darkJungleGreen;

  @override
  Color get addressHistoryTabBarTextUnSelected => Colors.white;

  @override
  Color get popUpMenuButtonSwapScreenTextColor => AquaColors.charcoal;

  @override
  Color get popUpMenuButtonSwapScreenBorderColor => AquaColors.greyGoose;

  @override
  Color get success => Colors.green;

  @override
  Color get keyboardBackground => AquaColors.brightGray;

  @override
  Color get inverseSurfaceColor => AquaColors.splashGrey;

  @override
  Color get sendMaxButtonBackgroundColor => Colors.white;

  @override
  Color get addressFieldContainerBackgroundColor => Colors.white;

  @override
  Color get textFieldOutlineColor => AquaColors.eerieBlack;

  @override
  Color get usdCenterPillBackgroundColor => AquaColors.periglacialBlue;

  @override
  Color get swapConversionRateViewTextColor => Colors.black;

  @override
  Color get swapReviewScreenBackgroundColor => AquaColors.splashGrey;

  @override
  Color get walletRemoveTextColor => const Color(0xFFFF8F8F);

  @override
  Color get recieveOtherAssetsTabBarSepratorColor => AquaColors.platinum;

  @override
  Color get headerBackgroundColor => Colors.white;

  @override
  Color get transactionAppBarBackgroundColor => Colors.white;

  @override
  Color get conversionRateSwapScreenColor => AquaColors.lotion;

  @override
  Color get conversionRateSwapScreenBackgroundColor => Colors.white;

  @override
  Color get versionBackground => AquaColors.eerieBlack;

  @override
  Color get versionForeground => Colors.white;

  @override
  Color get copayableTextColor => AquaColors.charcoal;

  @override
  Color get swapButtonForeground => AquaColors.charcoal;

  @override
  Color get swapButtonBackground => Colors.white;

  @override
  Color get background => AquaColors.splashGrey;

  @override
  Color get onBackground => AquaColors.eerieBlack;

  @override
  Color get debitCardBackground => Colors.white;

  @override
  Color get debitCardAvailableAmountLabelColor => AquaColors.dimMarble;

  @override
  Color get debitCardUsedAmountLabelColor => AquaColors.darkGray;

  @override
  Color get debitCardTransactionTitleColor => Colors.white;

  @override
  Color get debitCardTransactionSubtitleColor => AquaColors.dimMarble;

  @override
  Color get walletAmountLabel => AquaColors.dimMarble;

  @override
  Color get selectedFeeCard => const Color(0xFFD4F6FE);

  @override
  Color get unselectedFeeCard => Colors.transparent;

  @override
  Color get debitCardAddBalanceMinMaxAmountLabelColor => AquaColors.dimMarble;

  @override
  Color get topUpTransactionAmountSubtitleColor => AquaColors.dimMarble;

  @override
  ColorScheme get colorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: AquaColors.backgroundSkyBlue,
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
        onSurface: AquaColors.dimMarble,
        onTertiaryContainer: AquaColors.charcoal,
        error: AquaColors.portlandOrange,
        onError: Colors.white,
      );
}

//ANCHOR - Botev Mode Theme Colors

class BotevThemeColors extends DarkThemeColors {
  @override
  Color get divider => AquaColors.fcBotevDivider;

  @override
  Color get horizontalDivider => Colors.black;

  @override
  Color get walletHeaderDivider => AquaColors.fcBotevDivider;

  @override
  Color get headerBackgroundColor => AquaColors.fcBotevPrimary;

  @override
  Color get appBarIconOutlineColorAlt => AquaColors.eerieBlack;

  @override
  Color get appBarIconBackgroundColorAlt => AquaColors.fcBotevPrimary;

  @override
  Color get headerUsdContainerTextColor => AquaColors.eerieBlack;

  @override
  Color get usdPillTextColor => AquaColors.fcBotevPrimary;

  @override
  Color get menuBackground => AquaColors.fcBotevPrimary;

  @override
  Color get headerSubtitle => AquaColors.charcoal;

  @override
  Color get walletTabButtonBackgroundColor => AquaColors.fcBotevSecondary;

  @override
  Color get usdContainerBackgroundColor => Colors.black;

  @override
  Color get conversionRateSwapScreenColor => AquaColors.fcBotevPrimary;

  @override
  Color get swapConversionRateViewTextColor => Colors.black;

  @override
  Color get walletAmountLabel => Colors.black;

  @override
  Color get selectedFeeCard => AquaColors.aquaLightBlue;

  @override
  Color get unselectedFeeCard => Colors.transparent;

  @override
  ColorScheme get colorScheme => super.colorScheme.copyWith(
        primary: AquaColors.fcBotevPrimary,
        secondary: AquaColors.fcBotevSecondary,
        onPrimary: Colors.black,
        onPrimaryContainer: Colors.black,
        onSecondaryContainer: Colors.black,
      );
}
