import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/watch_only/watch_only.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsTab extends HookConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    ref.listen(
      recoveryPhraseRequestProvider,
      (_, state) => state?.when(
        authorized: () => Navigator.of(context).pushNamed(
          WalletRecoveryPhraseScreen.routeName,
          arguments: RecoveryPhraseScreenArguments(isOnboarding: false),
        ),
        verificationFailed: () => context.showErrorSnackbar(
          context.loc.recoveryPhraseAuthorizationError,
        ),
      ),
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        title: context.loc.settingsScreenTitle,
        showActionButton: false,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
        onTitlePressed: () =>
            ref.read(featureUnlockTapCountProvider.notifier).increment(),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Get Help
            MenuItemWidget(
              assetName: Svgs.support,
              title: context.loc.getHelpSupportScreenTitle,
              color: AquaColors.lotion,
              onPressed: () =>
                  Navigator.of(context).pushNamed(HelpSupportScreen.routeName),
            ),
            SizedBox(height: 22.h),
            //ANCHOR - General Settings
            _SectionTitle(
              context.loc.settingsScreenSectionGeneral,
            ),
            SizedBox(height: 22.h),
            //ANCHOR - Language
            MenuItemWidget.labeledArrow(
              context: context,
              assetName: Svgs.language,
              title: context.loc.settingsScreenItemLanguage,
              label: languageCode.toUpperCase(),
              onPressed: () => Navigator.of(context)
                  .pushNamed(LanguageSettingsScreen.routeName),
            ),
            //ANCHOR - Reference rate
            MenuItemWidget.labeledArrow(
              context: context,
              assetName: Svgs.exchangeRate,
              title: context.loc.refExRateSettingsScreenTitle,
              label: currentRate.currency.value,
              onPressed: () => Navigator.of(context)
                  .pushNamed(ExchangeRateSettingsScreen.routeName),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - Region
            MenuItemWidget.labeledArrow(
              context: context,
              assetName: region?.flagSvg ?? Svgs.region,
              title: context.loc.settingsScreenItemRegion,
              label: region?.name ?? '',
              onPressed: () => Navigator.of(context)
                  .pushNamed(RegionSettingsScreen.routeName),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - Biometric
            if (biometricAuth != null && biometricAuth.isDeviceSupported) ...[
              MenuItemWidget.switchItem(
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
              SizedBox(height: 4.h),
            ],
            //ANCHOR - Dark Mode
            MenuItemWidget.switchItem(
              context: context,
              value: darkMode,
              enabled: !botevMode,
              assetName: Svgs.darkMode,
              title: context.loc.settingsScreenItemDarkMode,
              onPressed: () => ref.read(prefsProvider).switchDarkMode(),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - Botev Mode
            MenuItemWidget.switchItem(
              context: context,
              value: botevMode,
              assetName: Svgs.botev,
              iconPadding: EdgeInsets.all(8.r),
              title: context.loc.settingsScreenItemBotevMode,
              multicolor: true,
              onPressed: () => ref.read(prefsProvider).switchBotevMode(),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - Block Explorer
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.blockExplorer,
              title: context.loc.settingsScreenItemExplorer,
              onPressed: () => Navigator.of(context)
                  .pushNamed(BlockExplorerSettingsScreen.routeName),
            ),
            SizedBox(height: 36.h),
            //ANCHOR - Advanced Settings
            _SectionTitle(
              context.loc.settingsScreenSectionAdvanced,
            ),
            SizedBox(height: 22.h),
            //ANCHOR - Manage Assets
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.assets,
              title: context.loc.settingsScreenItemAssets,
              onPressed: () =>
                  Navigator.of(context).pushNamed(ManageAssetsScreen.routeName),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - Recovery Phrase
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.recovery,
              title: context.loc.settingsScreenItemPhrase,
              onPressed: () => ref
                  .read(recoveryPhraseRequestProvider.notifier)
                  .requestRecoveryPhrase(),
            ),
            SizedBox(height: 4.h),
            //ANCHOR: Watch Only Export
            MenuItemWidget.arrow(
              context: context,
              title: context.loc.watchOnlyScreenTitle,
              assetName: Svgs.tabWallet,
              color: context.colorScheme.onBackground,
              onPressed: () => Navigator.of(context)
                  .pushNamed(WatchOnlyListScreen.routeName),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - SEEDQR
            if (isSeedQrEnabled) ...[
              MenuItemWidget.arrow(
                context: context,
                assetName: Svgs.qr,
                title: context.loc.settingsScreenItemViewSeedQR,
                onPressed: () => Navigator.of(context)
                    .pushNamed(WalletRecoveryQRScreen.routeName),
              ),
              SizedBox(height: 4.h),
            ],
            //ANCHOR - Direct Peg In
            MenuItemWidget.switchItem(
              context: context,
              value: isDirectPegInEnabled,
              assetName: Svgs.directPegIn,
              title: context.loc.settingsScreenItemDirectPegIn,
              onPressed: () => ref.read(prefsProvider).switchDirectPegIn(),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - Poker Chip
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.pokerchip,
              title: context.loc.settingsScreenItemPokerChip,
              onPressed: () =>
                  Navigator.of(context).pushNamed(PokerchipScreen.routeName),
            ),
            SizedBox(height: 4.h),
            //ANCHOR - Experimental Feature
            if (experimentalFeaturesEnabled) ...[
              MenuItemWidget.arrow(
                assetName: Svgs.flask,
                context: context,
                title: AppLocalizations.of(context)!
                    .settingsScreenItemExperimentalFeatures,
                iconPadding: EdgeInsets.all(14.r),
                onPressed: () => Navigator.of(context)
                    .pushNamed(ExperimentalFeaturesScreen.routeName),
              ),
              SizedBox(height: 4.h),
            ],
            //ANCHOR - Remove Wallet
            MenuItemWidget.arrow(
              assetName: Svgs.removeWallet,
              context: context,
              color: Theme.of(context).colors.walletRemoveTextColor,
              title: context.loc.settingsScreenItemRemoveWallet,
              onPressed: () => Navigator.of(context)
                  .pushNamed(RemoveWalletConfirmScreen.routeName),
            ),
            Container(
              margin: EdgeInsets.only(
                top: 30.h,
                bottom: 36.h,
              ),
              child: Divider(
                height: 0,
                thickness: 2.h,
                color: Theme.of(context).colors.divider,
              ),
            ),
            //ANCHOR - Jan3 Logo
            Center(
              child: SvgPicture.asset(
                darkMode ? Svgs.jan3LogoLight : Svgs.jan3LogoDark,
              ),
            ),
            SizedBox(height: 11.h),
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
            SizedBox(height: 14.h),
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
                  text: context.loc.settingsScreenPrivacyDescription,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            //ANCHOR - Socials
            SettingsSocialLinks(
              onLinkClick: (url) => ref.read(urlLauncherProvider).open(url),
            ),
            SizedBox(height: 20.h),
            //ANCHOR - Version
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colors.versionBackground,
                borderRadius: BorderRadius.all(Radius.circular(5.r)),
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
        margin: EdgeInsets.only(left: 10.w),
        child: Row(
          children: [
            Text(
              _text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20.sp,
                  ),
            ),
            if (collapsable) ...{
              const Spacer(),
              Transform.rotate(
                angle: expanded ? pi / 2 : 0,
                child: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: 15.r,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              SizedBox(width: 9.w),
            }
          ],
        ),
      ),
    );
  }
}
