import 'package:aqua/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/account/providers/providers.dart';
import 'package:aqua/features/feature_flags/providers/setup_config_provider.dart';
import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_components/ui_components.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  static const routeName = '/accountSettings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletId = ref.watch(currentWalletIdSyncProvider);
    final profile = ref.watch(jan3AuthProvider(walletId)).valueOrNull?.profile;
    final email = profile?.email;
    final isLnAddressEnabled = ref.watch(lnAddressRemoteFlagProvider);
    final lnAddressState = ref.watch(lightningAddressProvider);

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        showBackButton: true,
        colors: context.aquaColors,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AquaText.h4Medium(
                text: context.loc.accountSettingsTitle,
              ),
              const SizedBox(height: 8),
              AquaText.body1(
                height: 1.4,
                text: context.loc.accountSettingsSubtitle,
                color: context.aquaColors.textSecondary,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AquaListItem(
                      title: context.loc.jan3AccountTitle,
                      subtitle: email,
                      colors: context.aquaColors,
                      titleColor: context.aquaColors.textSecondary,
                      subtitleColor: context.aquaColors.textSecondary,
                      disabled: true,
                    ),
                    if (lnAddressState.isRegistered) ...[
                      const SizedBox(height: 1.0),
                      if (lnAddressState!.isToggled)
                        AquaListItem(
                          colors: context.aquaColors,
                          title:
                              context.loc.accountSettingsLightningAddressLabel,
                          subtitle: lnAddressState.address,
                          disabled: !isLnAddressEnabled,
                          iconTrailing: isLnAddressEnabled
                              ? AquaIcon.edit(
                                  size: 18,
                                  color: context.aquaColors.textSecondary,
                                )
                              : GestureDetector(
                                  onTap: () => showCustomAlertDialog(
                                    context: context,
                                    uiModel: CustomAlertDialogUiModel(
                                      title: context.loc
                                          .accountSettingsLnAddressDisabledTitle,
                                      subtitle: context.loc
                                          .accountSettingsLnAddressDisabledMessage,
                                      buttonTitle: context.loc.ok,
                                      onButtonPressed: context.pop,
                                    ),
                                  ),
                                  child: AquaIcon.danger(
                                    size: 18,
                                    color: context.aquaColors.accentWarning,
                                  ),
                                ),
                          onTap: isLnAddressEnabled
                              ? () {
                                  AquaBottomSheet.show(
                                    context,
                                    colors: context.aquaColors,
                                    content:
                                        const LnAddressEditBottomSheetContent(),
                                  );
                                }
                              : null,
                        )
                      else
                        AquaListItem(
                          colors: context.aquaColors,
                          title: context.loc.accountSettingsGetLightningAddress,
                          titleColor: context.aquaColors.accentBrand,
                          iconTrailing: AquaIcon.chevronRight(
                            size: 18,
                            color: context.aquaColors.accentBrand,
                          ),
                          onTap: () =>
                              context.push(LnAddressGiftScreen.routeName),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AquaCard(
                borderRadius: BorderRadius.circular(8),
                child: AquaListItem(
                  colors: context.aquaColors,
                  titleColor: context.aquaColors.accentBrand,
                  title: context.loc.jan3InviteFriends,
                  iconTrailing: AquaIcon.chevronRight(
                    size: 18,
                    color: context.aquaColors.accentBrand,
                  ),
                  onTap: () {
                    final message =
                        context.loc.jan3InviteMessage(aquaDownloadUrl);
                    Share.share(
                      message,
                      sharePositionOrigin: context.sharePositionOrigin,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
