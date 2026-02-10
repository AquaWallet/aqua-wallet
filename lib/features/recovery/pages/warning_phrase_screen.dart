import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class WalletPhraseWarningScreen extends HookConsumerWidget {
  const WalletPhraseWarningScreen({
    super.key,
    this.arguments = const RecoveryPhraseScreenArguments(),
  });

  static const routeName = '/walletPhraseWarningScreen';

  final RecoveryPhraseScreenArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      verificationRequestProvider,
      (_, state) => state?.when(
        authorized: () => context.pushReplacement(
          WalletRecoveryPhraseScreen.routeName,
          extra: arguments,
        ),
        verificationFailed: () => context.showErrorSnackbar(
          context.loc.verificationFailed,
        ),
      ),
    );

    return Scaffold(
      appBar: AquaTopAppBar(
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12.0),
              AquaText.h4SemiBold(
                text: context.loc.warningPhraseScreenTitle,
              ),
              const SizedBox(height: 18.0),
              AquaText.body1(
                text: context.loc.backupRecoveryPhraseSubtitle,
                color: context.aquaColors.textSecondary,
                maxLines: 5,
              ),
              const SizedBox(
                height: 24,
              ),
              AquaCard(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    AquaListItem(
                      title: context.loc.warningPhraseScreenFirstCardTitle,
                      subtitle: context.loc.warningPhraseScreenFirstCardText,
                      iconLeading: AquaIcon.home(
                        color: context.aquaColors.textPrimary,
                        size: 24,
                      ),
                    ),
                    AquaDivider(
                      colors: context.aquaColors,
                    ),
                    AquaListItem(
                        iconLeading: AquaIcon.danger(
                            color: context.aquaColors.textPrimary),
                        title: context.loc.warningPhraseScreenSecondCardTitle,
                        subtitle:
                            context.loc.warningPhraseScreenSecondCardText),
                    AquaDivider(
                      colors: context.aquaColors,
                    ),
                    AquaListItem(
                      iconLeading: AquaIcon.shield(
                        color: context.aquaColors.textPrimary,
                        size: 24,
                      ),
                      title: context.loc.verify,
                      subtitle: context.loc.warningPhraseScreenThirdCardText,
                    )
                  ],
                ),
              ),
              const Spacer(),
              AquaButton.primary(
                  text: context.loc.showSeedPhrase,
                  onPressed: () => ref
                      .read(verificationRequestProvider.notifier)
                      .requestVerification()),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
