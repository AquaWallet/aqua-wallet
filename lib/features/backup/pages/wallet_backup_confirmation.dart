import 'package:aqua/common/common.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class WalletBackupConfirmation extends ConsumerWidget {
  static const routeName = '/walletBackupConfirmation';

  const WalletBackupConfirmation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      walletBackupConfirmationResultProvider,
      (_, asyncValue) => asyncValue?.when(
          data: (_) {
            AquaModalSheet.show(
              context,
              title: context.loc.backupVerifiedTitle,
              message: context.loc.backupVerifiedDescription,
              primaryButtonText: context.loc.backupVerifiedButton,
              onPrimaryButtonTap: () {
                Navigator.of(context).pop(); // Close modal
                context.go(AuthWrapper.routeName);
              },
              icon: AquaIcon.checkCircle(
                color: context.aquaColors.textInverse,
              ),
              iconVariant: AquaRingedIconVariant.info,
              colors: context.aquaColors,
              copiedToClipboardText: context.loc.copiedToClipboard,
            );
          },
          loading: () => showLoadingDialog(
                context,
                context.loc.backupInviteLoadingIndicator,
              ),
          error: (e, _) {
            AquaModalSheet.show(
              context,
              title: context.loc.backupIncorrectWordsTitle,
              message: context.loc.backupIncorrectWordsDescription,
              primaryButtonText: context.loc.backupIncorrectWordsTryAgain,
              onPrimaryButtonTap: () {
                Navigator.of(context).pop();
              },
              secondaryButtonText: context.loc.backupLater,
              onSecondaryButtonTap: () {
                Navigator.of(context).pop();
                context.go(AuthWrapper.routeName);
              },
              icon: AquaIcon.warning(
                color: context.aquaColors.textInverse,
              ),
              iconVariant: AquaRingedIconVariant.warning,
              colors: context.aquaColors,
              copiedToClipboardText: context.loc.copiedToClipboard,
            );
          }),
    );

    return Scaffold(
      appBar: AquaTopAppBar(
        title: context.loc.backupConfirmationTitle,
        colors: context.aquaColors,
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: WalletBackupConfirmationContent(),
        ),
      ),
    );
  }
}
