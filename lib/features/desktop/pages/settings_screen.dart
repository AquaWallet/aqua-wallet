import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/settings/settings.dart' as settings;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';
  static const fullRoute = routeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final aquaColors = context.aquaColors;
    final isDarkMode = ref.watch(
      settings.prefsProvider.select(
        (p) => p.isDarkMode(context),
      ),
    );
    final currentTheme =
        ref.watch(settings.prefsProvider.select((p) => p.theme));
    final showJan3AccountWidget = useState(true);
    final isLoggedIn = useState(true);
    final selectedSettingsPageItem = useState(SelectedSettingsPageItem.none);

    final currentLang = ref.watch(
        settings.languageProvider(context).select((p) => p.currentLanguage));

    return ColoredBox(
      color: aquaColors.surfaceBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: AquaListItem(
                    colors: aquaColors,
                    iconLeading: AquaIcon.wallet(color: aquaColors.textPrimary),
                    title: '${loc.walletName} 1',
                    titleColor: aquaColors.textPrimary,
                    titleTrailing: 'B89AB7BC',
                    titleTrailingColor: aquaColors.textSecondary,
                    iconTrailing:
                        AquaIcon.chevronRight(color: aquaColors.textSecondary),
                  ),
                ),
                if (showJan3AccountWidget.value) ...[
                  const SizedBox(height: 16.0),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: aquaColors.surfacePrimary,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AquaListItem(
                          colors: aquaColors,

                          ///TODO: check which theme is it then show appropriate widget
                          iconLeading: isDarkMode
                              ? UiAssets.svgs.dark.jan3MiniLogo.svg(
                                  height: 40,
                                )
                              : UiAssets.svgs.light.jan3MiniLogo.svg(
                                  height: 40,
                                ),
                          title: 'JAN3 Account',
                          titleColor: aquaColors.textPrimary,
                          subtitle: isLoggedIn.value
                              ? 'user@email.com'
                              : loc.unlockMoreFeatures,
                          subtitleColor: aquaColors.textSecondary,

                          iconTrailing: isLoggedIn.value
                              ? null
                              : AquaIcon.close(
                                  color: aquaColors.textSecondary,
                                  size: 20,
                                  onTap: () =>
                                      showJan3AccountWidget.value = false,
                                ),
                        ),
                        const Divider(
                          height: 1,
                        ),
                        if (isLoggedIn.value) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: AquaButton.tertiary(
                                  size: AquaButtonSize.large,
                                  text: loc.jan3InviteFriends,
                                  onPressed: () {
                                    debugPrint('Button pressed');
                                  },
                                ),
                              ),
                              Expanded(
                                child: AquaButton.tertiary(
                                  size: AquaButtonSize.large,
                                  text: loc.jan3LogOut,
                                  onPressed: () {
                                    AquaModalSheet.show(
                                      context,
                                      title: 'Log Out of JAN3',
                                      illustration: isDarkMode
                                          ? UiAssets.svgs.dark.jan3MiniLogo
                                              .svg()
                                          : UiAssets.svgs.light.jan3MiniLogo
                                              .svg(),
                                      message:
                                          'This will unlink your JAN3 account from this wallet. You’ll lose access to features tied to the connection, but you can log in again anytime.',
                                      primaryButtonText: loc.jan3LogOut,
                                      secondaryButtonText: loc.cancel,
                                      bottomPadding:
                                          MediaQuery.sizeOf(context).height /
                                              screenParts,
                                      onPrimaryButtonTap: () {
                                        isLoggedIn.value = false;
                                        context.pop();
                                      },
                                      onSecondaryButtonTap: () => context.pop(),
                                      colors: aquaColors,
                                      copiedToClipboardText:
                                          loc.copiedToClipboard,
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        ] else ...[
                          AquaButton.tertiary(
                            text: loc.loginScreenTitle,
                            onPressed: () {
                              Jan3AccountSideSheetMainWidget.show(
                                aquaColors: aquaColors,
                                loc: loc,
                                isDarkMode: isDarkMode,
                                context: context,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16.0),
                OutlineContainer(
                  aquaColors: aquaColors,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AquaListItem(
                        iconLeading:
                            AquaIcon.infoCircle(color: aquaColors.textPrimary),
                        title: 'Wallet Details',
                        colors: aquaColors,
                        selected:
                            selectedSettingsPageItem.value.isWalletDetails,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isWalletDetails) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.walletDetails;
                          }
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        ///TODO: se if this exists
                        iconLeading: AquaIcon.sidebarVisibilityRight(
                            color: aquaColors.textPrimary),
                        title: loc.manageAssets,
                        colors: aquaColors,
                        selected: selectedSettingsPageItem.value.isManageAssets,
                        titleTrailingColor: aquaColors.textSecondary,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          selectedSettingsPageItem.value =
                              SelectedSettingsPageItem.manageAssets;
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        iconLeading:
                            AquaIcon.tool(color: aquaColors.textPrimary),
                        title: 'Advanced',
                        colors: aquaColors,
                        selected: selectedSettingsPageItem.value.isAdvanced,
                        titleTrailingColor: aquaColors.textSecondary,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isAdvanced) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.advanced;
                          }
                        },
                      ),
                      if (!showJan3AccountWidget.value) ...[
                        const Divider(height: 0),
                        AquaListItem(
                          iconLeading: isDarkMode
                              ? UiAssets.svgs.dark.jan3MiniLogo.svg(
                                  height: 24,
                                )
                              : UiAssets.svgs.light.jan3MiniLogo.svg(
                                  height: 24,
                                ),
                          title: loc.jan3AccountTitle,
                          colors: aquaColors,
                          selected: false,
                          titleTrailingColor: aquaColors.textSecondary,
                          iconTrailing: AquaIcon.chevronRight(
                              color: aquaColors.textSecondary),
                          onTap: () => showJan3AccountWidget.value = true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const AquaText.body1SemiBold(text: 'App Settings'),
                const SizedBox(height: 16),
                OutlineContainer(
                  aquaColors: aquaColors,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AquaListItem(
                        iconLeading:
                            AquaIcon.globe(color: aquaColors.textPrimary),
                        title: loc.region,
                        colors: aquaColors,
                        titleColor: aquaColors.textPrimary,
                        titleTrailing: 'Norway',
                        selected: selectedSettingsPageItem.value.isRegion,
                        titleTrailingColor: aquaColors.textSecondary,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isRegion) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.region;
                          }
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        iconLeading:
                            AquaIcon.language(color: aquaColors.textPrimary),
                        title: loc.language,
                        colors: aquaColors,
                        titleColor: aquaColors.textPrimary,
                        titleTrailing: currentLang.languageCode.toUpperCase(),
                        selected: selectedSettingsPageItem.value.isLanguage,
                        titleTrailingColor: aquaColors.textSecondary,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isLanguage) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.language;
                          }
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        iconLeading: AquaIcon.referenceRate(
                            color: aquaColors.textPrimary),
                        title: 'Unit & Currency',
                        colors: aquaColors,
                        titleColor: aquaColors.textPrimary,
                        titleTrailing: 'BTC/USD',
                        selected: selectedSettingsPageItem.value.isUnitCurrency,
                        titleTrailingColor: aquaColors.textSecondary,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isUnitCurrency) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.unitCurrency;
                          }
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        iconLeading:
                            AquaIcon.theme(color: aquaColors.textPrimary),
                        title: 'Theme',
                        colors: aquaColors,
                        titleColor: aquaColors.textPrimary,

                        ///TODO: get this from theme context
                        titleTrailing: currentTheme.toUpperCase(),
                        selected: selectedSettingsPageItem.value.isTheme,
                        titleTrailingColor: aquaColors.textSecondary,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isTheme) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.theme;
                          }
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        iconLeading:
                            AquaIcon.box(color: aquaColors.textPrimary),
                        title: 'Explorer',
                        colors: aquaColors,
                        titleColor: aquaColors.textPrimary,
                        titleTrailing: 'Blockstream',
                        selected: selectedSettingsPageItem.value.isExplorer,
                        titleTrailingColor: aquaColors.textSecondary,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isExplorer) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.explorer;
                          }
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        iconLeading:
                            AquaIcon.pokerchip(color: aquaColors.textPrimary),
                        title: loc.bitcoinChip,
                        colors: aquaColors,
                        titleColor: aquaColors.textPrimary,
                        selected: selectedSettingsPageItem.value.isBitcoinChip,
                        iconTrailing: AquaIcon.chevronRight(
                          color: aquaColors.textSecondary,
                        ),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isBitcoinChip) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.bitcoinChip;
                          }
                        },
                      ),
                      const Divider(height: 0),
                      AquaListItem(
                        iconLeading:
                            AquaIcon.lock(color: aquaColors.textPrimary),
                        title: 'Security',
                        colors: aquaColors,
                        titleColor: aquaColors.textPrimary,
                        selected: selectedSettingsPageItem.value.isSecurity,
                        iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary),
                        onTap: () {
                          if (selectedSettingsPageItem.value.isSecurity) {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.none;
                          } else {
                            selectedSettingsPageItem.value =
                                SelectedSettingsPageItem.security;
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlineContainer(
                  aquaColors: aquaColors,
                  child: AquaListItem(
                    colors: aquaColors,
                    iconLeading:
                        AquaIcon.helpSupport(color: aquaColors.textPrimary),
                    title: loc.commonContactSupport,
                    titleColor: aquaColors.textPrimary,
                    iconTrailing:
                        AquaIcon.chevronRight(color: aquaColors.textSecondary),
                    onTap: () {
                      ContactSupportSideSheet.show(
                        context: context,
                        loc: loc,
                        aquaColors: aquaColors,
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    if (isDarkMode) ...[
                      UiAssets.svgs.dark.jan3Logo.svg(
                        height: 32,
                      ),
                    ] else ...[
                      UiAssets.svgs.light.jan3Logo.svg(
                        height: 32,
                      ),
                    ],
                    const SizedBox(height: 8),
                    AquaText.caption1SemiBold(
                      text: 'AQUA by JAN3',
                      color: aquaColors.textPrimary,
                    ),
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: () {
                        ///TODO: add on tap for terms and services
                      },
                      child: Text(
                        'Terms and services',
                        style: AquaTypography.body2Medium.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: aquaColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () {
                        ///TODO: add on tap for terms and services
                      },
                      child: Text(
                        'Privacy Policy',
                        style: AquaTypography.body2Medium.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: aquaColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AquaIcon.globe(color: aquaColors.textPrimary),
                        const SizedBox(width: 25),
                        AquaIcon.twitter(color: aquaColors.textPrimary),
                        const SizedBox(width: 25),
                        AquaIcon.instagram(color: aquaColors.textPrimary),
                        const SizedBox(width: 25),
                        AquaIcon.telegram(color: aquaColors.textPrimary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32.0),
          Expanded(
              child: switch (selectedSettingsPageItem.value) {
            SelectedSettingsPageItem.walletDetails => WalletDetailsSettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.manageAssets => ManageAssetsSettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.advanced => AdvancedSettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.region => RegionSettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.language => LanguageSettings(
                loc: loc,
                aquaColors: aquaColors,
                currentLang: currentLang,
              ),
            SelectedSettingsPageItem.unitCurrency => UnitCurrencySettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.theme => ThemeSettings(
                loc: loc,
                aquaColors: aquaColors,
                currentTheme: currentTheme,
              ),
            SelectedSettingsPageItem.explorer => ExplorerSettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.security => SecuritySettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.bitcoinChip => BitcoinChipSettings(
                loc: loc,
                aquaColors: aquaColors,
              ),
            SelectedSettingsPageItem.none => const SizedBox.shrink(),
          }),
        ],
      ),
    );
  }
}
