import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

// Provider to control whether to show wallet name input
final showWalletNameInputProvider =
    StateProvider.autoDispose<bool>((ref) => true);

class WalletRestoreScreen extends HookConsumerWidget {
  static const routeName = '/wallet-restore';

  const WalletRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // Always show wallet name input
      ref.read(showWalletNameInputProvider.notifier).state = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          ref.read(systemOverlayColorProvider(context)).themeBased();
        });
      });
      return null;
    }, []);

    ref.listen(storedWalletsProvider, (prev, next) {
      final hadNoWallet = prev?.valueOrNull?.currentWallet == null;
      final hasWallet = next.valueOrNull?.currentWallet != null;
      final prevWalletCount = prev?.valueOrNull?.wallets.length ?? 0;
      final nextWalletCount = next.valueOrNull?.wallets.length ?? 0;
      final walletAdded = nextWalletCount > prevWalletCount;

      if ((hadNoWallet && hasWallet) || walletAdded) {
        ref
            .read(walletSuccessModalProvider.notifier)
            .showModal(WalletSuccessModalType.restored);
        if (context.mounted) {
          context.go(HomeScreen.routeName);
        }
      }
    });

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        ref.read(systemOverlayColorProvider(context)).aqua(aquaColorNav: true);
      },
      child: Scaffold(
        backgroundColor: context.aquaColors.surfaceBackground,
        appBar: AquaTopAppBar(
          showBackButton: true,
          colors: context.aquaColors,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Spacer(),
                AquaRingedIcon(
                    icon: AquaIcon.wallet(
                      color: context.aquaColors.textTertiary,
                    ),
                    variant: AquaRingedIconVariant.normal,
                    colors: context.aquaColors),
                const SizedBox(height: 24.0),
                AquaText.h4Medium(text: context.loc.restoreWallet),
                const SizedBox(
                  height: 8,
                ),
                AquaText.body1(
                  text: context.loc.restorePromptSubtitle,
                  maxLines: 4,
                  color: context.aquaColors.textSecondary,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                AquaButton.primary(
                  key: OnboardingScreenKeys.restoreStartButton,
                  onPressed: () =>
                      context.push(WalletRestoreInputScreen.routeName),
                  text: context.loc.restorePromptButton,
                ),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
