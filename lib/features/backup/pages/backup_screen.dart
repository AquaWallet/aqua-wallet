import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/backup/providers/backup_reminder_provider.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletBackupScreen extends HookConsumerWidget {
  const WalletBackupScreen({super.key});

  static const routeName = '/backupInvite';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(backupReminderProvider).setBackupFlowLastShown();
        ref.read(systemOverlayColorProvider(context)).forceLight();
      });
      return null;
    }, []);

    ref.listen(
      walletBackupNavigateToBackupPromptProvider,
      (_, action) {
        if (action != null) {
          context.pushReplacement(
            WalletRecoveryPhraseScreen.routeName,
            extra: RecoveryPhraseScreenArguments(
              isOnboarding: true,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.0,
        onActionButtonPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4.0),
              SvgPicture.asset(
                Svgs.backupWallet,
                width: 55.0,
                height: 61.0,
              ),
              const SizedBox(height: 43.0),
              Text(
                context.loc.backupInviteTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20.0),
              Text(
                context.loc.backupInviteDescription,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 16.0,
                    ),
              ),
              const Spacer(),
              AquaElevatedButton(
                onPressed: () =>
                    ref.read(walletBackupConfirmationProvider).acceptInvite(),
                child: Text(
                  context.loc.backupInviteButtonNext,
                ),
              ),
              const SizedBox(height: 30.0),
              AquaElevatedButton(
                onPressed: () => context.pop(),
                child: Text(
                  context.loc.backupInviteButtonLater,
                ),
              ),
              const SizedBox(height: 66.0),
            ],
          ),
        ),
      ),
    );
  }
}
