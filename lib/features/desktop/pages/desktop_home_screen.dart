import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

import '../widgets/widgets.dart';

class DesktopHomeScreen extends HookConsumerWidget {
  const DesktopHomeScreen({
    super.key,
    this.showDialog,
  });

  final WalletOnboardingDialog? showDialog;

  static const routeName = '/desktopHome';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final aquaColors = context.aquaColors;
    final historyOfAccount = [
      HistoryOfAccountUiModel(
        type: HistoryOfAccount.transactions,
        name: context.loc.transactions,
      ),
      HistoryOfAccountUiModel(
        type: HistoryOfAccount.address,
        name: context.loc.address,
      ),
      HistoryOfAccountUiModel(
        type: HistoryOfAccount.swapOrders,
        name: context.loc.swapOrders,
      ),
    ];

    final tempPendingTransactions = getMockTransactionsPending(context);

    /// Hooks
    final selectedAccount = useState<SelectedAccountUiModel>(
      SelectedAccountUiModel(
        type: TypeOfAccount.savings,
        assetUiModel: getMockSavingsAccounts.first,
      ),
    );

    final selectedHistoryOfAccount =
        useState<HistoryOfAccount>(HistoryOfAccount.transactions);

    /// widget sizes
    final desktopScreenHeight = MediaQuery.sizeOf(context).height;

    /// useEffect
    useEffect(() {
      void resetSelectedHistoryOfAccount() {
        if (selectedAccount.value.isSavingsAccount &&
            selectedHistoryOfAccount.value.isSwapOrders) {
          selectedHistoryOfAccount.value = HistoryOfAccount.transactions;
        }
      }

      selectedAccount.addListener(resetSelectedHistoryOfAccount);

      return () =>
          selectedAccount.removeListener(resetSelectedHistoryOfAccount);
    }, [selectedAccount]);

    /// useEffect to show dialog after first frame
    /// This is just for testing purposes show message should be based of of some logic
    useEffect(() {
      if (showDialog != null) {
        Future.delayed(const Duration(milliseconds: 500));
        Future.microtask(() {
          switch (showDialog!) {
            case WalletOnboardingDialog.createWallet:
              AquaModalSheet.show(
                context,
                title: loc.newWalletCreated,
                message: loc.onboardingWalletCreatedBody,
                primaryButtonText: loc.commonGotIt,
                secondaryButtonText: 'Backup Seed Phrase',
                onPrimaryButtonTap: () => context.pop(),
                onSecondaryButtonTap: () => context.pop(),
                bottomPadding: desktopScreenHeight / screenParts,
                icon: AquaIcon.checkCircle(
                  color: Colors.white,
                ),
                iconVariant: AquaRingedIconVariant.info,
                colors: aquaColors,
                copiedToClipboardText: loc.copiedToClipboard,
              );

            case WalletOnboardingDialog.restoreWallet:
              AquaModalSheet.show(
                context,
                title: loc.onboardingWalletRestored,
                message: loc.onboardingWalletRestoredBody,
                primaryButtonText: loc.commonGotIt,
                onPrimaryButtonTap: () => context.pop(),
                icon: AquaIcon.checkCircle(
                  color: Colors.white,
                ),
                iconVariant: AquaRingedIconVariant.info,
                colors: aquaColors,
                bottomPadding: desktopScreenHeight / screenParts,
                copiedToClipboardText: loc.copiedToClipboard,
              );
          }
        });
      }
      return null;
    }, [showDialog]);

    return ColoredBox(
      color: aquaColors.surfaceBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaDesktopWalletTile(
                  colors: aquaColors,
                  walletName: 'Wallet 1',
                  symbol: '\$',
                  walletBalance: '222,475.48',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: AquaText.body1SemiBold(
                          text: loc.tabSavings,
                          color: aquaColors.textPrimary,
                        ),
                      ),
                      OutlineContainer(
                        aquaColors: aquaColors,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: double.maxFinite,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: getMockSavingsAccounts.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    StylizedDivider(
                              color: context.aquaColors.surfaceBorderPrimary,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final item = getMockSavingsAccounts[index];

                              return AquaAccountItem(
                                asset: item,
                                textColorTitle: context.aquaColors.textPrimary,
                                textColorSubtitle: aquaColors.textSecondary,
                                selected:
                                    selectedAccount.value.isThisItemSelected(
                                  item.assetId,
                                  selectedAccount.value,
                                ),
                                onTap: (_) {
                                  selectedAccount.value =
                                      selectedAccount.value.copyWith(
                                    type: TypeOfAccount.savings,
                                    assetUiModel: item,
                                  );
                                },
                                colors: context.aquaColors,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: AquaText.body1SemiBold(
                          text: loc.tabSpendingSingular,
                          color: aquaColors.textPrimary,
                        ),
                      ),
                      OutlineContainer(
                        aquaColors: aquaColors,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: double.maxFinite,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: getMockSpendingAccounts.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    StylizedDivider(
                              color: context.aquaColors.surfaceBorderPrimary,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final item = getMockSpendingAccounts[index];

                              return AquaAccountItem(
                                asset: item,
                                textColorTitle: context.aquaColors.textPrimary,
                                textColorSubtitle: aquaColors.textSecondary,
                                selected:
                                    selectedAccount.value.isThisItemSelected(
                                  item.assetId,
                                  selectedAccount.value,
                                ),
                                onTap: (_) {
                                  selectedAccount.value =
                                      selectedAccount.value.copyWith(
                                    type: TypeOfAccount.spending,
                                    assetUiModel: item,
                                  );
                                },
                                colors: context.aquaColors,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaDesktopBitcoinPriceTile(
                  bitcoinPrice: '109,493.32',
                  currencySymbol: '\$',
                  priceChartData: kFakeChartData,
                  trendAmount: '+4,831.52',
                  trendPercent: '+10.46%',
                  isNegative: false,
                  colors: context.aquaColors,
                  bitcoinPriceText: context.loc.bitcoinPrice,
                ),
                TextTabBar(
                  onTabChanged: (tab) =>
                      selectedHistoryOfAccount.value = tab.type,
                  tabs: historyOfAccount.sublist(
                      0, selectedAccount.value.isSpendingAccount ? 3 : 2),
                  selectedTab: selectedHistoryOfAccount.value,
                ),
                Expanded(
                  child: switch (selectedHistoryOfAccount.value) {
                    HistoryOfAccount.transactions => Column(
                        children: [
                          if (tempPendingTransactions.isNotEmpty) ...[
                            Flexible(
                              child: ListCard(
                                maxWidth: double.maxFinite,
                                items: tempPendingTransactions,
                                noItemsTitle: loc.commonNoHistory,
                                noItemsSubtitle: loc.commonNoTransactions,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                          Expanded(
                            flex: 5,
                            child: ListCard(
                              maxWidth: double.maxFinite,
                              items: getMockTransactions(context),
                              noItemsTitle: loc.commonNoHistory,
                              noItemsSubtitle: loc.commonNoTransactions,
                            ),
                          ),
                        ],
                      ),
                    HistoryOfAccount.address => HistoryOfAccountAddress(
                        key: ObjectKey(selectedAccount.value),
                        data: mockAddresses,
                      ),
                    HistoryOfAccount.swapOrders => HistoryOfSwapOrder(
                        key: ObjectKey(selectedAccount.value),
                        data: getMockDataSwapOrder,
                      ),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
