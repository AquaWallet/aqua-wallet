import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/settings/settings.dart';
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
    final env = ref.watch(envProvider);
    final version = ref.watch(versionProvider).asData?.value ?? '';
    final versionText = kDebugMode ? '$version (${env.name})' : version;
    final languageCode = ref.watch(languageProvider(context)
        .select((p) => p.currentLanguage.languageCode));
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));

    ref.listen(
      recoveryPhraseRequestProvider,
      (_, state) => state?.when(
        authorized: () => Navigator.of(context).pushNamed(
          WalletRecoveryPhraseScreen.routeName,
          arguments: RecoveryPhraseScreenArguments(isOnboarding: false),
        ),
        verificationFailed: () => context.showErrorSnackbar(
          AppLocalizations.of(context)!.recoveryPhraseAuthorizationError,
        ),
      ),
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        title: AppLocalizations.of(context)!.settingsScreenTitle,
        showActionButton: false,
      ),
      body: Stack(
        children: [
          //ANCHOR - Background
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 400.h,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.only(top: 20.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //ANCHOR - Get Help
                    MenuItemWidget.labeledArrow(
                      context: context,
                      assetName: Svgs.support,
                      title: AppLocalizations.of(context)!
                          .getHelpSupportScreenTitle,
                      color: AquaColors.lotion,
                      label: '',
                      onPressed: () => Navigator.of(context)
                          .pushNamed(HelpSupportScreen.routeName),
                      isEnabled: true,
                    ),
                    SizedBox(height: 22.h),
                    //ANCHOR - General Settings
                    _SectionTitle(
                      AppLocalizations.of(context)!
                          .settingsScreenSectionGeneral,
                    ),
                    SizedBox(height: 22.h),
                    //ANCHOR - Language
                    MenuItemWidget.labeledArrow(
                      context: context,
                      assetName: Svgs.language,
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemLanguage,
                      label: languageCode.toUpperCase(),
                      onPressed: () => Navigator.of(context)
                          .pushNamed(LanguageSettingsScreen.routeName),
                      isEnabled: true,
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Region
                    MenuItemWidget.labeledArrow(
                      context: context,
                      assetName: region?.iso ?? Svgs.region,
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemRegion,
                      label: region?.name ?? '',
                      onPressed: () => Navigator.of(context)
                          .pushNamed(RegionSettingsScreen.routeName),
                      isEnabled: true,
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Dark Mode
                    MenuItemWidget.switchItem(
                      context: context,
                      value: darkMode,
                      enabled: !botevMode,
                      assetName: Svgs.darkMode,
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemDarkMode,
                      onPressed: () => ref.read(prefsProvider).switchDarkMode(),
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Botev Mode
                    MenuItemWidget.switchItem(
                      context: context,
                      value: botevMode,
                      assetName: Svgs.botev,
                      iconPadding: EdgeInsets.all(8.r),
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemBotevMode,
                      onPressed: () =>
                          ref.read(prefsProvider).switchBotevMode(),
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Block Explorer
                    MenuItemWidget.arrow(
                      context: context,
                      assetName: Svgs.blockExplorer,
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemExplorer,
                      onPressed: () => Navigator.of(context)
                          .pushNamed(BlockExplorerSettingsScreen.routeName),
                    ),
                    SizedBox(height: 40.h),
                    //ANCHOR - Advanced Settings
                    _SectionTitle(
                      AppLocalizations.of(context)!
                          .settingsScreenSectionAdvanced,
                    ),
                    SizedBox(height: 34.h),
                    //ANCHOR - Manage Assets
                    MenuItemWidget.arrow(
                      context: context,
                      assetName: Svgs.assets,
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemAssets,
                      onPressed: () => Navigator.of(context)
                          .pushNamed(ManageAssetsScreen.routeName),
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Recovery Phrase
                    MenuItemWidget.arrow(
                      context: context,
                      assetName: Svgs.recovery,
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemPhrase,
                      onPressed: () => ref
                          .read(recoveryPhraseRequestProvider.notifier)
                          .requestRecoveryPhrase(),
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Poker Chip
                    MenuItemWidget.arrow(
                      context: context,
                      assetName: Svgs.pokerchip,
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemPokerChip,
                      onPressed: () => Navigator.of(context)
                          .pushNamed(PokerchipScreen.routeName),
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Remove Wallet
                    MenuItemWidget.arrow(
                      assetName: Svgs.removeWallet,
                      context: context,
                      color: const Color(0xFFFF8F8F),
                      title: AppLocalizations.of(context)!
                          .settingsScreenItemRemoveWallet,
                      onPressed: () => Navigator.of(context)
                          .pushNamed(RemoveWalletConfirmScreen.routeName),
                    ),
                    SizedBox(height: 34.h),
                    //ANCHOR - Jan3 Logo
                    Center(
                      child: SvgPicture.asset(
                        darkMode ? Svgs.jan3LogoLight : Svgs.jan3LogoDark,
                      ),
                    ),
                    SizedBox(height: 22.h),
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
                          text: AppLocalizations.of(context)!
                              .welcomeScreenToSDescriptionBold,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
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
                          text: AppLocalizations.of(context)!
                              .settingsScreenPrivacyDescription,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    //ANCHOR - Socials
                    SettingsSocialLinks(
                      onLinkClick: (url) =>
                          ref.read(urlLauncherProvider).open(url),
                    ),
                    SizedBox(height: 12.h),
                    //ANCHOR - Version
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.all(Radius.circular(5.r)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!
                            .settingsScreenItemVersion(versionText),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this._text);

  final String _text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 10.w),
      child: Text(
        _text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20.sp,
            ),
      ),
    );
  }
}
