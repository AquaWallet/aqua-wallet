import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

const deleteWalletButtonConfirmKey =
    Key("settings-delete-wallet-button-confirm");

class WalletSettingsScreen extends HookConsumerWidget with AuthGuardMixin {
  const WalletSettingsScreen({
    super.key,
    required this.walletId,
  });

  final String walletId;

  static const routeName = '/settings/wallet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWallet =
        ref.watch(storedWalletsProvider).valueOrNull?.currentWallet;
    final showWatchOnly = currentWallet?.id ==
        walletId; // watch only is only available for the current wallet
    final wallets = ref.watch(storedWalletsProvider).valueOrNull?.wallets ?? [];
    final wallet =
        ref.watch(storedWalletsProvider).valueOrNull?.getWalletById(walletId);

    final onDeleteWallet = useCallback((StoredWallet wallet) {
      AquaModalSheet.show(
        context,
        colors: context.aquaColors,
        copiedToClipboardText: context.loc.copiedToClipboard,
        icon: AquaIcon.danger(
          size: 24,
          color: AquaPrimitiveColors.white,
        ),
        iconVariant: AquaRingedIconVariant.danger,
        title: context.loc.areYouSure,
        message: context.loc.deleteWalletWarning(wallet.name),
        messageTertiary: context.loc.thisActionIsPermanent,
        primaryButtonKey: deleteWalletButtonConfirmKey,
        primaryButtonText: context.loc.deleteWallet,
        primaryButtonVariant: AquaButtonVariant.error,
        secondaryButtonText: context.loc.cancel,
        onSecondaryButtonTap: () => Navigator.of(context).pop(),
        onPrimaryButtonTap: () async {
          await withAuth(
            context: context,
            ref: ref,
            walletId: wallet.id,
            authDescription: context.loc.authenticateToDeleteWallet,
            operation: () async {
              await ref
                  .read(storedWalletsProvider.notifier)
                  .deleteWallet(wallet.id);

              if (context.mounted) {
                Navigator.of(context).pop(); // Close the delete modal first
                context.go(HomeScreen.routeName);
                ref.read(homeProvider).selectTab(0);
              }

              if (wallets.length > 1) {
                ref
                    .read(walletSuccessModalProvider.notifier)
                    .showModal(WalletSuccessModalType.deleted);
              } else {
                if (context.mounted) {
                  // this is reached only on iOS
                  // on Adroid, the app will restart without user interaction needed
                  context.replace(RestartScreen.routeName);
                }
              }

              return true;
            },
          );
        },
      );
    }, []);

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.homeTabWalletTitle,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //ANCHOR - Edit Wallet
                AquaListItem(
                  iconLeading: AquaIcon.edit(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaIcon.chevronForward(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.editWallet,
                  onTap: () => context.push(
                    EditWalletScreen.routeName,
                    extra: wallet,
                  ),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Recovery Phrase
                AquaListItem(
                  key: SettingsScreenKeys.settingsViewSeedPhraseButton,
                  iconLeading: AquaIcon.key(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaIcon.chevronForward(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.settingsScreenItemPhrase,
                  onTap: () => context.push(
                    WalletPhraseWarningScreen.routeName,
                    extra: RecoveryPhraseScreenArguments(walletId: walletId),
                  ),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Watch Only Export
                if (showWatchOnly) ...[
                  AquaListItem(
                    iconLeading: AquaIcon.eyeOpen(
                      size: 24,
                      color: context.aquaColors.textSecondary,
                    ),
                    iconTrailing: AquaIcon.chevronForward(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                    title: context.loc.walletSettingsScreenItemWatchOnlyExport,
                    onTap: () => context.push(WatchOnlyListScreen.routeName),
                  ),
                  const SizedBox(height: 1.0),
                ],
                //ANCHOR - Remove Wallet
                AquaListItem(
                  key: SettingsScreenKeys.settingsRemoveWalletButton,
                  iconLeading: AquaIcon.danger(
                    size: 24,
                    color: context.aquaColors.accentDanger,
                  ),
                  iconTrailing: AquaIcon.chevronForward(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.deleteWallet,
                  titleColor: context.aquaColors.accentDanger,
                  onTap: wallet != null ? () => onDeleteWallet(wallet) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
