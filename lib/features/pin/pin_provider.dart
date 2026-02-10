import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/pin/models/pin_state.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

enum PinAuthState { enabled, disabled, locked }

class PinAuthNotifier extends AsyncNotifier<PinAuthState> {
  @override
  FutureOr<PinAuthState> build() async {
    state = const AsyncValue.loading();

    final storage = ref.read(secureStorageProvider);
    final (currentWalletId, _) = await storage.get(StorageKeys.currentWalletId);

    if (currentWalletId == null) {
      state = const AsyncData(PinAuthState.disabled);
      return PinAuthState.disabled;
    }

    final pin = await getPin();
    if (pin == null) {
      state = const AsyncData(PinAuthState.disabled);
      return PinAuthState.disabled;
    }

    final (lockedAt, _) = await storage.get(
      StorageKeys.pinLockedAt,
    );

    if (lockedAt != null && await tryUnlock() == false) {
      state = const AsyncData(PinAuthState.locked);
      return PinAuthState.locked;
    }

    state = const AsyncData(PinAuthState.enabled);
    return PinAuthState.enabled;
  }

  Future<String?> getPin() async {
    final storage = ref.read(secureStorageProvider);

    final (pin, _) = await storage.get(StorageKeys.pin);
    return pin;
  }

  Future<void> setPin(String pin) async {
    final storage = ref.read(secureStorageProvider);

    final (existingPin, _) = await storage.get(StorageKeys.pin);

    if (existingPin != null) {
      throw Exception('PIN already persisted');
    }

    await storage.save(
      key: StorageKeys.pin,
      value: pin,
    );

    state = const AsyncData(PinAuthState.enabled);
  }

  static const Duration lockDuration = Duration(minutes: 3);

  Future<bool?> tryUnlock() async {
    final storage = ref.read(secureStorageProvider);

    final (lockedAt, _) = await storage.get(
      StorageKeys.pinLockedAt,
    );

    if (lockedAt != null) {
      final lockedAtDateTime = DateTime.parse(lockedAt);
      final isExpired =
          DateTime.now().difference(lockedAtDateTime) >= lockDuration;
      if (isExpired) {
        await storage.delete(StorageKeys.pinFailedAttempts);
        await storage.delete(StorageKeys.pinLockedAt);
        state = const AsyncData(PinAuthState.enabled);
        return true;
      }
      return false;
    }
    return null;
  }

  Future<Duration?> getRemainingLockTime() async {
    final storage = ref.read(secureStorageProvider);
    final (lockedAt, _) = await storage.get(StorageKeys.pinLockedAt);

    logger.debug('PinLockTimer: lockedAt = $lockedAt');
    if (lockedAt == null) return null;

    final lockedAtDateTime = DateTime.parse(lockedAt);
    final elapsed = DateTime.now().difference(lockedAtDateTime);
    final remaining = lockDuration - elapsed;

    logger.debug('PinLockTimer: elapsed = $elapsed, remaining = $remaining');
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> lock() async {
    final storage = ref.read(secureStorageProvider);

    await storage.save(
      key: StorageKeys.pinLockedAt,
      value: DateTime.now().toIso8601String(),
    );

    state = const AsyncData(PinAuthState.locked);
  }

  Future<void> disable() async {
    await ref.read(secureStorageProvider).delete(StorageKeys.pin);
    await ref.read(secureStorageProvider).delete(StorageKeys.pinFailedAttempts);
    await ref.read(secureStorageProvider).delete(StorageKeys.pinLockedAt);
    await ref.read(prefsProvider).removeAutoLock();

    state = const AsyncData(PinAuthState.disabled);
  }
}

final pinAuthProvider =
    AsyncNotifierProvider<PinAuthNotifier, PinAuthState>(PinAuthNotifier.new);

class PinNotifier extends StateNotifier<PinState> {
  static const int maxAttempts = 10;
  static const int pinLength = 6;

  final Ref ref;

  PinNotifier(this.ref) : super(PinState());

  void setFailedAttempts(int failedAttempts) {
    state = state.copyWith(
      failedAttempts: failedAttempts,
    );
  }

  void addDigit(String digit) {
    if (state.pin.length < pinLength) {
      state = state.copyWith(
        pin: state.pin + digit,
      );
    }
  }

  void removeDigit() {
    if (state.pin.isNotEmpty) {
      state = state.copyWith(
        pin: state.pin.substring(0, state.pin.length - 1),
      );
    }
  }

  void clear() {
    state = PinState();
  }

  Future<bool> validatePin() async {
    if (state.pin.length != pinLength) {
      state = state.copyWith(
        pin: '',
        isError: true,
        errorMessage: 'PIN must be $pinLength digits',
      );
      return false;
    }

    final storage = ref.read(secureStorageProvider);
    final (currentWalletId, _) = await storage.get(StorageKeys.currentWalletId);
    if (currentWalletId == null) {
      throw Exception('No current wallet ID found');
    }

    final pin = await ref.read(pinAuthProvider.notifier).getPin();
    if (state.pin != pin) {
      final failedAttempts = state.failedAttempts + 1;
      await storage.save(
        key: StorageKeys.pinFailedAttempts,
        value: failedAttempts.toString(),
      );

      if (failedAttempts == maxAttempts) {
        await ref.read(pinAuthProvider.notifier).lock();
        state = state.copyWith(
          pin: '',
          isError: true,
          errorMessage:
              ref.read(appLocalizationsProvider).pinScreenLockedMessage,
          failedAttempts: failedAttempts,
        );
        return false;
      }

      state = state.copyWith(
        pin: '',
        isError: true,
        errorMessage: failedAttempts == 1
            ? null
            : ref
                .read(appLocalizationsProvider)
                .pinScreenFailedAttemptsMessage(maxAttempts - failedAttempts),
        failedAttempts: failedAttempts,
      );
      return false;
    }

    state =
        state.copyWith(isError: false, errorMessage: null, failedAttempts: 0);
    await storage.save(
      key: StorageKeys.pinFailedAttempts,
      value: '0',
    );

    return true;
  }
}

/// Provider exposing state for PIN screen
final pinProvider =
    StateNotifierProvider.autoDispose<PinNotifier, PinState>((ref) {
  return PinNotifier(ref);
});

class PinLockTimerNotifier extends StateNotifier<String?> {
  PinLockTimerNotifier(this.ref) : super(null) {
    _initialize();
  }

  final Ref ref;
  Timer? _timer;

  void _initialize() async {
    // Watch for PIN auth state changes
    ref.listen(pinAuthProvider, (previous, next) {
      final pinAuthState = next.asData?.value;
      if (pinAuthState == PinAuthState.locked) {
        _startTimer();
      } else {
        _stopTimer();
        state = null;
      }
    });

    // Check current state
    final pinAuthState = ref.read(pinAuthProvider).asData?.value;
    if (pinAuthState == PinAuthState.locked) {
      await _updateRemainingTime();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _updateRemainingTime();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '00:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _updateRemainingTime() async {
    final remaining =
        await ref.read(pinAuthProvider.notifier).getRemainingLockTime();
    logger.debug('PinLockTimer: remaining time = $remaining');
    if (remaining == null || remaining == Duration.zero) {
      state = null;
      _stopTimer();
      // Reset PIN state to clear failed attempts
      ref.read(pinProvider.notifier).clear();
      // Trigger PIN auth state refresh to unlock
      ref.invalidate(pinAuthProvider);
      return;
    }
    state = _formatDuration(remaining);
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// Provider exposing remaining lock time with periodic updates
final pinLockTimerProvider =
    StateNotifierProvider.autoDispose<PinLockTimerNotifier, String?>((ref) {
  return PinLockTimerNotifier(ref);
});
