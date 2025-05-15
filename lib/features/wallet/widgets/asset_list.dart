import 'dart:io';
import 'dart:async';

import 'package:aqua/constants.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class AssetsList extends HookConsumerWidget {
  const AssetsList({
    super.key,
    required this.assets,
  });

  final List<Asset> assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anyNonZeroBalance = assets.any((asset) => asset.amount > 0);
    final savingAssetList = assets.where((asset) => asset.isBTC).toList();
    final spendingAssetList = assets.where((asset) => !asset.isBTC).toList();
    final refresherKey = useMemoized(UniqueKey.new);
    final controller =
        useMemoized(() => RefreshController(initialRefresh: false));

    // Scroll controller to scroll to the top of the list after inactivity
    final scrollController = useScrollController();
    // Timer for detecting inactivity
    final inactivityTimer = useRef<Timer?>(null);

    // Reset inactivity timer
    void resetInactivityTimer() {
      inactivityTimer.value?.cancel();
      inactivityTimer.value = Timer(const Duration(minutes: 2), () {
        // Scroll to the top gently after 2 minutes of inactivity
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0, // Scroll to the top
            duration: const Duration(seconds: 1), // Smooth scroll duration
            curve: Curves.easeInOut,
          );
        }
      });
    }

    // Reset the timer whenever the user interacts with the device
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resetInactivityTimer();
      });

      // Listen to scroll events to reset the timer
      scrollController.addListener(resetInactivityTimer);

      return () {
        // Cleanup: cancel the timer and remove the listener
        inactivityTimer.value?.cancel();
        scrollController.removeListener(resetInactivityTimer);
      };
    }, []);

    //NOTE - Hide swap button under two scenarios:
    // 1. Device is iOS AND the feature flag for disabling swaps is enabled
    // 2. The user has zero balance
    final isSwapEnabled = useMemoized(
      () => !(Platform.isIOS && disableSideswapOnIOS && !anyNonZeroBalance),
      [disableSideswapOnIOS, anyNonZeroBalance],
    );

    return SmartRefresher(
      enablePullDown: true,
      key: refresherKey,
      controller: controller,
      physics: const BouncingScrollPhysics(),
      onRefresh: () async {
        await ref.read(assetsProvider.notifier).reloadAssets();
        controller.refreshCompleted();
      },
      header: ClassicHeader(
        height: 72.0,
        refreshingText: '',
        releaseText: '',
        completeText: '',
        failedText: '',
        idleText: '',
        idleIcon: null,
        failedIcon: null,
        releaseIcon: null,
        refreshingIcon: null,
        completeIcon: null,
        outerBuilder: (child) => Container(child: child),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(
          left: 28.0,
          right: 28.0,
          bottom: 80,
        ),
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          const SizedBox(height: 18),
          //ANCHOR - Savings Header
          AssetListSectionHeader(
            text: context.loc.tabSavings,
            children: const [
              Spacer(),
              SizedBox(height: 33),
              // Replicate the height taken up by Swap button to make gaps even
            ],
          ),
          const SizedBox(height: 18),
          //ANCHOR - Savings List
          SectionAssetList(items: savingAssetList),
          const SizedBox(height: 18),
          //ANCHOR - Spending Header
          AssetListSectionHeader(
            text: spendingAssetList.length == 1
                ? context.loc.tabSpendingSingular
                : context.loc.tabSpending,
            children: [
              const Spacer(),
              if (isSwapEnabled) ...{
                const WalletInternalSwapButton(),
              } else ...{
                const SizedBox(height: 33),
              }
            ],
          ),
          const SizedBox(height: 19.0),
          //ANCHOR - Spending List
          spendingAssetList.isNotEmpty
              ? SectionAssetList(items: spendingAssetList)
              : AssetListErrorView(
                  message: context.loc.manageAssetsScreenError,
                ),
        ],
      ),
    );
  }
}
