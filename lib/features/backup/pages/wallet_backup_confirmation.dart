import 'package:aqua/common/common.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:aqua/config/config.dart';

class WalletBackupConfirmation extends ConsumerWidget {
  static const routeName = '/walletBackupConfirmation';

  const WalletBackupConfirmation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      walletBackupConfirmationResultProvider,
      (_, asyncValue) => asyncValue?.when(
          data: (_) => context.go(AuthWrapper.routeName),
          loading: () => showLoadingDialog(
                context,
                context.loc.backupInviteLoadingIndicator,
              ),
          error: (e, _) {
            context
              ..popUntilPath(routeName)
              ..push(WalletBackupConfirmationFailure.routeName);
          }),
    );

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: const WalletBackupConfirmationContent(),
        ),
      ),
    );
  }
}
