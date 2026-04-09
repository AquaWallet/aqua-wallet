import 'package:aqua/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/marketplace/providers/enabled_services_provider.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/lifecycle_observer.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

typedef RecordModalData = ({
  String title,
  String message,
  String primaryButtonText,
  void Function() onPrimaryButtonTap,
  String? secondaryButtonText,
  void Function()? onSecondaryButtonTap
});

class HomeScreen extends HookConsumerWidget with RestoreTransactionMixin {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshController = useRefreshController();
    final isDarkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final isBalanceVisible =
        ref.watch(prefsProvider.select((p) => !p.isBalanceHidden));
    final selectedTab = ref.watch(homeSelectedBottomTabProvider);
    final isWalletTabSelected = selectedTab == WalletTabs.wallet;
    final hasTransacted = ref.watch(hasTransactedProvider).asData?.value;
    final unifiedBalance = ref.watch(unifiedBalanceProvider);
    final currentWallet =
        ref.watch(storedWalletsProvider).valueOrNull?.currentWallet;
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));
    final modalState = ref.watch(walletSuccessModalProvider);
    final languageCode = ref.watch(prefsProvider.select((p) => p.languageCode));

    final availableServices = ref.watch(enabledServicesTypesProvider);
    final isSwapEnabled = useMemoized(
        () => availableServices.asData?.value
            .firstWhereOrNull(
                (service) => service.type == MarketplaceServiceType.swaps)
            ?.isEnabled,
        [availableServices]);

    final onTabSelected = useCallback((WalletTabs tab) {
      if (tab == WalletTabs.marketplace && region == null) {
        context.push(
          RegionSettingsScreen.routeName,
          extra: true,
        );
      } else {
        ref.read(homeProvider).selectTab(tab.index);
      }
    }, [region]);

    ref.watch(availableAssetsProvider);
    ref.watch(featureUnlockTapCountProvider);
    ref.watch(recentlySpentUtxosProvider);
    ref.watch(swapServicesRegistryProvider);
    ref.watch(preferredUsdtSwapServiceProvider);
    ref.watch(pendingTransactionMarkingProvider);

    ref.watch(boltzInitProvider).maybeWhen(
          data: (_) {
            ref.watch(boltzSwapSettlementServiceProvider);
          },
          error: (e, stackTrace) async {
            final alertModel = CustomAlertDialogUiModel(
                title: context.loc.boltzInitTitleError,
                subtitle: '${context.loc.needRestartAppError}\n\n$e',
                buttonTitle: context.loc.ok,
                onButtonPressed: () {
                  context.pop();
                });
            await showCustomAlertDialog(context: context, uiModel: alertModel);
          },
          orElse: () {},
        );

    listenToRestoreTransactionHistoryEvents(context, ref);

    observeAppLifecycle((state) {
      if (state == AppLifecycleState.resumed) {
        logger.debug("[Lifecycle] App resumed in foreground");
        Future.microtask(() {
          // Refresh boltz swaps monitoring
          ref.invalidate(boltzSwapSettlementServiceProvider);
        });
      }
    });

    useEffect(() {
      Future.microtask(() {
        final showBackupFlow = ref
            .read(backupReminderProvider.select((p) => p.shouldShowBackupFlow));
        if (hasTransacted == true && showBackupFlow) {
          context.push(WalletBackupScreen.routeName);
        }
      });
      return null;
    }, [hasTransacted]);

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).themeBased();
      });
      return null;
    }, []);

    final walletSuccessModalLookup = useMemoized(() {
      commonPrimaryFn() {
        ref.read(walletSuccessModalProvider.notifier).dismiss();
        Navigator.of(context).pop();
      }

      final RecordModalData createdModalData = (
        title: context.loc.walletCreated,
        message: context.loc.onboardingWalletCreatedBody,
        primaryButtonText: context.loc.commonGotIt,
        onPrimaryButtonTap: commonPrimaryFn,
        secondaryButtonText: context.loc.backupSeedPhrase,
        onSecondaryButtonTap: () {
          ref.read(walletSuccessModalProvider.notifier).dismiss();
          Navigator.of(context).pop();
          context.push(
            WalletPhraseWarningScreen.routeName,
            extra: const RecoveryPhraseScreenArguments(isOnboarding: true),
          );
        }
      );

      final RecordModalData restoredModalData = (
        title: context.loc.onboardingWalletRestored,
        message: context.loc.onboardingWalletRestoredBody,
        primaryButtonText: context.loc.commonGotIt,
        onPrimaryButtonTap: commonPrimaryFn,
        secondaryButtonText: null,
        onSecondaryButtonTap: null
      );

      final RecordModalData deletedModalData = (
        title: context.loc.walletDeletedModalTitle,
        message: context.loc.walletDeletedModalBody,
        primaryButtonText: context.loc.commonGotIt,
        onPrimaryButtonTap: commonPrimaryFn,
        secondaryButtonText: null,
        onSecondaryButtonTap: null
      );

      final Map<WalletSuccessModalType, RecordModalData>
          walletSuccessModalLookup = {
        WalletSuccessModalType.created: createdModalData,
        WalletSuccessModalType.restored: restoredModalData,
        WalletSuccessModalType.deleted: deletedModalData,
      };

      return walletSuccessModalLookup;
    }, [languageCode]);

    final showWalletSuccessModal = useCallback(() {
      final notifier = ref.read(walletSuccessModalProvider.notifier);
      if (!notifier.shouldShowModal) {
        return;
      }

      notifier.markAsShown();

      final modalData = walletSuccessModalLookup[modalState.modalType];
      if (modalData == null) {
        logger.error(
            "Wallet sucess modal data not found for modal type: ${modalState.modalType}");
        return;
      }

      AquaModalSheet.show(
        context,
        colors: context.aquaColors,
        title: modalData.title,
        message: modalData.message,
        primaryButtonText: modalData.primaryButtonText,
        secondaryButtonText: modalData.secondaryButtonText,
        iconVariant: AquaRingedIconVariant.info,
        icon: AquaIcon.checkCircle(color: Colors.white),
        onPrimaryButtonTap: modalData.onPrimaryButtonTap,
        onSecondaryButtonTap: modalData.onSecondaryButtonTap,
        copiedToClipboardText: context.loc.copiedToClipboard,
      );
    }, [modalState.modalType]);

    useEffect(() {
      if (ref.read(walletSuccessModalProvider.notifier).shouldShowModal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final assetsLoaded = ref.read(availableAssetsProvider).hasValue;
          final balanceLoaded = unifiedBalance != null;
          final walletsLoaded = currentWallet != null;

          if (assetsLoaded &&
              balanceLoaded &&
              walletsLoaded &&
              context.mounted) {
            if (context.mounted) {
              showWalletSuccessModal();
            }
          }
        });
      }
      return null;
    }, [modalState, showWalletSuccessModal, unifiedBalance, currentWallet]);

    return Theme(
      data: isDarkMode
          ? ref.watch(newDarkThemeProvider(context))
          : ref.watch(newLightThemeProvider(context)),
      child: PopScope(
        canPop: selectedTab == WalletTabs.wallet,
        onPopInvoked: (bool didPop) {
          if (!didPop && selectedTab != WalletTabs.wallet) {
            ref.read(homeProvider).selectTab(0);
          }
        },
        child: AnnotatedRegion(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: context.aquaColors.glassBackground,
            systemNavigationBarContrastEnforced: true,
          ),
          child: Scaffold(
            appBar: isWalletTabSelected
                ? AquaHeader(
                    refreshController: refreshController,
                    onRefresh: () async {
                      ref.read(assetsProvider.notifier).reloadAssets();
                      ref.read(aquaConnectionProvider.notifier).connect();
                    },
                    onNotificationsPressed: () {},
                    onWalletPressed: () => context.push(
                      StoredWalletsScreen.routeName,
                    ),
                    showNotifications: false,
                    paddingTop: MediaQuery.of(context).padding.top + 8,
                    walletBalance: unifiedBalance?.formatted != null
                        ? unifiedBalance!.formatted
                        : '',
                    walletName: currentWallet?.name ??
                        context.loc.walletPlaceHolderName(1),
                    colors: context.aquaColors,
                    isBalanceVisible: isBalanceVisible,
                    onBalanceVisibilityChanged: (_) {
                      ref.read(prefsProvider).switchBalanceHidden();
                    },
                  )
                : null,
            body: switch (selectedTab) {
              WalletTabs.wallet => WalletTab(
                  refreshController: refreshController,
                ),
              WalletTabs.marketplace => const MarketplaceTab(),
              WalletTabs.settings => const SettingsTab(),
            },
            extendBody: true,
            extendBodyBehindAppBar: false,
            floatingActionButton:
                (isSwapEnabled ?? false) && selectedTab == WalletTabs.wallet
                    ? AquaFloatingActionButton(
                        onTap: () => context.push(SwapScreen.routeName),
                        icon: AquaIcon.swap,
                      )
                    : null,
            bottomNavigationBar: AquaNavBar(
              colors: context.aquaColors,
              itemCount: WalletTabs.values.length,
              itemBuilder: (context, index) {
                final tab = WalletTabs.values.elementAt(index);
                return AquaNavBarItem(
                  onTap: () => onTabSelected(tab),
                  colors: context.aquaColors,
                  isSelected: selectedTab == tab,
                  icon: switch (tab) {
                    WalletTabs.wallet => AquaIcon.wallet,
                    WalletTabs.marketplace => AquaIcon.marketplace,
                    WalletTabs.settings => AquaIcon.settings,
                  },
                  label: switch (tab) {
                    WalletTabs.wallet => context.loc.homeTabWalletTitle,
                    WalletTabs.marketplace => context.loc.marketplaceTitle,
                    WalletTabs.settings => context.loc.settings,
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
