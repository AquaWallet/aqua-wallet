import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class RecoveryPhraseWidget extends ConsumerWidget {
  const RecoveryPhraseWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Text(
          context.loc.backupRecoveryPhraseTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 1,
                height: 1.2,
              ),
        ),
        SizedBox(height: 18.h),
        Text(
          context.loc.backupRecoveryPhraseSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                letterSpacing: .15,
                height: 1.2,
                fontWeight: FontWeight.w400,
              ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 36.h),
          child: const WalletBackupMnemonicWords(),
        ),
      ],
    );
  }
}
