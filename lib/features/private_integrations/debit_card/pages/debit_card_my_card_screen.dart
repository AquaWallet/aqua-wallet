import 'package:aqua/config/router/extensions.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/auth/auth.dart';
import 'package:aqua/features/private_integrations/debit_card/debit_card.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DebitCardMyCardScreen extends HookConsumerWidget {
  const DebitCardMyCardScreen({super.key});

  static const routeName = '/debitCardMyCard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDetailsRevealed = useState(false);
    final cardsAsync = ref.watch(moonCardsProvider);
    final cards = useMemoized(
      () => cardsAsync.valueOrNull ?? [],
      [cardsAsync.isLoading],
    );

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(prefsProvider.notifier).setTheme(dark: true);
      });
      return null;
    }, []);

    ref
      ..listen(jan3AuthProvider, (_, data) {
        if (data.value is Jan3UserUnauthenticated) {
          context
            ..popUntilPath(AuthWrapper.routeName)
            ..push(DebitCardOnboardingScreen.routeName);
        }
      })
      ..listen(
        verificationRequestProvider,
        (_, state) => state?.when(
          authorized: () => isDetailsRevealed.value = !isDetailsRevealed.value,
          verificationFailed: () => context.showErrorSnackbar(
            context.loc.verificationFailed,
          ),
        ),
      );

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        backgroundColor: context.colors.inverseSurfaceColor,
        foregroundColor: context.colors.onBackground,
        iconForegroundColor: context.colors.onBackground,
        title: context.loc.myCard,
        onTitlePressed: () async {
          if (kDebugMode) {
            await ref.read(jan3AuthProvider.notifier).resetAccount();
            await ref.read(jan3AuthProvider.notifier).signOut();
          }
        },
      ),
      body: Skeletonizer(
        enabled: cardsAsync.isLoading,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              //ANCHOR - Balance
              MoonCardBalance(
                balance: cards.firstOrNull?.availableBalance ?? 0,
              ),
              const SizedBox(height: 23),
              //ANCHOR - Debit Card / Placeholder
              AspectRatio(
                aspectRatio: DebitCard.aspectRatio,
                child: !cardsAsync.isLoading && cards.isEmpty
                    ? CreateCardPlaceholder(
                        onCreateCard: () => ref
                            .read(moonCardsProvider.notifier)
                            .createDebitCard(),
                      )
                    : DebitCard(
                        card: cards.firstOrNull,
                        isRevealed: isDetailsRevealed.value,
                      ),
              ),
              const SizedBox(height: 13),
              Row(children: [
                //ANCHOR - Show/Hide Details Button
                Expanded(
                  child: Center(
                    child: DebitCardActionButton(
                      title: isDetailsRevealed.value
                          ? context.loc.hideDetails
                          : context.loc.showDetails,
                      icon: isDetailsRevealed.value
                          ? UiAssets.svgs.eyeHidden
                          : UiAssets.svgs.eye,
                      onTap: () {
                        if (isDetailsRevealed.value) {
                          isDetailsRevealed.value = false;
                        } else {
                          ref
                              .read(verificationRequestProvider.notifier)
                              .requestVerification(
                                message:
                                    context.loc.authenticateToRevealCardDetails,
                              );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                //ANCHOR - Add Balance Button
                Expanded(
                  child: Center(
                    child: DebitCardActionButton(
                      title: context.loc.addBalance,
                      icon: UiAssets.svgs.add,
                      onTap: () => context.push(DebitCardTopUpScreen.routeName),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 21),
              //ANCHOR - Card Limits
              //TODO: Use correct limit values
              const DebitCardLimit(
                availableAmount: 4000,
                usedAmount: 3000,
              ),
              const SizedBox(height: 33),
              //ANCHOR - Transactions
              const DebitCardTransactions(),
            ],
          ),
        ),
      ),
    );
  }
}
