import 'package:aqua/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:aqua/common/widgets/custom_bottom_navigation_bar.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/lifecycle_observer.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HomeScreen extends HookConsumerWidget with RestoreTransactionMixin {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(homeContentVisibilityProvider);
    final selectedTab = ref.watch(homeSelectedBottomTabProvider);
    final hasTransacted = ref.watch(hasTransactedProvider).asData?.value;

    ref.watch(availableAssetsProvider);
    ref.watch(featureUnlockTapCountProvider);
    ref.watch(recentlySpentUtxosProvider);
    ref.watch(swapServicesRegistryProvider);
    ref.watch(preferredUsdtSwapServiceProvider);

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

    ref.listen(connectivityStatusProvider, (_, data) {
      ref.invalidate(btcPriceProvider);
      ref.invalidate(exchangeRatesProvider);
      ref.invalidate(fiatRatesProvider);
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

    return Visibility(
      visible: visible,
      child: PopScope(
        canPop: selectedTab == WalletTabs.wallet,
        onPopInvoked: (bool didPop) {
          if (!didPop && selectedTab != WalletTabs.wallet) {
            ref.read(homeProvider).selectTab(0);
          }
        },
        child: AnnotatedRegion(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            body: Stack(
              children: [
                switch (selectedTab) {
                  WalletTabs.wallet => const WalletTab(),
                  WalletTabs.marketplace => const MarketplaceTab(),
                  WalletTabs.settings => const SettingsTab(),
                },
              ],
            ),
            bottomNavigationBar: CustomBottomNavigationBar(
              currentIndex: selectedTab.index,
              onTap: (index) => ref.read(homeProvider).selectTab(index),
            ),
          ),
        ),
      ),
    );
  }
}
