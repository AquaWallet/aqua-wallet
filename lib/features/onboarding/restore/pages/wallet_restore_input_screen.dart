import 'package:aqua/config/config.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/recovery/providers/seed_qr_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/pages/stored_wallets_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class WalletRestoreInputScreen extends HookConsumerWidget {
  static const routeName = '/walletRestoreInput';

  const WalletRestoreInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = useState(false);
    final currentPage = useState(0);
    final focusedIndex = useState(0);

    final onScan = useCallback(() async {
      final result = await context.push(
        QrScannerScreen.routeName,
        extra: QrScannerArguments(
          asset: null,
          parseAction: QrScannerParseAction.returnRawValue,
        ),
      ) as String?;

      ref.read(seedQrProvider.notifier).populateFromQrCode(result ?? '');
    });

    ref.listen(
      walletRestoreProvider,
      (prev, asyncValue) {
        hasError.value = false;
        asyncValue.maybeWhen(
          error: (error, _) {
            if (error is WalletRestoreWalletAlreadyExistsException) {
              if (context.mounted) {
                context.popUntilPath(StoredWalletsScreen.routeName);
              }
            } else {
              hasError.value = true;
              context.popUntilPath(routeName);
            }
          },
          orElse: () {},
        );
      },
    );

    return Scaffold(
      appBar: AquaTopAppBar(
        title: context.loc.restoreWallet,
        showBackButton: true,
        colors: context.aquaColors,
        actions: [
          AquaIcon.qrIcon(
            color: context.aquaColors.textPrimary,
            onTap: onScan,
          )
        ],
        onBackPressed: () {
          if (currentPage.value == 0) {
            // First page: pop the screen
            context.pop();
          } else {
            // Not first page: go to previous page
            currentPage.value = currentPage.value - 1;
            // Focus on the last field of the previous page with a small delay
            // to ensure the field is fully rendered
            const itemsPerPage = 4;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              focusedIndex.value =
                  currentPage.value * itemsPerPage + (itemsPerPage - 1);
            });
          }
        },
      ),
      body: SafeArea(
        child: ref.watch(walletHintWordListProvider).when(
                  data: (_) => WalletRestoreInputContent(
                    error: hasError,
                    currentPage: currentPage,
                    focusedIndex: focusedIndex,
                  ),
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
