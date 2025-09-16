import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/backup/providers/wallet_backup_provider.dart';
import 'package:coin_cz/features/recovery/providers/seed_qr_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
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
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.0,
        onActionButtonPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 16.0),
              Text(
                context.loc.backupRecoveryPhraseQRTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 1,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 18.0),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: SizedBox.square(
                          child: QrImageView(
                            data: qrCode,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                      );
                    },
                  ),
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
