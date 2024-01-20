enum DeviceCategory {
  mobile,
  tabletPortrait,
  tabletLandscape,
  desktop,
  unknown,
}

class ResponsiveBreakpoints {
  static double minMobileWidth = 300;
  static double maxMobileWidth = 767;

  static double minPortraitTabletWidth = 768;
  static double maxPortraitTabletWidth = 1024;
  static double minLandscapeTabletWidth = 1025;
  static double maxLandscapeTabletWidth = 1366;

  static double minDesktopWidth = 1367;

  static DeviceCategory getDeviceCategory(double screenWidth) {
    if (screenWidth >= minMobileWidth && screenWidth <= maxMobileWidth) {
      return DeviceCategory.mobile;
    } else if (screenWidth >= minPortraitTabletWidth &&
        screenWidth <= maxPortraitTabletWidth) {
      return DeviceCategory.tabletPortrait;
    } else {
      return DeviceCategory.unknown;
    }
  }
}
