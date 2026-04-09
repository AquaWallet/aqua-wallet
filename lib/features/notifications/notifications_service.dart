import 'package:aqua/data/data.dart';
import 'package:aqua/features/notifications/notifications_service_model.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/config/router/go_router.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/config/constants/pref_keys.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_service.g.dart';

final _logger = CustomLogger(FeatureFlag.notifications);

class NotificationsService {
  final ProviderRef ref;

  NotificationsService(this.ref);

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<bool> requestPermissions() async {
    // For iOS
    final bool? iosResult = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // For Android (Android 13+ requires explicit permission)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final bool? androidResult =
        await androidImplementation?.requestNotificationsPermission();

    return iosResult == true || androidResult == true;
  }

  Future<void> toggleSettings(NotificationChannelType type) async {
    final currentState =
        ref.read(prefsProvider).isNotificationsSettingsEnabled(type);
    final nextState = !currentState;

    if (nextState == true) {
      // Request permissions
      final granted = await requestPermissions();

      _logger.debug('Notification permissions granted: $granted');

      if (!granted) {
        return;
      }
    }

    ref.read(prefsProvider.notifier).setNotificationsSettings(
          type: type,
          enabled: nextState,
        );
  }

  Future<void> _createNotificationChannel(
      NotificationChannelConfig config) async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      config.id,
      config.name,
      description: config.description,
      importance: config.importance,
      enableVibration: config.enableVibration,
      enableLights: config.enableLights,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> createAllNotificationChannels() async {
    for (final config in NotificationChannels.configs.values) {
      await _createNotificationChannel(config);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channelType,
    String? payload,
  }) async {
    final config = NotificationChannels.getConfig(channelType);
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      config.id,
      config.name,
      channelDescription: config.description,
      importance: config.importance,
      priority: config.priority,
      enableVibration: config.enableVibration,
      icon: '@mipmap/launcher_icon',
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _logger.debug('Show notification with id: $id');
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Safely checks if a specific notification type is enabled
  bool _isNotificationEnabled(NotificationChannelType type) {
    final prefs = ref.read(sharedPreferencesProvider);

    switch (type) {
      case NotificationChannelType.transaction:
        return prefs.getBool(PrefKeys.transactionNotifications) ?? false;
    }
  }

  Future<void> showTransactionNotification(
      GdkTransactionEvent transactionEvent) async {
    // Check if transaction notifications are enabled
    if (!_isNotificationEnabled(NotificationChannelType.transaction)) {
      return; // Don't show notification if disabled
    }

    final transaction = await retryAsync(
      () async {
        final txsLookup =
            await ref.read(networkTransactionsLookupProvider.future);
        return txsLookup[transactionEvent.txhash];
      },
      (tx) => tx != null,
      3, // maxRetries
      const Duration(seconds: 2), // delay
    );

    if (transaction == null) {
      _logger.error(
          'Transaction not found in network transactions after retries: ${transactionEvent.txhash}');
      return;
    }

    if (transaction.gdkTransaction.type != GdkTransactionTypeEnum.incoming) {
      return;
    }

    final notificationTitle =
        ref.read(appLocalizationsProvider).notificationsTransactionTitle;
    final notificationBody =
        ref.read(appLocalizationsProvider).notificationsTransactionBody;

    showNotification(
      channelType: NotificationChannelType.transaction,
      id: transactionEvent.txhash.hashCode,
      title: notificationTitle,
      body: notificationBody,
      payload: transactionEvent.txhash, // Include transaction hash in payload
    );
  }

  Future<void> cancelNotification(int id) async {
    _logger.debug('Cancel notification with id: $id');
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  void _onNotificationTapped(NotificationResponse response) async {
    _logger.debug('Notification tapped: ${response.payload}');

    final txHash = response.payload;
    if (txHash == null || txHash.isEmpty) {
      _logger.error('No transaction hash in notification payload');
      return;
    }

    final txsLookup = await ref.read(networkTransactionsLookupProvider.future);
    final transaction = txsLookup[txHash];

    if (transaction == null) {
      _logger.error('Transaction not found in network transactions: $txHash');
      return;
    }

    final allSupportedAssets = ref.read(assetsProvider).asData?.value ?? [];
    final transactionAsset = allSupportedAssets
        .firstWhere((asset) => asset.id == transaction.assetId);

    // Navigate to the transaction details screen
    ref.read(routerProvider).push(
          AssetTransactionDetailsScreen.routeName,
          extra: TransactionDetailsArgs(
            transactionId: txHash,
            asset: transactionAsset,
          ),
        );
  }
}

@riverpod
NotificationsService notificationsService(NotificationsServiceRef ref) {
  return NotificationsService(ref);
}
