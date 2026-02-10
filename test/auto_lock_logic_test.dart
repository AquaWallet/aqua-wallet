import 'package:aqua/config/constants/pref_keys.dart';
import 'package:aqua/config/router/go_router.dart';
import 'package:aqua/features/auth/auth.dart';
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/providers/auto_lock_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

// Mock classes
class MockGoRouter extends Mock implements GoRouter {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockBuildContext extends Mock implements BuildContext {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MockBuildContext';
  }
}

void main() {
  group('AutoLockService Tests', () {
    late MockGoRouter mockRouter;
    late MockLocalAuthentication mockLocalAuth;
    late SharedPreferences mockPrefs;
    late ProviderContainer container;
    late AutoLockService autoLockService;

    setUpAll(() {
      registerFallbackValue(CheckPinScreenArguments());
      registerFallbackValue(const AuthenticationOptions());
    });

    setUp(() async {
      mockRouter = MockGoRouter();
      mockLocalAuth = MockLocalAuthentication();

      // Set up SharedPreferences with default values
      SharedPreferences.setMockInitialValues({
        PrefKeys.autoLockAfter: AutoLockOption.tenMinutes.value,
        PrefKeys.biometric: false,
      });
      mockPrefs = await SharedPreferences.getInstance();

      // Set up default mock behaviors
      when(() => mockRouter.push(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async => true);
      when(() => mockLocalAuth.canCheckBiometrics)
          .thenAnswer((_) async => true);
      when(() => mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      container = createContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
          routerProvider.overrideWithValue(mockRouter),
          localAuthProvider.overrideWithValue(mockLocalAuth),
          // Mock authDepsProvider with a simple value
          authDepsProvider.overrideWithValue(const AsyncValue.data(AuthDepsData(
            pinState: PinAuthState.enabled,
            canAuthenticateWithBiometric: false,
          ))),
        ],
      );

      autoLockService = container.read(autoLockProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('shouldLockApp method', () {
      test('should return true when AutoLockOption.always is set', () {
        // Act
        final result = autoLockService.shouldLockApp(AutoLockOption.always, 1);

        // Assert
        expect(result, isTrue);
      });

      test(
          'should return false when time elapsed is less than auto lock setting',
          () {
        // Act
        final result =
            autoLockService.shouldLockApp(AutoLockOption.tenMinutes, 5);

        // Assert
        expect(result, isFalse);
      });

      test('should return true when time elapsed equals auto lock setting', () {
        // Act
        final result =
            autoLockService.shouldLockApp(AutoLockOption.tenMinutes, 10);

        // Assert
        expect(result, isTrue);
      });

      test('should return true when time elapsed exceeds auto lock setting',
          () {
        // Act
        final result =
            autoLockService.shouldLockApp(AutoLockOption.tenMinutes, 15);

        // Assert
        expect(result, isTrue);
      });

      test('should work correctly with different AutoLockOption values', () {
        // Test thirtyMinutes
        expect(autoLockService.shouldLockApp(AutoLockOption.thirtyMinutes, 25),
            isFalse);
        expect(autoLockService.shouldLockApp(AutoLockOption.thirtyMinutes, 30),
            isTrue);
        expect(autoLockService.shouldLockApp(AutoLockOption.thirtyMinutes, 35),
            isTrue);

        // Test fortyFiveMinutes
        expect(
            autoLockService.shouldLockApp(AutoLockOption.fortyFiveMinutes, 40),
            isFalse);
        expect(
            autoLockService.shouldLockApp(AutoLockOption.fortyFiveMinutes, 45),
            isTrue);
        expect(
            autoLockService.shouldLockApp(AutoLockOption.fortyFiveMinutes, 50),
            isTrue);

        // Test sixtyMinutes
        expect(autoLockService.shouldLockApp(AutoLockOption.sixtyMinutes, 50),
            isFalse);
        expect(autoLockService.shouldLockApp(AutoLockOption.sixtyMinutes, 60),
            isTrue);
        expect(autoLockService.shouldLockApp(AutoLockOption.sixtyMinutes, 70),
            isTrue);
      });

      test('should handle edge cases correctly', () {
        // Zero minutes
        expect(autoLockService.shouldLockApp(AutoLockOption.tenMinutes, 0),
            isFalse);

        // Negative minutes (clock changes)
        expect(autoLockService.shouldLockApp(AutoLockOption.tenMinutes, -1),
            isFalse);
      });
    });

    group('isPinEnabled method', () {
      test('should return true when PIN is enabled', () {
        // Arrange
        const authDeps = AsyncValue.data(AuthDepsData(
          pinState: PinAuthState.enabled,
          canAuthenticateWithBiometric: false,
        ));

        // Act
        final result = autoLockService.isPinEnabled(authDeps);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when PIN is disabled', () {
        // Arrange
        const authDeps = AsyncValue.data(AuthDepsData(
          pinState: PinAuthState.disabled,
          canAuthenticateWithBiometric: false,
        ));

        // Act
        final result = autoLockService.isPinEnabled(authDeps);

        // Assert
        expect(result, isFalse);
      });

      test('should return true when PIN is locked', () {
        // Arrange
        const authDeps = AsyncValue.data(AuthDepsData(
          pinState: PinAuthState.locked,
          canAuthenticateWithBiometric: false,
        ));

        // Act
        final result = autoLockService.isPinEnabled(authDeps);

        // Assert
        expect(result, isTrue);
      });
    });

    group('handleAppResume method', () {
      test('should do nothing when backgroundStartTime is null', () async {
        // Act
        await autoLockService.handleAppResume(
          backgroundStartTime: null,
        );

        // Assert
        verifyNever(() => mockRouter.push(any(), extra: any(named: 'extra')));
      });

      test('should not trigger auth when shouldLock is false', () async {
        // Arrange
        final backgroundStartTime =
            DateTime.now().subtract(const Duration(minutes: 5));

        // Act
        await autoLockService.handleAppResume(
          backgroundStartTime: backgroundStartTime,
        );

        // Assert
        verifyNever(() => mockRouter.push(CheckPinScreen.routeName,
            extra: any(named: 'extra')));
      });

      test('should trigger PIN auth when PIN is enabled', () async {
        // Arrange
        await mockPrefs.setBool(PrefKeys.biometric, false);
        final backgroundStartTime =
            DateTime.now().subtract(const Duration(minutes: 15));

        // Recreate container with PIN enabled and biometric disabled
        container = createContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            routerProvider.overrideWithValue(mockRouter),
            localAuthProvider.overrideWithValue(mockLocalAuth),
            authDepsProvider
                .overrideWithValue(const AsyncValue.data(AuthDepsData(
              pinState: PinAuthState.enabled,
              canAuthenticateWithBiometric: false,
            ))),
          ],
        );

        autoLockService = container.read(autoLockProvider);

        // Act
        await autoLockService.handleAppResume(
          backgroundStartTime: backgroundStartTime,
        );

        // Assert
        verify(() => mockRouter.push(
              CheckPinScreen.routeName,
              extra: any(named: 'extra'),
            )).called(1);
      });

      test('should not trigger auth when PIN is disabled', () async {
        // Arrange
        await mockPrefs.setBool(PrefKeys.biometric, false);
        final backgroundStartTime =
            DateTime.now().subtract(const Duration(minutes: 15));

        // Recreate container with PIN disabled
        container = createContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            routerProvider.overrideWithValue(mockRouter),
            localAuthProvider.overrideWithValue(mockLocalAuth),
            authDepsProvider
                .overrideWithValue(const AsyncValue.data(AuthDepsData(
              pinState: PinAuthState.disabled,
              canAuthenticateWithBiometric: false,
            ))),
          ],
        );

        autoLockService = container.read(autoLockProvider);

        // Act
        await autoLockService.handleAppResume(
          backgroundStartTime: backgroundStartTime,
        );

        // Assert
        verifyNever(() => mockRouter.push(CheckPinScreen.routeName,
            extra: any(named: 'extra')));
      });

      test('should respect AutoLockOption.always setting', () async {
        // Arrange
        await mockPrefs.setInt(
            PrefKeys.autoLockAfter, AutoLockOption.always.value);
        final backgroundStartTime =
            DateTime.now().subtract(const Duration(seconds: 1));

        // Recreate container with updated settings
        container = createContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockPrefs),
            routerProvider.overrideWithValue(mockRouter),
            localAuthProvider.overrideWithValue(mockLocalAuth),
            authDepsProvider
                .overrideWithValue(const AsyncValue.data(AuthDepsData(
              pinState: PinAuthState.enabled,
              canAuthenticateWithBiometric: false,
            ))),
          ],
        );

        autoLockService = container.read(autoLockProvider);

        // Act
        await autoLockService.handleAppResume(
          backgroundStartTime: backgroundStartTime,
        );

        // Assert
        verify(() => mockRouter.push(
              CheckPinScreen.routeName,
              extra: any(named: 'extra'),
            )).called(1);
      });
    });

    group('AutoLockOption values', () {
      test('should have correct values', () {
        expect(AutoLockOption.always.value, equals(0));
        expect(AutoLockOption.tenMinutes.value, equals(10));
        expect(AutoLockOption.thirtyMinutes.value, equals(30));
        expect(AutoLockOption.fortyFiveMinutes.value, equals(45));
        expect(AutoLockOption.sixtyMinutes.value, equals(60));
      });
    });
  });
}
