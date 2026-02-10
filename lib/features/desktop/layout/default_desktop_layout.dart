import 'package:aqua/data/provider/provider.dart';
import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

final desktopGlobalKey = GlobalKey();

class DefaultDesktopLayout extends HookConsumerWidget {
  const DefaultDesktopLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dropDownListKey = useMemoized(GlobalKey.new);
    final sizeOfScreen = MediaQuery.sizeOf(context);
    final aquaColors = context.aquaColors;
    final loc = context.loc;
    final selectedDrawerNavIndex = useState(0);

    final centerOfScreenForModelSheet = sizeOfScreen.height / 3;
    final isScreenWidthTooSmall = sizeOfScreen.width < tooSmallWidthOfScreen;

    final isDarkMode = ref.watch(
      prefsProvider.select(
        (p) => p.isDarkMode(context),
      ),
    );

    return Theme(
      data: isDarkMode
          ? ref.watch(newDarkThemeProvider(context))
          : ref.watch(newLightThemeProvider(context)),
      child: Scaffold(
        key: desktopGlobalKey,
        body: SafeArea(
          child: Row(
            children: [
              Container(
                color: aquaColors.surfacePrimary,
                constraints: const BoxConstraints(
                  maxWidth: desktopSideBarWidth,
                ),
                child: AquaNavDrawer(
                  colors: aquaColors,
                  onLogoTap: () => context.go(DesktopHomeScreen.routeName),
                  sections: [
                    AquaNavDrawerSection(
                      title: 'Digital Wallets',
                      colors: context.aquaColors,
                      itemCount: 2,
                      itemBuilder: (context, index) => AquaNavDrawerItem(
                        label: 'Wallet ${index + 1}',
                        icon: AquaIcon.wallet,
                        colors: context.aquaColors,
                        isSelected: selectedDrawerNavIndex.value == index,
                        onTap: () {
                          selectedDrawerNavIndex.value = index;
                          AquaTooltip.show(
                            context,
                            message: 'Wallet ${index + 1} tapped',
                            colors: aquaColors,
                          );
                          if (index == 0) {
                            context.go(DesktopHomeScreen.routeName);
                          } else if (index == 1) {
                            context.go(DolphinCardScreen.routeName);
                          }
                        },
                      ),
                    ),
                    AquaNavDrawerSection(
                      title: 'Hardware Wallets',
                      colors: aquaColors,
                      itemCount: 2,
                      itemBuilder: (context, index) => AquaNavDrawerItem(
                        label: 'HW Wallet ${index + 1}',
                        icon: AquaIcon.hardwareWallet,
                        isSelected: selectedDrawerNavIndex.value == 2 + index,
                        colors: aquaColors,
                        onTap: () {
                          selectedDrawerNavIndex.value = 2 + index;
                          AquaTooltip.show(
                            context,
                            message: 'HW Wallet ${index + 1} tapped',
                            colors: aquaColors,
                          );
                        },
                      ),
                    ),
                  ],
                  footer: AquaNavDrawerFooterButton(
                    colors: aquaColors,
                    label: 'Add Wallet',
                    icon: AquaIcon.plus,
                    onTap: () => AquaModalSheet.show(
                      context,
                      colors: aquaColors,
                      icon: AquaIcon.wallet(
                        color: aquaColors.textPrimary,
                      ),
                      title: 'Digital Wallet',
                      message:
                          'Your Bitcoin keys are securely stored on your device.',
                      primaryButtonText: context.loc.addNewWallet,
                      secondaryButtonText: loc.restoreWallet,
                      bottomPadding: centerOfScreenForModelSheet,
                      onPrimaryButtonTap: () {
                        debugPrint('New wallet');
                        Navigator.of(context).pop();
                      },
                      onSecondaryButtonTap: () => Navigator.of(context).pop(),
                      copiedToClipboardText: context.loc.copiedToClipboard,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 26.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AquaNavHeader(
                        title: 'Wallet',
                        onReceiveTap: () => ReceiveSelectorSideSheet.show(
                          context: context,
                          aquaColors: aquaColors,
                          loc: loc,
                        ),
                        onSendTap: () => SendSelectorSideSheet.show(
                          context: context,
                          aquaColors: aquaColors,
                          loc: loc,
                        ),
                        onSwapTap: () => SwapMainSideSheet.show(
                          context: context,
                          aquaColors: aquaColors,
                          loc: loc,
                        ),
                        onMarketplaceTap: () => MarketPlaceSideSheet.show(
                          context: context,
                          aquaColors: aquaColors,
                          loc: loc,
                        ),
                        onRegionTap: () {},
                        onUserTap: () {},
                        onSettingsTap: () =>
                            context.go(SettingsScreen.fullRoute),
                        colors: aquaColors,
                        isScreenTooSmall: isScreenWidthTooSmall,
                        dropDownWidget: AquaIcon.more(
                          key: dropDownListKey,
                          color: aquaColors.textSecondary,
                          onTap: () => AquaDropDown.show(
                            context: context,
                            colors: aquaColors,
                            containerWidth: 240,
                            offsetY: 5,
                            anchor: dropDownListKey.currentContext
                                ?.findRenderObject(),
                            child: ListView(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                AquaListItem(
                                  iconLeading: AquaIcon.edit(
                                    color: aquaColors.textSecondary,
                                  ),
                                  iconTrailing: AquaIcon.chevronRight(
                                    color: aquaColors.textSecondary,
                                  ),
                                  title: loc.editWallet,
                                  titleColor: aquaColors.textPrimary,
                                  onTap: () async {
                                    AquaDropDown.dismiss();

                                    await SideSheet.right<bool>(
                                      context: context,
                                      colors: aquaColors,
                                      body: const WalletEditSideSheet(),
                                    ).then((value) {
                                      debugPrint(
                                        'Side sheet closed with result: $value',
                                      );
                                    });
                                  },
                                ),
                                AquaListItem(
                                  iconLeading: AquaIcon.lock(
                                    color: aquaColors.textSecondary,
                                  ),
                                  iconTrailing: AquaIcon.chevronRight(
                                    color: aquaColors.textSecondary,
                                  ),
                                  title: 'Lock Wallet',
                                  titleColor: aquaColors.textPrimary,
                                  onTap: () {
                                    AquaDropDown.dismiss();
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      StylizedDivider(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        color: aquaColors.surfaceBorderSecondary,
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
