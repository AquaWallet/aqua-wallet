import 'package:aqua/common/widgets/loading_dialog.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class WalletBackupConfirmation extends ConsumerWidget {
  static const routeName = '/walletBackupConfirmation';

  const WalletBackupConfirmation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      walletBackupConfirmationResultProvider,
      (_, asyncValue) => asyncValue?.when(
        data: (_) => Navigator.of(context).popUntil((route) => route.isFirst),
        loading: () => showLoadingDialog(
          context,
          context.loc.backupInviteLoadingIndicator,
        ),
        error: (e, _) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              WalletBackupConfirmationFailure.routeName,
              (route) =>
                  route is! RawDialogRoute &&
                  route.settings.name != WalletBackupConfirmation.routeName);
        },
      ),
    );

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: const WalletBackupConfirmationContent(),
        ),
      ),
    );
  }
}
