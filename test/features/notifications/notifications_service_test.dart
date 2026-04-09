import 'package:aqua/config/constants/pref_keys.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/localization_provider.dart';
import 'package:aqua/features/notifications/notifications_service.dart';
import 'package:aqua/features/notifications/notifications_service_model.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/prefs_provider_mocks.dart';

// Simple spy class that tracks calls
class SpyNotificationsService extends NotificationsService {
  SpyNotificationsService(super.ref);

  final List<Map<String, dynamic>> showNotificationCalls = [];
  int requestPermissionsCallCount = 0;
  bool mockPermissionsResult = true;

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channelType,
    String? payload,
  }) async {
    showNotificationCalls.add({
      'id': id,
      'title': title,
      'body': body,
      'channelType': channelType,
      'payload': payload,
    });
  }

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCallCount++;
    return mockPermissionsResult;
  }

  void setMockPermissionsResult(bool result) {
    mockPermissionsResult = result;
  }

  void clearCalls() {
    showNotificationCalls.clear();
    requestPermissionsCallCount = 0;
  }
}

// Mock class for AppLocalizations
class MockAppLocalizations extends Mock implements AppLocalizations {}

// Mock class for ProviderRef
class MockProviderRef extends Mock implements ProviderRef {}

// Fake class for AlwaysAliveProviderListenable
class FakeProviderListenable extends Fake
    implements AlwaysAliveProviderListenable<Object?> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(NotificationChannelType.transaction);
    registerFallbackValue(const GdkTransactionEvent(
      txhash: 'fallback',
      type: GdkTransactionEventEnum.incoming,
      satoshi: 0,
      subaccounts: [0],
    ));
    registerFallbackValue(FakeProviderListenable());
  });

  group('NotificationsService', () {
    late ProviderContainer container;
    late SpyNotificationsService spyService;
    late MockProviderRef mockRef;
    late MockUserPreferencesNotifier mockPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final sharedPrefs = await SharedPreferences.getInstance();

      final mockLocalizations = MockAppLocalizations();
      when(() => mockLocalizations.notificationsTransactionTitle)
          .thenReturn('Transaction');
      when(() => mockLocalizations.notificationsTransactionBody)
          .thenReturn('You received a transaction');

      // Create mock preferences notifier
      mockPrefs = MockUserPreferencesNotifier();

      // Mock the setNotificationsSettings method to return a Future
      when(() => mockPrefs.setNotificationsSettings(
            type: any(named: 'type'),
            enabled: any(named: 'enabled'),
          )).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          appLocalizationsProvider.overrideWithValue(mockLocalizations),
        ],
      );

      // Setup mock ref to return the providers
      mockRef = MockProviderRef();
      when(() => mockRef.read(sharedPreferencesProvider))
          .thenReturn(sharedPrefs);
      when(() => mockRef.read(appLocalizationsProvider))
          .thenReturn(mockLocalizations);
      when(() => mockRef.read(prefsProvider)).thenReturn(mockPrefs);
      when(() => mockRef.read(prefsProvider.notifier)).thenReturn(mockPrefs);

      spyService = SpyNotificationsService(mockRef);
    });

    tearDown(() {
      container.dispose();
    });

    group('showTransactionNotification', () {
      late GdkTransactionEvent testTransactionEvent;

      setUp(() {
        testTransactionEvent = const GdkTransactionEvent(
          txhash: 'test_tx_hash_123',
          type: GdkTransactionEventEnum.incoming,
          satoshi: 100000,
          subaccounts: [1],
        );
        when(() => mockRef.read(networkTransactionsLookupProvider.future))
            .thenAnswer((_) => Future.value({
                  'test_tx_hash_123': const TransactionLookupModel(
                      assetId: '',
                      gdkTransaction: GdkTransaction(
                          txhash: 'test_tx_hash_123',
                          type: GdkTransactionTypeEnum.incoming))
                }));

        spyService.clearCalls();
      });

      test(
          'should NOT call showNotification when transaction notifications are disabled by default',
          () async {
        final sharedPrefs = container.read(sharedPreferencesProvider);
        expect(sharedPrefs.getBool(PrefKeys.transactionNotifications), isNull);

        await spyService.showTransactionNotification(testTransactionEvent);

        expect(spyService.showNotificationCalls, isEmpty);
      });

      test(
          'should NOT call showNotification when transaction notifications are explicitly disabled',
          () async {
        final sharedPrefs = container.read(sharedPreferencesProvider);
        await sharedPrefs.setBool(PrefKeys.transactionNotifications, false);

        await spyService.showTransactionNotification(testTransactionEvent);

        expect(spyService.showNotificationCalls, isEmpty);
      });

      test(
          'should NOT call showNotification when transaction notifications are enabled and transaction is not incoming',
          () async {
        testTransactionEvent = const GdkTransactionEvent(
          txhash: 'test_tx_hash_123',
          type: GdkTransactionEventEnum.outgoing,
          satoshi: 100000,
          subaccounts: [1],
        );
        when(() => mockRef.read(networkTransactionsLookupProvider.future))
            .thenAnswer((_) => Future.value({
                  'test_tx_hash_123': const TransactionLookupModel(
                      assetId: '',
                      gdkTransaction: GdkTransaction(
                          txhash: 'test_tx_hash_123',
                          type: GdkTransactionTypeEnum.outgoing))
                }));

        final sharedPrefs = container.read(sharedPreferencesProvider);
        await sharedPrefs.setBool(PrefKeys.transactionNotifications, true);

        await spyService.showTransactionNotification(testTransactionEvent);

        expect(spyService.showNotificationCalls, isEmpty);
      });

      test(
          'should call showNotification when transaction notifications are enabled and transaction is incoming',
          () async {
        final sharedPrefs = container.read(sharedPreferencesProvider);
        await sharedPrefs.setBool(PrefKeys.transactionNotifications, true);

        await spyService.showTransactionNotification(testTransactionEvent);

        expect(spyService.showNotificationCalls, hasLength(1));

        final call = spyService.showNotificationCalls.first;
        expect(call['id'], equals(testTransactionEvent.txhash.hashCode));
        expect(call['title'], equals('Transaction'));
        expect(call['body'], equals('You received a transaction'));
        expect(
            call['channelType'], equals(NotificationChannelType.transaction));
        expect(call['payload'], equals(testTransactionEvent.txhash));
      });
    });

    group('toggleSettings', () {
      setUp(() {
        spyService.clearCalls();
      });

      test('should call requestPermissions when enabling notifications',
          () async {
        // Arrange - mock current state as disabled
        when(() => mockPrefs.isNotificationsSettingsEnabled(
            NotificationChannelType.transaction)).thenReturn(false);

        // Act
        await spyService.toggleSettings(NotificationChannelType.transaction);

        // Assert - requestPermissions should be called once
        expect(spyService.requestPermissionsCallCount, equals(1));

        // Verify setNotificationsSettings was called with enabled=true
        verify(() => mockPrefs.setNotificationsSettings(
              type: NotificationChannelType.transaction,
              enabled: true,
            )).called(1);
      });

      test('should NOT call requestPermissions when disabling notifications',
          () async {
        // Arrange - mock current state as enabled
        when(() => mockPrefs.isNotificationsSettingsEnabled(
            NotificationChannelType.transaction)).thenReturn(true);

        // Act
        await spyService.toggleSettings(NotificationChannelType.transaction);

        // Assert - requestPermissions should NOT be called
        expect(spyService.requestPermissionsCallCount, equals(0));

        // Verify setNotificationsSettings was called with enabled=false
        verify(() => mockPrefs.setNotificationsSettings(
              type: NotificationChannelType.transaction,
              enabled: false,
            )).called(1);
      });

      test('should NOT update settings when permissions are denied', () async {
        // Arrange - mock current state as disabled, permissions will be denied
        when(() => mockPrefs.isNotificationsSettingsEnabled(
            NotificationChannelType.transaction)).thenReturn(false);
        spyService.setMockPermissionsResult(false);

        // Act
        await spyService.toggleSettings(NotificationChannelType.transaction);

        // Assert - requestPermissions should be called
        expect(spyService.requestPermissionsCallCount, equals(1));

        // Verify setNotificationsSettings was NOT called
        verifyNever(() => mockPrefs.setNotificationsSettings(
              type: NotificationChannelType.transaction,
              enabled: any(named: 'enabled'),
            ));
      });

      test('should update settings when permissions are granted', () async {
        // Arrange - mock current state as disabled, permissions will be granted
        when(() => mockPrefs.isNotificationsSettingsEnabled(
            NotificationChannelType.transaction)).thenReturn(false);
        spyService.setMockPermissionsResult(true);

        // Act
        await spyService.toggleSettings(NotificationChannelType.transaction);

        // Assert - requestPermissions should be called
        expect(spyService.requestPermissionsCallCount, equals(1));

        // Verify setNotificationsSettings was called with enabled=true
        verify(() => mockPrefs.setNotificationsSettings(
              type: NotificationChannelType.transaction,
              enabled: true,
            )).called(1);
      });
    });
  });
}
