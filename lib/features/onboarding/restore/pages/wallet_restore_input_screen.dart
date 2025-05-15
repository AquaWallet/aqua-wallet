import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/recovery/providers/seed_qr_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/config/config.dart';

class WalletRestoreInputScreen extends HookConsumerWidget {
  static const routeName = '/walletRestoreInput';

  const WalletRestoreInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = useState(false);

    final onScan = useCallback(() async {
      final result = await context.push(
        QrScannerScreen.routeName,
        extra: QrScannerArguments(
          asset: null,
          parseAction: QrScannerParseAction.returnRawValue,
          onSuccessAction: QrOnSuccessNavAction.popBack,
        ),
      ) as String?;

      logger.debug("[Restore][Input] scanned input: $result");

      ref.read(seedQrProvider.notifier).populateFromQrCode(result ?? '');
    });

    ref.listen(
      walletRestoreProvider,
      (_, asyncValue) {
        hasError.value = false;
        asyncValue.maybeWhen(
          loading: () => showGeneralDialog(
            context: context,
            pageBuilder: (_, __, ___) => const WalletProcessingAnimation(
              type: WalletProcessType.restore,
            ),
          ),
          error: (_, __) {
            hasError.value = true;
            context.popUntilPath(routeName);
          },
          orElse: () {},
        );
      },
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        onBackPressed: () {
          ref.read(systemOverlayColorProvider(context)).aqua();
          context.pop();
        },
        actionButtonAsset: Svgs.qr,
        actionButtonIconSize: 13.0,
        onActionButtonPressed: onScan,
      ),
      body: SafeArea(
        child: ref.watch(walletHintWordListProvider).when(
                  data: (_) => WalletRestoreInputContent(error: hasError),
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  error: (_, __) => GenericErrorWidget(
                    buttonAction: () =>
                        ref.invalidate(walletInputHintsProvider),
                  ),
                ) ??
            Container(),
      ),
    );
  }
}
