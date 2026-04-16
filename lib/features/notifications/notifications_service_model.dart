import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_service_model.freezed.dart';

enum NotificationChannelType {
  transaction,
}

@freezed
class NotificationChannelConfig with _$NotificationChannelConfig {
  const factory NotificationChannelConfig({
    required String id,
    required String name,
    required String description,
    @Default(Importance.high) Importance importance,
    @Default(Priority.high) Priority priority,
    @Default(true) bool enableVibration,
    @Default(true) bool enableLights,
  }) = _NotificationChannelConfig;
}

class NotificationChannels {
  static const Map<NotificationChannelType, NotificationChannelConfig> configs =
      {
    NotificationChannelType.transaction: NotificationChannelConfig(
      id: 'transaction_notifications',
      name: 'Transaction Notifications',
      description: 'Notifications for incoming transactions',
    ),
  };

  static NotificationChannelConfig getConfig(NotificationChannelType type) {
    return configs[type]!;
  }
}
