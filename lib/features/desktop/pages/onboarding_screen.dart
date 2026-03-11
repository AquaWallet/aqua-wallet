import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aquaColors = context.aquaColors;
    final loc = context.loc;

    final widthOfScreen = MediaQuery.of(context).size.width;
    final leftHalfOfScreen = widthOfScreen * .55;

    return Material(
      color: aquaColors.surfaceBackground,
      child: Row(
        children: [
          Container(
            width: leftHalfOfScreen,
            color: aquaColors.surfaceBackground,
            padding: const EdgeInsets.all(50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UiAssets.svgs.aquaLogoColorSpaced.svg(
                  height: 30,
                  color: aquaColors.textPrimary,
                ),
                SizedBox(
                  width: onboardingContentWidth,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AquaText.subtitle(
                          text: loc.onboardingDesktopDescription,
                          maxLines: 5,
                          color: aquaColors.textSecondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      AquaButton.primary(
                        text: loc.createWallet,
                        onPressed: () async {
                          await showDialog(
                              context: context,
                              builder: (context) => Dialog.fullscreen(
                                    child: LoaderScreenWidget(
                                      message:
                                          loc.walletProcessingCreateMessage,
                                    ),
                                  )).then(
                            (value) {
                              ///This is for design purposes
                              ///this popup should be shown on desktop_home_screen

                              context.go(DesktopHomeScreen.routeName,
                                  extra: WalletOnboardingDialog.createWallet);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      AquaButton.secondary(
                        text: loc.restoreWallet,
                        onPressed: () {
                          context.go(RestoreWalletScreen.fullRoute);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: TermsAndPrivacyRichText(aquaColors: aquaColors),
                      )
                    ],
                  ),
                ),
                const AquaText.caption1(text: 'App Version 0.2.7 (160)'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: context.colorScheme.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ///TODO: change to appropriate illustration/animation
                  Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      color: aquaColors.surfaceBackground,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: AquaText.subtitle(
                        text: 'Illustration/Animation\nPlaceholder',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 343,
                    child: Column(
                      children: [
                        AquaText.h3SemiBold(
                          text: loc.onboardingYourBitcoinYourWay,
                          color: Colors.white,
                        ),
                        AquaText.body1Medium(
                          text: loc.onboardingYourBitcoinYourWayBody,
                          color: Colors.white,
                          maxLines: 4,
                          textAlign: TextAlign.center,
                        ),

                        ///TODO: some kind of page indicator needs to be added
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
