import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/recovery/providers/seed_qr_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/screens/qrscanner/qr_scanner_screen.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WalletRestoreInputScreen extends HookConsumerWidget {
  static const routeName = '/walletRestoreInput';

  const WalletRestoreInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = useState(false);

    final onScan = useCallback(() async {
      final result = await Navigator.of(context).pushNamed(
        QrScannerScreen.routeName,
        arguments: QrScannerScreenArguments(
          asset: null,
          parseAction: QrScannerParseAction.doNotParse,
          onSuccessAction: QrOnSuccessAction.pull,
        ),
      ) as String?;

      logger.d("[Restore][Input] scanned input: $result");

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
            Navigator.of(context).popUntil((route) => route is! RawDialogRoute);
          },
          orElse: () {},
        );
      },
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        onBackPressed: () {
          ref.read(systemOverlayColorProvider(context)).aqua();
          Navigator.of(context).pop();
        },
        actionButtonAsset: Svgs.qr,
        actionButtonIconSize: 13.r,
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
