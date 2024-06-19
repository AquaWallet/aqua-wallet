import 'package:aqua/common/widgets/custom_bottom_navigation_bar.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/home/providers/home_provider.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/lifecycle_observer.dart';
import 'package:aqua/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(homeContentVisibilityProvider);
    final selectedTab = ref.watch(homeSelectedBottomTabProvider);
    final hasTransacted = ref.watch(hasTransactedProvider).asData?.value;

    ref.watch(availableAssetsProvider);

    observeAppLifecycle((state) {
      if (state == AppLifecycleState.resumed) {
        logger.d("[Lifecycle] App resumed in foreground");
        Future.microtask(() {
          ref.read(boltzStatusCheckProvider).streamAllPendingSwaps();
        });
      }
    });

    useEffect(() {
      Future.microtask(() {
        ref.read(boltzStatusCheckProvider).streamAllPendingSwaps();
      });
      return null;
    }, []);

    useEffect(() {
      Future.microtask(() {
        final showBackupFlow = ref
            .read(backupReminderProvider.select((p) => p.shouldShowBackupFlow));
        if (hasTransacted == true && showBackupFlow) {
          Navigator.of(context).pushNamed(WalletBackupScreen.routeName);
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
      child: WillPopScope(
        onWillPop: () async {
          if (selectedTab != WalletTabs.wallet) {
            ref.read(homeProvider).selectTab(0);
            return false;
          } else {
            return true;
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
