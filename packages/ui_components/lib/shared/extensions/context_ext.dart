import 'dart:io';

import 'package:flutter/widgets.dart';

const _kSystemGestureNavBarHeight = 24.0;

extension ContextExt on BuildContext {
  /// Returns `true` when the device is running Android **and** the user has
  /// enabled 2-button or 3-button system navigation (i.e. the traditional
  /// on-screen navigation bar is visible). For gesture navigation or on
  /// non-Android platforms this returns `false`.
  ///
  /// The check is heuristic: we measure the bottom [MediaQuery.viewPadding].
  /// When button navigation is active, Android reserves space at the bottom of
  /// the screen, resulting in a non-zero padding. Gesture navigation reports
  /// zero unless a display cut-out is present.
  bool get isButtonSystemNavigationOn =>
      Platform.isAndroid &&
      MediaQuery.of(this).viewPadding.bottom > _kSystemGestureNavBarHeight;
}
