import 'package:flutter/material.dart';

enum DeviceCategory { smallMobile, mobile, wideMobile, tablet, desktop }

class ResponsiveBreakpoints {
  static double maxSmallMobileViewportWidth = 380;
  static double maxMobileViewportWidth = 480;
  static double maxWideMobileViewportWidth = 768;
  static double maxTabletViewportWidth = 1366;

  static DeviceCategory getDeviceCategory(
    double screenWidth,
    double screenHeight,
  ) {
    if (screenWidth <= maxSmallMobileViewportWidth) {
      return DeviceCategory.smallMobile;
    }
    if (screenWidth <= maxMobileViewportWidth) {
      return DeviceCategory.mobile;
    }
    if (screenWidth <= maxWideMobileViewportWidth) {
      return DeviceCategory.wideMobile;
    }
    if (screenWidth <= maxTabletViewportWidth) {
      return DeviceCategory.tablet;
    }
    return DeviceCategory.desktop;
  }
}

extension ResponsiveEx on BuildContext {
  DeviceCategory get deviceCategory =>
      ResponsiveBreakpoints.getDeviceCategory(vw, vh);
  bool get isMobile => deviceCategory == DeviceCategory.mobile;
  bool get isSmallMobile => deviceCategory == DeviceCategory.smallMobile;
  bool get isWideMobile => deviceCategory == DeviceCategory.wideMobile;
  bool get isTablet => deviceCategory == DeviceCategory.tablet;
  bool get isDesktop => deviceCategory == DeviceCategory.desktop;

  /// Gets the screen orientation (portrait or landscape).
  Orientation get orientation => MediaQuery.of(this).orientation;

  /// Gets the screen height in visual height units.
  double get vh => MediaQuery.sizeOf(this).height;

  /// Gets the screen width in visual width units.
  double get vw => MediaQuery.sizeOf(this).width;

  /// Gets the screen size as a `Size` object.
  Size get size => MediaQuery.sizeOf(this);

  /// Retrieves a double value that adapts to different device sizes and orientations.
  ///
  /// The value is determined based on the current device's type (mobile, tablet, desktop)
  /// and the orientation (portrait or landscape). The provided parameters, such as
  /// `mobile`, `tablet`, and `desktop`, specify the values to use for each scenario.
  ///
  double adaptiveDouble({
    required double mobile,
    double? smallMobile,
    double? wideMobile,
    double? tablet,
    double? desktop,
  }) {
    double defaultDeviceSize = mobile;
    if (isSmallMobile) {
      return smallMobile ?? defaultDeviceSize;
    }
    if (isMobile) {
      return mobile;
    }
    if (isWideMobile) {
      return wideMobile ?? defaultDeviceSize;
    }
    if (isTablet) {
      return tablet ?? defaultDeviceSize;
    }
    if (isDesktop) {
      return desktop ?? tablet ?? defaultDeviceSize;
    }
    return defaultDeviceSize;
  }

  /// Retrieves a `MainAxisAlignment` value that adapts to different device sizes.
  ///
  /// The value is determined based on the current device type (mobile, tablet, desktop).
  /// If the device is in mobile view, `mobile` is returned; otherwise, `orElse` is used.
  ///
  MainAxisAlignment adaptiveMainAxisAlignment({
    required MainAxisAlignment mobile,
    MainAxisAlignment orElse = MainAxisAlignment.start,
  }) {
    return isMobile ? mobile : orElse;
  }

  /// Retrieves a `CrossAxisAlignment` value that adapts to different device sizes.
  ///
  /// The value is determined based on the current device type (mobile, tablet, desktop).
  /// If the device is in mobile view, `mobile` is returned; otherwise, `orElse` is used.
  ///
  CrossAxisAlignment adaptiveCrossAxisAlignment({
    required CrossAxisAlignment mobile,
    CrossAxisAlignment orElse = CrossAxisAlignment.start,
  }) {
    return isMobile ? mobile : orElse;
  }

  double getCardHeight({
    required List<String> items,
    double charactersPerLine = 18,
    double defaultHeightPerLine = 80,
  }) {
    const kCardMaxLineLength = 60;
    String longestStringFromItems = items.reduce((a, b) {
      return a.length > b.length ? a : b;
    });
    double heightPerLine = longestStringFromItems.length > kCardMaxLineLength
        ? defaultHeightPerLine / 1.5
        : defaultHeightPerLine;

    return (longestStringFromItems.length / charactersPerLine) * heightPerLine;
  }
}
