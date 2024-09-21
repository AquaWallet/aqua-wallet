import 'package:aqua/config/config.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/recovery/providers/seed_qr_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletRecoveryQRScreen extends HookConsumerWidget {
  static const routeName = '/walletRecoveryQRScreen';

  const WalletRecoveryQRScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryPhrase = ref.watch(recoveryPhraseWordsProvider).asData?.value;

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              Text(
                context.loc.backupRecoveryPhraseQRTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 1,
                      height: 1.2,
                    ),
              ),
              SizedBox(height: 18.h),
              Text(
                context.loc.backupRecoveryPhraseQRSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      letterSpacing: .15,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              Expanded(
                child: Center(
                  child: Builder(
                    builder: (context) {
                      final qrCode = ref
                          .read(seedQrProvider.notifier)
                          .generateQRCodeFromSeedList(recoveryPhrase);
                      if (recoveryPhrase == null || qrCode.isEmpty) {
                        return const CircularProgressIndicator();
                      }
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 9.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: SizedBox.square(
                          child: QrImageView(
                            data: qrCode,
                            version: QrVersions.auto,
                            size: 200.r,
                          ),
                        ),
                      );
                    },
                  ),
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
