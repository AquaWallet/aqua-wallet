import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class WalletDetailsSettings extends HookConsumerWidget {
  const WalletDetailsSettings({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final hasTextChanged = useState(false);

    useEffect(() {
      void listener() {
        hasTextChanged.value = textController.text.isNotEmpty;
      }

      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

    final sizeIfScreen = MediaQuery.sizeOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AquaTextField(
          label: loc.walletName,
          controller: textController,
          maxLength: 23,
          assistiveText: loc.max23Characters,
          trailingIcon: hasTextChanged.value
              ? AquaIcon.close(
                  color: aquaColors.textTertiary,
                  size: 16,
                  onTap: textController.clear,
                )
              : null,
        ),
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            children: [
              AquaListItem(
                colors: aquaColors,
                iconLeading: AquaIcon.biometricFingerprint(
                    color: aquaColors.textPrimary),
                title: 'Wallet ID',
                titleColor: aquaColors.textPrimary,
                titleTrailing: 'B89AB7BC',
                titleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                colors: aquaColors,
                iconLeading: AquaIcon.key(color: aquaColors.textPrimary),
                title: loc.pinScreenWarningViewRecovery,
                titleColor: aquaColors.textPrimary,
                iconTrailing:
                    AquaIcon.chevronRight(color: aquaColors.textSecondary),
                onTap: () {
                  RecoveryPhraseSideSheet.show(
                      context: context, loc: loc, aquaColors: aquaColors);
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
            iconLeading: AquaIcon.danger(color: aquaColors.accentDanger),
            title: 'Remove Wallet',
            titleColor: aquaColors.accentDanger,
            iconTrailing: AquaIcon.chevronRight(color: aquaColors.accentDanger),
            onTap: () {
              final currentWallet = ref.read(currentWalletProvider);
              AquaModalSheet.show(
                context,
                copiedToClipboardText: loc.copiedToClipboard,
                title: loc.areYouSure,
                message: loc.deleteWalletWarning(currentWallet!.name),
                primaryButtonText: 'Remove Wallet',
                secondaryButtonText: loc.cancel,
                messageTertiary: loc.thisActionIsPermanent,

                ///TODO: add tool tip message after successful removal of wallet
                ///and redirection to whatever page is appropriate
                onPrimaryButtonTap: () => context.pop(),
                onSecondaryButtonTap: () => context.pop(),
                bottomPadding: sizeIfScreen.height / screenParts,
                primaryButtonVariant: AquaButtonVariant.error,
                icon: AquaIcon.danger(
                  color: Colors.white,
                ),
                iconVariant: AquaRingedIconVariant.danger,
                colors: aquaColors,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        AquaButton.primary(
          text: loc.save,
          onPressed: hasTextChanged.value
              ? () {
                  ///TODO: implement on click
                }
              : null,
        ),
      ],
    );
  }
}

class RecoveryPhraseSideSheet extends StatelessWidget {
  const RecoveryPhraseSideSheet({
    required this.aquaColors,
    required this.loc,
    super.key,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.warningPhraseScreenTitle,
      showBackButton: false,
      widgetAtBottom: AquaButton.primary(
        text: 'Show Seed Phrase',
        onPressed: () {
          ShowSeedPhrasesSideSheet.show(
            context: context,
            loc: loc,
            aquaColors: aquaColors,
          );
        },
      ),
      children: [
        AquaText.body1(
          maxLines: 5,
          text:
              '''Your 12-word seed is your wallet’s key, keep it secure. Ensure no one can see your screen, write it on paper, and store it safely. Avoid digital copies; for extra security, consider a metal backup later.''',
          color: aquaColors.textSecondary,
        ),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                colors: aquaColors,
                iconLeading: AquaIcon.home(
                  color: aquaColors.textPrimary,
                ),
                title: loc.warningPhraseScreenFirstCardTitle,
                titleColor: aquaColors.textPrimary,
                subtitle: loc.warningPhraseScreenFirstCardText,
                subtitleColor: aquaColors.textSecondary,
              ),
              AquaListItem(
                colors: aquaColors,
                iconLeading: AquaIcon.danger(
                  color: aquaColors.textPrimary,
                ),
                title: loc.warningPhraseScreenSecondCardTitle,
                titleColor: aquaColors.textPrimary,
                subtitle: loc.warningPhraseScreenSecondCardText,
                subtitleColor: aquaColors.textSecondary,
              ),
              AquaListItem(
                colors: aquaColors,
                iconLeading: AquaIcon.shield(
                  color: aquaColors.textPrimary,
                ),
                title: loc.verify,
                titleColor: aquaColors.textPrimary,
                subtitle: loc.warningPhraseScreenThirdCardText,
                subtitleColor: aquaColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AppLocalizations loc,
    required AquaColors aquaColors,
  }) async {
    await SideSheet.right<bool>(
      body: RecoveryPhraseSideSheet(
        loc: loc,
        aquaColors: aquaColors,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ShowSeedPhrasesSideSheet extends StatelessWidget {
  const ShowSeedPhrasesSideSheet({
    required this.aquaColors,
    required this.loc,
    super.key,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final seedWords = testSeedWords.sublist(0, 12);
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.warningPhraseScreenTitle,
      onBackPress: () {
        Navigator.pop(context);
        RecoveryPhraseSideSheet.show(
          context: context,
          loc: loc,
          aquaColors: aquaColors,
        );
      },
      widgetAtBottom: AquaButton.secondary(
        text: 'Hide Seed Phrase',
        onPressed: () => Navigator.pop(context),
      ),
      children: [
        OutlineContainer(
          aquaColors: aquaColors,
          child: ListView.separated(
              shrinkWrap: true,
              itemCount: seedWords.length,
              separatorBuilder: (context, index) => const Divider(
                    height: 0,
                  ),
              itemBuilder: (context, index) {
                return AquaSeedListItem(
                  index: index,
                  text: seedWords[index],
                  colors: aquaColors,
                );
              }),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AppLocalizations loc,
    required AquaColors aquaColors,
  }) async {
    Navigator.pop(context);
    await SideSheet.right<bool>(
      body: ShowSeedPhrasesSideSheet(
        loc: loc,
        aquaColors: aquaColors,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
