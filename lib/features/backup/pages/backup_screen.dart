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
          Navigator.of(context)
              .pushReplacementNamed(WalletRecoveryPhraseScreen.routeName);
        }
      },
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.r,
        onActionButtonPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4.h),
              SvgPicture.asset(
                Svgs.backupWallet,
                width: 55.w,
                height: 61.h,
              ),
              SizedBox(height: 43.h),
              Text(
                context.loc.backupInviteTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20.h),
              Text(
                context.loc.backupInviteDescription,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 16.sp,
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
              SizedBox(height: 30.h),
              AquaElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.loc.backupInviteButtonLater,
                ),
              ),
              SizedBox(height: 66.h),
            ],
          ),
        ),
      ),
    );
  }
}
