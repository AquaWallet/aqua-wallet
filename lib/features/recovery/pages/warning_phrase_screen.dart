import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/recovery/recovery.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletPhraseWarningScreen extends HookConsumerWidget {
  const WalletPhraseWarningScreen({super.key});

  static const routeName = '/walletPhraseWarningScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      verificationRequestProvider,
      (_, state) => state?.when(
        authorized: () => context.pushReplacement(
          WalletRecoveryPhraseScreen.routeName,
          extra: RecoveryPhraseScreenArguments(isOnboarding: false),
        ),
        verificationFailed: () => context.showErrorSnackbar(
          context.loc.verificationFailed,
        ),
      ),
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        iconBackgroundColor: context.colors.background,
        iconForegroundColor: context.colors.onBackground,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 80),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12.0),
                    Text(
                      context.loc.warningPhraseScreenTitle,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                letterSpacing: 1,
                                height: 1.2,
                              ),
                    ),
                    const SizedBox(height: 18.0),
                    Text(
                      context.loc.warningPhraseScreenSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            letterSpacing: .15,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    WarningMessage(
                        icon: Svgs.houseIcon,
                        title: context.loc.warningPhraseScreenFirstCardTitle,
                        message: context.loc.warningPhraseScreenFirstCardText),
                    const SizedBox(
                      height: 15,
                    ),
                    WarningMessage(
                        icon: Svgs.warningIcon,
                        title: context.loc.warningPhraseScreenSecondCardTitle,
                        message: context.loc.warningPhraseScreenSecondCardText),
                    const SizedBox(
                      height: 15,
                    ),
                    WarningMessage(
                        icon: Svgs.shieldCheckIcon,
                        title: context.loc.warningPhraseScreenThirdCardTitle,
                        message: context.loc.warningPhraseScreenThirdCardText),
                  ],
                ),
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: AquaElevatedButton(
                  child: Text(context.loc.warningPhraseScreenNextButton),
                  onPressed: () => ref
                      .read(verificationRequestProvider.notifier)
                      .requestVerification()),
            ),
          ],
        ),
      ),
    );
  }
}

class WarningMessage extends StatelessWidget {
  const WarningMessage(
      {super.key,
      required this.title,
      required this.message,
      required this.icon});

  final String title;
  final String message;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(9)),
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: context.colors.bottomNavBarBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(
        left: 53,
        right: 53,
        top: 16,
        bottom: 16,
      ),
      height: 140,
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            fit: BoxFit.scaleDown,
            colorFilter: ColorFilter.mode(
              context.colors.onBackground,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.2,
                  )),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    letterSpacing: .15,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  )),
        ],
      ),
    );
  }
}
