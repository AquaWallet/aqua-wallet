import 'dart:async';

import 'package:aqua/features/pin/models/pin_state.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/data/data.dart';

enum PinAuthState { enabled, disabled, locked }

class PinAuthNotifier extends AsyncNotifier<PinAuthState> {
  @override
  FutureOr<PinAuthState> build() async {
    state = const AsyncValue.loading();
    final pin = await getPin();
    if (pin == null) {
      state = const AsyncData(PinAuthState.disabled);
      return PinAuthState.disabled;
    }

    final (lockedAt, _) =
        await ref.read(secureStorageProvider).get(StorageKeys.pinLockedAt);

    if (lockedAt != null && await tryUnlock() == false) {
      state = const AsyncData(PinAuthState.locked);
      return PinAuthState.locked;
    }

    if (state.valueOrNull != null) {
      return state.value!;
    }

    state = const AsyncData(PinAuthState.enabled);
    return PinAuthState.enabled;
  }

  Future<String?> getPin() async {
    final (pin, _) = await ref.read(secureStorageProvider).get(StorageKeys.pin);
    return pin;
  }

  lock() async {
    await ref.read(secureStorageProvider).save(
        key: StorageKeys.pinLockedAt, value: DateTime.now().toIso8601String());
    state = const AsyncData(PinAuthState.locked);
  }

  Future<bool?> tryUnlock() async {
    final (lockedAt, _) =
        await ref.read(secureStorageProvider).get(StorageKeys.pinLockedAt);
    if (lockedAt != null) {
      final lockedAtDateTime = DateTime.parse(lockedAt);
      final isExpired = DateTime.now().difference(lockedAtDateTime) >=
          const Duration(minutes: 10);
      if (isExpired) {
        await ref
            .read(secureStorageProvider)
            .delete(StorageKeys.pinFailedAttempts);
        await ref.read(secureStorageProvider).delete(StorageKeys.pinLockedAt);
        state = const AsyncData(PinAuthState.enabled);
        return true;
      }

      return false;
    }

    return null;
  }

  disable() async {
    await ref.read(secureStorageProvider).delete(StorageKeys.pin);
    await ref.read(secureStorageProvider).delete(StorageKeys.pinFailedAttempts);
    await ref.read(secureStorageProvider).delete(StorageKeys.pinLockedAt);
    state = const AsyncData(PinAuthState.disabled);
  }

  setPin(String pin) async {
    if (await getPin() != null) {
      throw Exception("PIN already persisted");
    }

    await ref
        .read(secureStorageProvider)
        .save(key: StorageKeys.pin, value: pin);

    state = const AsyncData(PinAuthState.enabled);
  }
}

/// The main provider holding:
/// - PIN feature state: enabled, disabled, locked
/// - methods to set, retrieve, disable, lock PIN
final pinAuthProvider =
    AsyncNotifierProvider<PinAuthNotifier, PinAuthState>(PinAuthNotifier.new);

class PinNotifier extends StateNotifier<PinState> {
  static const int maxAttempts = 10;
  static const int pinLength = 6;

  PinNotifier(this.ref) : super(PinState());

  final Ref ref;

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

    final pin = await ref.read(pinAuthProvider.notifier).getPin();
    if (state.pin != pin) {
      final failedAttempts = state.failedAttempts + 1;
      await ref.read(secureStorageProvider).save(
          key: StorageKeys.pinFailedAttempts, value: failedAttempts.toString());

      if (failedAttempts == maxAttempts) {
        await ref.read(pinAuthProvider.notifier).lock();
        state = state.copyWith(
            pin: '',
            isError: true,
            errorMessage:
                ref.read(appLocalizationsProvider).pinScreenLockedMessage,
            failedAttempts: failedAttempts);

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
          failedAttempts: failedAttempts);

      return false;
    }

    state =
        state.copyWith(isError: false, errorMessage: null, failedAttempts: 0);

    await ref
        .read(secureStorageProvider)
        .save(key: StorageKeys.pinFailedAttempts, value: 0.toString());

    return true;
  }
}

/// Provider exposing state for PIN screen
final pinProvider =
    StateNotifierProvider.autoDispose<PinNotifier, PinState>((ref) {
  return PinNotifier(ref);
});
