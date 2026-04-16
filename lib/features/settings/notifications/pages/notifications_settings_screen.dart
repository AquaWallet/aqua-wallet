import 'package:aqua/features/notifications/notifications_service.dart';
import 'package:aqua/features/notifications/notifications_service_model.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

class NotificationsSettingsScreen extends HookConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  static const routeName = '/notificationsSettingsScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTransactionNotificationsEnabled = ref.watch(prefsProvider.select(
        (p) => p.isNotificationsSettingsEnabled(
            NotificationChannelType.transaction)));

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.notificationsSettingsScreenTitle,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //ANCHOR - Transaction Notifications
                AquaListItem(
                  iconLeading: AquaIcon.notification(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaToggle(
                    value: isTransactionNotificationsEnabled,
                    trackColor: context.aquaColors.surfaceSecondary,
                  ),
                  title: context.loc.transactionNotificationsToggle,
                  subtitle: context.loc.transactionNotificationsDescription,
                  onTap: () async {
                    await ref.read(notificationsServiceProvider).toggleSettings(
                          NotificationChannelType.transaction,
                        );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
