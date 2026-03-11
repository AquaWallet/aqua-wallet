import 'package:aqua/config/config.dart' hide AquaColors;
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class WalletRestoreReviewScreen extends HookConsumerWidget {
  const WalletRestoreReviewScreen({
    super.key,
  });

  static const routeName = '/wallet-restore-review';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = useState(false);

    final mnemonicWords = List.generate(
      kMnemonicLength,
      (i) => ref
          .watch(mnemonicWordInputStateProvider(i))
          .text
          .trim()
          .toLowerCase(),
    );

    //ANCHOR - Listen for restore state changes
    ref.listen(
      walletRestoreProvider,
      (prev, asyncValue) {
        hasError.value = false;
        asyncValue.maybeWhen(
          data: (needsWalletName) {
            if (prev?.isLoading == true &&
                !needsWalletName &&
                context.mounted) {
              Navigator.of(context).pop();
            }
          },
          error: (error, _) {
            if (error is! WalletRestoreWalletAlreadyExistsException) {
              hasError.value = true;
              context.popUntilPath(routeName);
            }
          },
          orElse: () {},
        );
      },
    );

    //ANCHOR - Listen for wallet name input requirement
    ref.listen(walletRestoreProvider, (prev, state) async {
      state.whenData((needsWalletName) async {
        if (needsWalletName) {
          // Collect mnemonic from input fields
          final mnemonic = mnemonicWords.join(' ');

          // Navigate to wallet name input screen
          final walletName =
              await context.push(EditWalletScreen.routeName) as String?;
          if (walletName != null && context.mounted) {
            await ref
                .read(walletRestoreProvider.notifier)
                .handleWalletNameInput(mnemonic, walletName);
          }
        }
      });
    });

    return Scaffold(
      appBar: AquaTopAppBar(
        title: context.loc.restoreWallet,
        showBackButton: true,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: Column(
          children: [
            //ANCHOR - Error Header
            if (hasError.value) ...{
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AquaText.body1SemiBold(
                  text: context.loc.restoreInputError,
                  color: context.aquaColors.accentDanger,
                ),
              ),
            },
            //ANCHOR - Mnemonic words list
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: mnemonicWords.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    color: context.aquaColors.surfaceBackground,
                  ),
                  itemBuilder: (context, index) {
                    final isFirst = index == 0;
                    final isLast = index == mnemonicWords.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        color: context.aquaColors.surfacePrimary,
                        borderRadius: BorderRadius.only(
                          topLeft:
                              isFirst ? const Radius.circular(8) : Radius.zero,
                          topRight:
                              isFirst ? const Radius.circular(8) : Radius.zero,
                          bottomLeft:
                              isLast ? const Radius.circular(8) : Radius.zero,
                          bottomRight:
                              isLast ? const Radius.circular(8) : Radius.zero,
                        ),
                      ),
                      child: AquaSeedListItem(
                        index: index + 1,
                        text: mnemonicWords[index],
                        colors: context.aquaColors,
                        showBackground: false,
                      ),
                    );
                  },
                ),
              ),
            ),
            //ANCHOR - Restore Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: AquaButton.primary(
                key: OnboardingScreenKeys.restoreConfirmButton,
                text: context.loc.restoreInputButton,
                isLoading: ref.watch(walletRestoreProvider).isLoading,
                onPressed: () async {
                  await ref
                      .read(walletRestoreProvider.notifier)
                      .validateMnemonicAndGetWalletInfo();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
