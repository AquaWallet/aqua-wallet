import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/pin/pin_provider.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/pin/pin_warning_screen.dart';
import 'package:aqua/features/recovery/pages/warning_phrase_screen.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/settings/watch_only/watch_only.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> downloadFile(String logs) async {
  final dir = await getTemporaryDirectory();
  final dirPath = dir.path;
  final fmtDate = DateTime.now().toString().replaceAll(":", " ");
  final file =
      await File('$dirPath/aqua_logs_$fmtDate.txt').create(recursive: true);
  await file.writeAsString(logs);
  await Share.shareXFiles(
    <XFile>[
      XFile(file.path),
    ],
  );
}

class SettingsTab extends HookConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinEnabled =
        ref.watch(pinAuthProvider).asData?.value != PinAuthState.disabled;
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
    final biometricAuth = ref.watch(biometricAuthProvider).asData?.value;
    final env = ref.watch(envProvider);
    final version = ref.watch(versionProvider).asData?.value ?? '';
    final versionText = kDebugMode ? '$version (${env.name})' : version;
    final languageCode = ref.watch(languageProvider(context)
        .select((p) => p.currentLanguage.languageCode));

    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));
    final isDirectPegInEnabled =
        ref.watch(prefsProvider.select((p) => p.isDirectPegInEnabled));
    final experimentalFeaturesEnabled = ref.watch(featureUnlockTapCountProvider
        .select((p) => p.experimentalFeaturesEnabled));
    final isSeedQrEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.seedQrEnabled));
    final isCustomElectrumUrlEnabled = ref
        .watch(featureFlagsProvider.select((p) => p.customElectrumUrlEnabled));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        title: context.loc.settings,
        showActionButton: false,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
        onTitlePressed: () =>
            ref.read(featureUnlockTapCountProvider.notifier).increment(),
      ),
      body: SingleChildScrollView(
        key: SettingsScreenKeys.settingsScrollableScreenMenu,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - General Settings
            _SectionTitle(
              context.loc.settingsScreenSectionGeneral,
            ),
            const SizedBox(height: 22.0),
            //ANCHOR - Language
            MenuItemWidget.labeledArrow(
              key: SettingsScreenKeys.settingsLanguageButton,
              context: context,
              assetName: Svgs.language,
              color: context.colors.onBackground,
              title: context.loc.language,
              label: languageCode.toUpperCase(),
              onPressed: () => context.push(LanguageSettingsScreen.routeName),
            ),
            //ANCHOR - Reference rate
            MenuItemWidget.labeledArrow(
              key: SettingsScreenKeys.settingsReferenceRateButton,
              context: context,
              assetName: Svgs.exchangeRate,
              color: context.colors.onBackground,
              title: context.loc.refExRateSettingsScreenTitle,
              label: currentRate.currency.value,
              onPressed: () =>
                  context.push(ExchangeRateSettingsScreen.routeName),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Region
            MenuItemWidget.labeledArrow(
              key: SettingsScreenKeys.settingsRegionButton,
              context: context,
              assetName: region?.flagSvg ?? Svgs.region,
              color: context.colors.onBackground,
              title: context.loc.region,
              label: region?.name ?? '',
              onPressed: () => context.push(RegionSettingsScreen.routeName),
            ),
            const SizedBox(height: 4.0),

            //ANCHOR - Dark Mode
            MenuItemWidget.switchItem(
              key: SettingsScreenKeys.settingsDarkModeButton,
              context: context,
              value: darkMode,
              enabled: !botevMode,
              assetName: Svgs.darkMode,
              title: context.loc.settingsScreenItemDarkMode,
              onPressed: () => ref.read(prefsProvider).switchDarkMode(),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Botev Mode
            MenuItemWidget.switchItem(
              key: SettingsScreenKeys.settingsBotevModeButton,
              context: context,
              value: botevMode,
              assetName: darkMode ? Svgs.botevDark : Svgs.botev,
              multicolor: true,
              iconPadding: const EdgeInsets.all(8.0),
              title: context.loc.settingsScreenItemBotevMode,
              onPressed: () => ref.read(prefsProvider).switchBotevMode(),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Block Explorer
            MenuItemWidget.arrow(
              key: SettingsScreenKeys.settingsBlockExplorerButton,
              context: context,
              assetName: Svgs.blockExplorer,
              color: context.colors.onBackground,
              title: context.loc.settingsScreenItemExplorer,
              onPressed: () =>
                  context.push(BlockExplorerSettingsScreen.routeName),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Get Help
            MenuItemWidget(
              key: SettingsScreenKeys.settingsGetHelpSupportButton,
              assetName: Svgs.support,
              title: context.loc.getHelpSupportScreenTitle,
              color: AquaColors.lotion,
              onPressed: () => context.push(HelpSupportScreen.routeName),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Electrum Server
            if (isCustomElectrumUrlEnabled) ...[
              //TODO: In order to release this feature, we need to get broadcasting of hex txs and psbts working through GDK, so they can broadcast through the custom endpoint set by user
              MenuItemWidget.arrow(
                key: SettingsScreenKeys.settingsElectrumServerButton,
                context: context,
                assetName: Svgs.blockExplorer,
                title: context.loc.electrumServer,
                onPressed: () =>
                    context.push(ElectrumServerSettingsScreen.routeName),
              ),
            ],
            const SizedBox(height: 36.0),

            //ANCHOR - Security Settings
            _SectionTitle(
              context.loc.settingsScreenSectionSecurity,
            ),
            const SizedBox(height: 22.0),
            //ANCHOR - Biometric
            if (biometricAuth != null && biometricAuth.isDeviceSupported) ...[
              MenuItemWidget.switchItem(
                key: SettingsScreenKeys.settingsBiometricAuthenticationButton,
                context: context,
                value: biometricAuth.enabled,
                assetName: Svgs.touch,
                title: context.loc.settingsScreenItemBiometricAuth,
                onPressed: () {
                  if (biometricAuth.available) {
                    ref.read(biometricAuthProvider.notifier).toggle(
                          reason:
                              context.loc.biometricAuthenticationDescription,
                        );
                  } else if (Platform.isAndroid) {
                    // on Android, open settings security screen
                    AppSettings.openAppSettings(type: AppSettingsType.security);
                  } else {
                    // on iOS, security type is not supported, so open general settings
                    AppSettings.openAppSettings();
                  }
                },
              ),
              const SizedBox(height: 4.0),
            ],
            //ANCHOR - PIN
            MenuItemWidget.switchItem(
              context: context,
              value: pinEnabled,
              assetName: Svgs.passcode,
              title: context.loc.settingsScreenItemPin,
              onPressed: () async {
                if (!pinEnabled) {
                  context.push(PinWarningScreen.routeName);
                  return;
                }

                final success = await context.push(CheckPinScreen.routeName,
                    extra: CheckPinScreenArguments(
                        onSuccessAction: CheckAction.pull,
                        canCancel: true,
                        description: context.loc.pinScreenDisabledDescription));
                if (success == true) {
                  ref.read(pinAuthProvider.notifier).disable();
                }
              },
            ),
            const SizedBox(height: 36.0),
            //ANCHOR - Advanced Settings
            _SectionTitle(
              context.loc.settingsScreenSectionAdvanced,
            ),
            const SizedBox(height: 22.0),
            //ANCHOR - Manage Assets
            MenuItemWidget.arrow(
              key: SettingsScreenKeys.settingsManageAssetsButton,
              context: context,
              assetName: Svgs.assets,
              color: context.colors.onBackground,
              title: context.loc.manageAssets,
              onPressed: () => context.push(ManageAssetsScreen.routeName),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Recovery Phrase
            MenuItemWidget.arrow(
              key: SettingsScreenKeys.settingsViewSeedPhraseButton,
              context: context,
              assetName: Svgs.recovery,
              color: context.colors.onBackground,
              title: context.loc.settingsScreenItemPhrase,
              onPressed: () =>
                  context.push(WalletPhraseWarningScreen.routeName),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR: Watch Only Export
            MenuItemWidget.arrow(
              key: SettingsScreenKeys.settingsWatchOnlyButton,
              context: context,
              title: context.loc.watchOnlyScreenTitle,
              assetName: Svgs.watchOnly,
              color: context.colors.onBackground,
              onPressed: () => context.push(WatchOnlyListScreen.routeName),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - SEEDQR
            if (isSeedQrEnabled) ...[
              MenuItemWidget.arrow(
                context: context,
                assetName: Svgs.qr,
                title: context.loc.settingsScreenItemViewSeedQR,
                onPressed: () => context.push(WalletRecoveryQRScreen.routeName),
              ),
              const SizedBox(height: 4.0),
            ],
            //ANCHOR - Direct Peg In
            MenuItemWidget.switchItem(
              key: SettingsScreenKeys.settingsDirectPegInButton,
              context: context,
              value: isDirectPegInEnabled,
              assetName: Svgs.directPegIn,
              title: context.loc.directPegIn,
              onPressed: () => ref.read(prefsProvider).switchDirectPegIn(),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Poker Chip
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.pokerchip,
              color: context.colors.onBackground,
              title: context.loc.bitcoinChip,
              onPressed: () => context.push(PokerchipScreen.routeName),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Share logs
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.shareAlt,
              color: context.colors.onBackground,
              title: context.loc.settingsScreenItemShareLogs,
              onPressed: () => downloadFile(logger.internalLogger.history
                  .text(timeFormat: logger.internalLogger.settings.timeFormat)),
            ),
            const SizedBox(height: 4.0),
            //ANCHOR - Experimental Feature
            if (experimentalFeaturesEnabled) ...[
              MenuItemWidget.arrow(
                assetName: Svgs.flask,
                context: context,
                title: AppLocalizations.of(context)!
                    .settingsScreenItemExperimentalFeatures,
                iconPadding: const EdgeInsets.all(14.0),
                onPressed: () =>
                    context.push(ExperimentalFeaturesScreen.routeName),
              ),
              const SizedBox(height: 4.0),
            ],
            //ANCHOR - Remove Wallet
            MenuItemWidget.arrow(
              key: SettingsScreenKeys.settingsRemoveWalletButton,
              assetName: Svgs.removeWallet,
              context: context,
              color: Theme.of(context).colors.walletRemoveTextColor,
              title: context.loc.settingsScreenItemRemoveWallet,
              onPressed: () =>
                  context.push(RemoveWalletConfirmScreen.routeName),
            ),
            Container(
              margin: const EdgeInsets.only(
                top: 30.0,
                bottom: 36.0,
              ),
              child: Divider(
                height: 0,
                thickness: 2.0,
                color: Theme.of(context).colors.divider,
              ),
            ),
            //ANCHOR - Jan3 Logo
            Center(
              child: SvgPicture.asset(
                darkMode
                    ? Svgs.jan3LogoWithAquaLight
                    : Svgs.jan3LogoWithAquaDark,
              ),
            ),
            const SizedBox(height: 11.0),
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
            const SizedBox(height: 14.0),
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
            const SizedBox(height: 20.0),
            //ANCHOR - Socials
            SettingsSocialLinks(
              onLinkClick: (url) => ref.read(urlLauncherProvider).open(url),
            ),
            const SizedBox(height: 20.0),
            //ANCHOR - Version
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colors.versionBackground,
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              ),
              alignment: Alignment.center,
              child: Text(
                context.loc.settingsScreenItemVersion(versionText),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colors.versionForeground,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
    this._text, {
    // ignore: unused_element
    this.collapsable = false,
    // ignore: unused_element
    this.expanded = false,
    // ignore: unused_element
    this.onExpanded,
  });

  final String _text;
  final bool collapsable;
  final bool expanded;
  final Function(bool value)? onExpanded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: collapsable ? () => onExpanded?.call(!expanded) : null,
      child: Container(
        margin: const EdgeInsets.only(left: 10.0),
        child: Row(
          children: [
            Text(
              _text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20.0,
                  ),
            ),
            if (collapsable) ...{
              const Spacer(),
              Transform.rotate(
                angle: expanded ? pi / 2 : 0,
                child: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: 15.0,
                  color: Theme.of(context).colors.onBackground,
                ),
              ),
              const SizedBox(width: 9.0),
            }
          ],
        ),
      ),
    );
  }
}
