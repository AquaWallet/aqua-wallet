import 'dart:async';

import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/scan/scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/wallet_header_localizations_extension.dart';
import 'package:aqua/features/text_scan/text_scan.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AssetsList extends HookConsumerWidget {
  const AssetsList({
    super.key,
    required this.assets,
    required this.refreshController,
  });

  final List<Asset> assets;
  final AquaRefreshController refreshController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(btcPriceUiModelProvider(2));
    final btcPriceUiModel = btcPriceAsync.valueOrNull;
    final btcPriceHistory = ref.watch(bitcoinPriceHistoryProvider).valueOrNull;
    final savingAssetList = assets.where((asset) => asset.isBTC).toList();
    final spendingAssetList = assets.where((asset) => !asset.isBTC).toList();

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

    return AquaPullToRefresh(
      enablePullDown: true,
      controller: refreshController,
      // Don't show indicator here, it will be in the header
      showIndicator: false,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 2,
          bottom: 80,
        ),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Price/Balance Header
            AquaWalletHeader(
              text: context.loc.walletHeaderLocalizations,
              currencySymbol: btcPriceUiModel?.symbol,
              bitcoinPrice: btcPriceUiModel?.price,
              isSymbolLeading: btcPriceUiModel?.isSymbolLeading,
              priceChartData: btcPriceHistory,
              showChart: true,
              onSend: () => context.push(SendMenuScreen.routeName),
              onReceive: () => context.push(ReceiveMenuScreen.routeName),
              onScan: () async {
                final result = await context.push(
                  ScanScreen.routeName,
                  extra: ScanArguments(
                    qrArguments: QrScannerArguments(
                      parseAction: QrScannerParseAction.attemptToParse,
                    ),
                    textArguments: TextScannerArguments(
                      parseAction: TextScannerParseAction.attemptToParse,
                    ),
                    initialType: ScannerType.qr,
                  ),
                );

                // Handle QR scan result
                if (result is QrScanState) {
                  result.maybeWhen(
                    sendAsset: (args) {
                      context.push(SendAssetScreen.routeName, extra: args);
                    },
                    orElse: () {},
                  );
                }
                // Handle text scan result
                else if (result is String) {
                  // Use first asset (prefer BTC if available) - send flow will parse address and switch if needed
                  final defaultAsset = assets.isEmpty
                      ? Asset.btc()
                      : assets.firstWhere(
                          (a) => a.isBTC,
                          orElse: () => assets.first,
                        );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.push(
                      SendAssetScreen.routeName,
                      extra:
                          SendAssetArguments.fromAsset(defaultAsset).copyWith(
                        input: result,
                      ),
                    );
                  });
                }
              },
              colors: context.aquaColors,
            ),
            const SizedBox(height: 22),
            //ANCHOR - Savings Header
            AquaText.body1SemiBold(text: context.loc.tabSavings),
            const SizedBox(height: 16),
            //ANCHOR - Savings List
            if (savingAssetList.isNotEmpty) ...[
              SectionAssetList(items: savingAssetList),
            ] else ...[
              const SkeletonAssetListItem(),
            ],
            const SizedBox(height: 22),
            //ANCHOR - Spending Header
            AquaText.body1SemiBold(
              text: spendingAssetList.length == 1
                  ? context.loc.tabSpendingSingular
                  : context.loc.tabSpending,
            ),
            const SizedBox(height: 16),
            //ANCHOR - Spending List
            if (spendingAssetList.isNotEmpty) ...[
              SectionAssetList(items: spendingAssetList),
            ] else ...[
              SkeletonAssetListItem(
                assets: [Asset.lbtc(), Asset.usdtLiquid()],
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
