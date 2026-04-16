import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/provider.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class StoredWalletsScreen extends HookConsumerWidget with AuthGuardMixin {
  static const routeName = '/storedWallets';

  const StoredWalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(storedWalletsProvider).valueOrNull;
    final currentWallet = walletState?.currentWallet;
    final currentWalletId = currentWallet?.id;
    final wallets = useMemoized(
      () => List<StoredWallet>.from(walletState?.wallets ?? []),
      [walletState?.wallets],
    );
    final isWalletLimitReached =
        ref.watch(storedWalletsProvider.notifier).isWalletLimitReached;
    final onWalletSwitch = useCallback((String walletId) {
      final targetWallet =
          ref.read(storedWalletsProvider).valueOrNull?.getWalletById(walletId);

      // ignore if wallet is already selected
      if (targetWallet?.id == currentWalletId) {
        return null;
      }
      ref.read(storedWalletsProvider.notifier).switchToWallet(walletId);
    }, [wallets]);

    final onReorder = useCallback((int oldIndex, int newIndex) {
      final wallet = wallets.removeAt(oldIndex);
      wallets.insert(newIndex, wallet);

      Future.microtask(
        () async => ref
            .read(storedWalletsProvider.notifier)
            .reorderWallets(oldIndex, newIndex),
      );
    }, [wallets, ref]);

    ref
      ..listen(registerWalletProcessingProvider, (prev, next) {
        next?.maybeWhen(
          loading: () => showGeneralDialog(
            context: context,
            pageBuilder: (_, __, ___) => const WalletProcessingAnimation(
              type: WalletProcessType.create,
            ),
          ),
          error: (_, __) => showDialog(
            context: context,
            builder: (context) => const WalletProcessError(),
          ),
          orElse: () {},
        );
      })
      ..listen(storedWalletsProvider, (prev, next) {
        final prevWalletCount = prev?.valueOrNull?.wallets.length ?? 0;
        final nextWalletCount = next.valueOrNull?.wallets.length ?? 0;
        final walletAdded = nextWalletCount > prevWalletCount;
        final operationType = next.valueOrNull?.lastOperationType;

        if (walletAdded && operationType != null) {
          final modalType = operationType == WalletOperationType.create
              ? WalletSuccessModalType.created
              : WalletSuccessModalType.restored;
          ref.read(walletSuccessModalProvider.notifier).showModal(modalType);
          if (context.mounted) {
            context.go(HomeScreen.routeName);
          }
        }
      })
      ..listen(walletOperationProvider, (prev, next) {
        // Show loading animation when operation starts
        if (prev == WalletOperationState.idle &&
            next == WalletOperationState.switching) {
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            pageBuilder: (_, __, ___) => const WalletProcessingAnimation(
              type: WalletProcessType.switchWallet,
            ),
          );
        }
        // Hide loading animation when operation completes and go to Home screen
        else if (prev == WalletOperationState.switching &&
            next == WalletOperationState.idle) {
          Future.microtask(() {
            ref.read(systemOverlayColorProvider(context)).themeBased();
            if (context.mounted) {
              context.go(HomeScreen.routeName);
            }
          });
        }
      })
      ..listen(walletRestoreProvider, (prev, state) {
        state.maybeWhen(
          error: (error, _) {
            if (error is WalletRestoreWalletAlreadyExistsException &&
                prev?.isLoading == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  AquaModalSheet.show(
                    context,
                    colors: context.aquaColors,
                    title: context.loc.restoreWalletAlreadyAddedAlertTitle,
                    message: context.loc.restoreWalletAlreadyAddedAlertSubtitle,
                    icon: AquaIcon.check(color: Colors.white),
                    iconVariant: AquaRingedIconVariant.success,
                    primaryButtonText: context.loc.okay,
                    onPrimaryButtonTap: () {
                      context.pop();
                    },
                    copiedToClipboardText: context.loc.copiedToClipboard,
                  );
                }
              });
            }
          },
          orElse: () {},
        );
      });

    return PopScope(
      canPop: currentWallet != null,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AquaTopAppBar(
          title: context.loc.storedWalletsTitle,
          colors: context.aquaColors,
          showBackButton: currentWallet != null,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: MediaQuery.of(context).padding +
                const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
            child: Column(
              children: [
                // ANCHOR: Wallets List
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SeparatedReorderableListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: wallets.length,
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        handleOnlyMode: true,
                        onReorder: onReorder,
                        proxyDecorator: (child, _, __) => Card(
                          elevation: 8,
                          child: child,
                        ),
                        separatorBuilder: (context, index) => AquaDivider(
                          colors: context.aquaColors,
                        ),
                        itemBuilder: (context, index) {
                          final wallet = wallets[index];
                          return AquaListItem(
                            key: ValueKey(wallet.id),
                            colors: context.aquaColors,
                            title: wallet.name,
                            subtitleTrailing:
                                wallet.formattedFingerprint.toUpperCase(),
                            subtitleTrailingColor:
                                context.aquaColors.textSecondary,
                            iconLeading: AquaRadio<String>.small(
                              value: wallet.id,
                              groupValue: currentWalletId,
                              colors: context.aquaColors,
                            ),
                            iconTrailing:
                                SeparatedReorderableListView.buildDragHandle(
                              index: index,
                              child: AquaIcon.grab(size: 18),
                            ),
                            iconSecondaryTrailing: AquaIcon.edit(
                              size: 18,
                              color: context.aquaColors.textSecondary,
                              onTap: () => context.push(
                                WalletSettingsScreen.routeName,
                                extra: wallet.id,
                              ),
                            ),
                            onTap: () => onWalletSwitch(wallet.id),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    // ANCHOR: Add New Wallet Button
                    AquaButton.primary(
                      text: isWalletLimitReached
                          ? context.loc.walletLimitReached
                          : context.loc.addNewWallet,
                      onPressed: isWalletLimitReached
                          ? null
                          : () => ref.read(registerWalletProvider).register(
                              walletName: 'Wallet ${wallets.length + 1}'),
                    ),
                    const SizedBox(height: 16),
                    // ANCHOR: Restore Wallet Button
                    AquaButton.secondary(
                      text: context.loc.restoreWallet,
                      onPressed: isWalletLimitReached
                          ? null
                          : () => context.push(
                                WalletRestoreScreen.routeName,
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
