import 'package:aqua/common/common.dart';
import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/bip329/bip329_settings_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/settings/shared/widgets/settings_tab_tiles_wrapper.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/models/stored_wallet.dart';
import 'package:aqua/features/wallet/pages/stored_wallets_screen.dart';
import 'package:aqua/features/wallet/providers/providers.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_components/ui_components.dart';

class SettingsTab extends HookConsumerWidget with AuthGuardMixin {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final currentTheme = ref.watch(prefsProvider.select((p) => p.theme));
    final currentThemeLabel = switch (currentTheme) {
      'light' => context.loc.themesSettingsScreenItemLight,
      'dark' => context.loc.themesSettingsScreenItemDark,
      'system' => context.loc.themesSettingsScreenItemSystem,
      _ => currentTheme.capitalize(),
    };
    final env = ref.watch(envProvider);
    final version = ref.watch(versionProvider).asData?.value ?? '';
    final versionText = kDebugMode ? '$version (${env.name})' : version;
    final languageCode = ref.watch(languageProvider(context)
        .select((p) => p.currentLanguage.languageCode));
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));
    final isCustomElectrumUrlEnabled = ref
        .watch(featureFlagsProvider.select((p) => p.customElectrumUrlEnabled));
    final isJan3CardVisible =
        ref.watch(prefsProvider.select((p) => p.isJan3CardExpanded));
    final isNotesEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));

    final currentBlockExplorer =
        ref.watch(blockExplorerProvider.select((p) => p.currentBlockExplorer));
    final currentDisplayUnit =
        ref.watch(displayUnitsProvider.select((p) => p.currentDisplayUnit));
    final walletState = ref.watch(storedWalletsProvider).valueOrNull;
    final currentWallet = walletState?.currentWallet;
    final currentWalletName = currentWallet?.name;
    final accountState = ref.watch(jan3AuthProvider).valueOrNull;
    final isAuthenticated = accountState?.isAuthenticated ?? false;

    return DesignRevampScaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaTopAppBar(
        showBackButton: false,
        title: context.loc.settings,
        colors: context.aquaColors,
        onTitlePressed: () =>
            ref.read(featureUnlockTapCountProvider.notifier).increment(),
      ),
      body: SingleChildScrollView(
        key: SettingsScreenKeys.settingsScrollableScreenMenu,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Padding to account for the app bar
            const AppBarPadding(),
            //ANCHOR - General Settings
            AquaWalletTile(
              walletName: currentWalletName ?? '',
              isBalanceVisible: false,
              walletBalance: '',
              colors: context.aquaColors,
              isShowingFingerprint: currentWallet?.formattedFingerprint != null,
              fingerprint: currentWallet?.formattedFingerprint.toUpperCase(),
              onWalletPressed: () => context.push(
                StoredWalletsScreen.routeName,
              ),
            ),
            const SizedBox(height: 16.0),
            // Jan3 Account Card
            Jan3AccountCard(
              isExpanded: isJan3CardVisible || isAuthenticated,
              onClose: () {
                if (!isAuthenticated) {
                  ref
                      .read(prefsProvider.notifier)
                      .setJan3CardExpanded(isExpanded: false);
                }
              },
            ),
            if (isJan3CardVisible || isAuthenticated) ...[
              const SizedBox(height: 16.0),
            ],
            SettingsTabTilesWrapper(
              items: (useSubTitle) => [
                //ANCHOR - Wallet
                AquaListItem(
                  key: SettingsScreenKeys.settingsWalletButton,
                  iconLeading: AquaIcon.infoCircle(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  subtitleTrailing: useSubTitle ? '' : currentWalletName ?? '',
                  subtitle: useSubTitle ? currentWalletName ?? '' : '',
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.walletDetails,
                  onTap: currentWallet != null
                      ? () => context.push(
                            WalletSettingsScreen.routeName,
                            extra: currentWallet.id,
                          )
                      : null,
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Manage Assets
                AquaListItem(
                  key: SettingsScreenKeys.settingsManageAssetsButton,
                  iconLeading: AquaIcon.assets(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.manageAssets,
                  onTap: () => context.push(ManageAssetsScreen.routeName),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Advanced Settings
                AquaListItem(
                  iconLeading: AquaIcon.tool(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.settingsScreenSectionAdvanced,
                  onTap: () => context.push(AdvancedSettingsScreen.routeName),
                ),
                if (!isJan3CardVisible && !isAuthenticated) ...[
                  const SizedBox(height: 1.0),
                  //ANCHOR - Jan3 Settings
                  AquaListItem(
                    iconLeading: darkMode
                        ? AquaIcon.jan3LogoDark(
                            size: 24,
                          )
                        : AquaIcon.jan3Logo(
                            size: 24,
                          ),
                    iconTrailing: AquaIcon.chevronRight(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                    title: context.loc.jan3AccountTitle,
                    onTap: () {
                      context.push(Jan3LoginScreen.routeName);
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            AquaText.body1SemiBold(
              text: context.loc.appSettingsTitle,
            ),
            const SizedBox(height: 16),
            //ANCHOR - General Settings
            SettingsTabTilesWrapper(
              items: (useSubtitle) => [
                //ANCHOR - Region
                AquaListItem(
                  key: SettingsScreenKeys.settingsRegionButton,
                  iconLeading: AquaIcon.globe(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  subtitleTrailing: useSubtitle
                      ? null
                      : region != null
                          ? region.name
                          : '',
                  subtitle: useSubtitle
                      ? region != null
                          ? region.name
                          : ''
                      : null,
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.region,
                  onTap: () => context.push(
                    RegionSettingsScreen.routeName,
                    extra: false,
                  ),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Language
                AquaListItem(
                  key: SettingsScreenKeys.settingsLanguageButton,
                  iconLeading: AquaIcon.language(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  subtitleTrailing:
                      useSubtitle ? null : languageCode.toUpperCase(),
                  subtitle: useSubtitle ? languageCode.toUpperCase() : null,
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.language,
                  onTap: () => context.push(LanguageSettingsScreen.routeName),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Reference rate
                AquaListItem(
                  key: SettingsScreenKeys.settingsReferenceRateButton,
                  iconLeading: AquaIcon.referenceRate(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  subtitleTrailing: useSubtitle
                      ? null
                      : '${currentDisplayUnit.value}/${currentRate.currency.value.toUpperCase()}',
                  subtitle: useSubtitle
                      ? '${currentDisplayUnit.value}/${currentRate.currency.value.toUpperCase()}'
                      : null,
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.unitAndCurrencySettingsTitle,
                  onTap: () =>
                      context.push(ExchangeRateSettingsScreen.routeName),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Themes
                AquaListItem(
                  key: SettingsScreenKeys.settingsThemesButton,
                  iconLeading: AquaIcon.theme(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  subtitleTrailing: useSubtitle ? null : currentThemeLabel,
                  subtitle: useSubtitle ? currentThemeLabel : null,
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.themesSettingsScreenTitle,
                  onTap: () => context.push(ThemesSettingsScreen.routeName),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Block Explorer
                AquaListItem(
                  key: SettingsScreenKeys.settingsBlockExplorerButton,
                  iconLeading: AquaIcon.box(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  subtitleTrailing:
                      useSubtitle ? null : currentBlockExplorer.name,
                  subtitle: useSubtitle ? currentBlockExplorer.name : null,
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.settingsScreenItemExplorer,
                  onTap: () =>
                      context.push(BlockExplorerSettingsScreen.routeName),
                ),
                const SizedBox(height: 1.0),
                //ANCHOR - Security Settings
                AquaListItem(
                  iconLeading: AquaIcon.lock(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  title: context.loc.securitySetingsTitle,
                  onTap: () => context.push(SecuritySettingsScreen.routeName),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            //ANCHOR - Support
            AquaCard(
              borderRadius: BorderRadius.circular(8.0),
              child: AquaListItem(
                key: SettingsScreenKeys.settingsGetHelpSupportButton,
                title: context.loc.commonContactSupport,
                iconLeading: AquaIcon.helpSupport(
                  size: 24,
                  color: context.aquaColors.textSecondary,
                ),
                iconTrailing: AquaIcon.chevronRight(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
                onTap: () => context.push(HelpSupportScreen.routeName),
              ),
            ),
            const SizedBox(height: 1.0),
            //ANCHOR - Electrum Server
            if (isCustomElectrumUrlEnabled) ...[
              //TODO: In order to release this feature, we need to get broadcasting of hex txs and psbts working through GDK, so they can broadcast through the custom endpoint set by user
              AquaListItem(
                key: SettingsScreenKeys.settingsElectrumServerButton,
                iconLeading: AquaIcon.box(
                  size: 24,
                  color: context.aquaColors.textSecondary,
                ),
                title: context.loc.electrumServer,
                onTap: () =>
                    context.push(ElectrumServerSettingsScreen.routeName),
              ),
            ],

            const SizedBox(height: 36.0),

            //ANCHOR - Notes
            if (isNotesEnabled) ...[
              const SizedBox(height: 4.0),
              MenuItemWidget.arrow(
                context: context,
                assetName: Svgs.addNote,
                color: context.colors.onBackground,
                title: context.loc.notesSettingsScreenTitle,
                onPressed: () => context.push(NotesSettingsScreen.routeName),
              ),
            ],
            const SizedBox(height: 4.0),
            //ANCHOR - Jan3 Logo
            Center(
              child: SvgPicture.asset(
                darkMode
                    ? Svgs.jan3LogoWithAquaLight
                    : Svgs.jan3LogoWithAquaDark,
              ),
            ),
            const SizedBox(height: 32.0),
            //ANCHOR - T&C
            Center(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => ref
                        .read(urlLauncherProvider)
                        .open(constants.aquaTermsOfServiceUrl),
                  text: context.loc.welcomeScreenToSDescriptionBold,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            //ANCHOR - Socials
            Center(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => ref
                        .read(urlLauncherProvider)
                        .open(constants.aquaPrivacyUrl),
                  text: context.loc.privacyPolicy,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            //ANCHOR - Socials
            SettingsSocialLinks(
              onLinkClick: (url) => ref.read(urlLauncherProvider).open(url),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 32),
              child: Divider(
                height: 0,
                thickness: 1.0,
                color: context.aquaColors.surfaceBorderSecondary,
              ),
            ),
            //ANCHOR - Version
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
              ),
              alignment: Alignment.center,
              child: Text(
                context.loc.settingsScreenItemVersion(versionText),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.aquaColors.textTertiary,
                    ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
