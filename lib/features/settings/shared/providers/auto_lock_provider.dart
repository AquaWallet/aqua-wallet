import 'package:aqua/config/router/go_router.dart';
import 'package:aqua/features/auth/auth.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.autoLock);

final autoLockProvider = Provider<AutoLockService>((ref) {
  return AutoLockService(ref);
});

class AutoLockService {
  final Ref _ref;

  AutoLockService(this._ref);

  /// Handles the auto lock logic when the app resumes from background
  Future<void> handleAppResume({
    required DateTime? backgroundStartTime,
  }) async {
    if (backgroundStartTime == null) {
      _logger.debug("No background start time, skipping auto lock");
      return;
    }

    // Skip auto-lock if biometric auth happened recently (from any screen)
    final authTracker = _ref.read(biometricAuthTrackerProvider);
    if (authTracker.wasRecentlyAuthenticated() ||
        authTracker.wasRecentlyFailed()) {
      _logger
          .debug("Skipping auto lock due to recent biometric authentication");
      return;
    }

    final autoLockAfter =
        _ref.read(prefsProvider.select((p) => p.autoLockAfter));
    final authDeps = _ref.read(authDepsProvider);

    _logger.debug("Background start time: $backgroundStartTime");

    final minutesSinceAppWentInBackground =
        DateTime.now().difference(backgroundStartTime).inMinutes;
    final shouldLock =
        shouldLockApp(autoLockAfter, minutesSinceAppWentInBackground);

    _logger.debug(
        "Minutes in background: $minutesSinceAppWentInBackground, shouldLock: $shouldLock");

    if (!shouldLock) {
      return;
    }

    if (isPinEnabled(authDeps)) {
      final success = await _ref.read(routerProvider).push(
            CheckPinScreen.routeName,
            extra: CheckPinScreenArguments(
              onSuccessAction: CheckAction.pull,
              canCancel: false,
            ),
          );

      if (success == false) {
        return handleAppResume(backgroundStartTime: backgroundStartTime);
      }
    }
  }

  /// Determines if the app should be locked based on auto lock settings and time elapsed
  bool shouldLockApp(AutoLockOption autoLockAfter, int minutesSinceBackground) {
    return autoLockAfter == AutoLockOption.always ||
        minutesSinceBackground >= autoLockAfter.value;
  }

  /// Checks if PIN authentication is enabled
  bool isPinEnabled(AsyncValue<AuthDepsData> authDeps) {
    return authDeps.asData?.value.pinState != PinAuthState.disabled;
  }
}
