import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletBackupConfirmationFailure extends HookConsumerWidget {
  static const routeName = '/walletBackupConfirmationFailure';

  const WalletBackupConfirmationFailure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onRetry = useCallback(
      () => Navigator.of(context)
          .pushReplacementNamed(WalletRecoveryPhraseScreen.routeName),
      [],
    );

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        onBackPressed: onRetry,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),
              const Spacer(),
              //ANCHOR - Icon
              SvgPicture.asset(
                Svgs.failure,
                width: 60.r,
                height: 60.r,
              ),
              SizedBox(height: 20.h),
              //ANCHOR - Title
              Text(
                context.loc.backupFailureTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 20.sp,
                    ),
              ),
              SizedBox(height: 8.h),
              //ANCHOR - Description
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  context.loc.backupFailureDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                ),
              ),
              const Spacer(),
              //ANCHOR - Quit button
              AquaElevatedButton(
                child: Text(
                  context.loc.backupFailureQuitButton,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: 27.h),
              //ANCHOR - Retry button
              AquaElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(
                  context.loc.backupFailureRetryButton,
                ),
              ),
              SizedBox(height: 64.h),
            ],
          ),
        ),
      ),
    );
  }
}
