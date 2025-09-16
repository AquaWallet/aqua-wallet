import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/account/account.dart';
import 'package:coin_cz/features/private_integrations/debit_card/debit_card.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/gen/fonts.gen.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebitCardOnboardingScreen extends HookConsumerWidget {
  const DebitCardOnboardingScreen({super.key});

  static const routeName = '/debitCardOnboarding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTermsAccepted = useState(false);

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        showBackButton: false,
        backgroundColor: Colors.transparent,
        foregroundColor: context.colors.onBackground,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            //ANCHOR - Title
            Container(
              alignment: Alignment.center,
              child: Text(
                context.loc.visaRechargeable,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontFamily: UiFontFamily.helveticaNeue,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 21),
            //ANCHOR - Available Countries Link
            Container(
              alignment: Alignment.center,
              child: Text(
                context.loc.seeCountriesAvailableForUse,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colorScheme.primary,
                  fontSize: 14,
                  fontFamily: UiFontFamily.inter,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 21),
            //ANCHOR - Debit Card
            const AspectRatio(
              aspectRatio: 372 / 234,
              child: DebitCard(),
            ),
            const SizedBox(height: 21),
            //ANCHOR - Characteristics
            const Expanded(
              child: DebitCardCharacteristics(),
            ),
            const SizedBox(height: 21),
            Column(
              children: [
                //ANCHOR - Terms and Conditions
                DebitCardTermsCheckbox(
                  onTermsAccepted: isTermsAccepted,
                ),
                const SizedBox(height: 19),
                //ANCHOR - Sign Up Button
                AquaElevatedButton(
                  height: 52,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AquaColors.backgroundSkyBlue,
                    textStyle: TextStyle(
                      fontSize: 20,
                      height: 1.05,
                      color: context.colorScheme.onPrimary,
                      // fontFamily: UiFontFamily.helveticaNeue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: isTermsAccepted.value
                      ? () => context.push(Jan3LoginScreen.routeName)
                      : null,
                  child: Text(context.loc.signUp),
                ),
                const SizedBox(height: 14),
                //ANCHOR - Cancel Button
                AquaTextButton(
                  height: 52,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      height: 1.05,
                      fontFamily: UiFontFamily.helveticaNeue,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onPressed: () => context.pop(),
                  child: Text(context.loc.cancel),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
