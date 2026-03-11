import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class RestoreWalletScreen extends HookConsumerWidget {
  const RestoreWalletScreen({super.key});

  static const routePath = 'restore-wallet';
  static const fullRoute = '${OnboardingScreen.routePath}/$routePath';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// BIP39 has support for 12, 15, 18, 21, and 24 word seeds

    ///This variable is only for testing purposes
    ///amount of fields should be taken from backend etc.
    const wordSeedFieldsCount = 12;

    final aquaColors = context.aquaColors;
    final loc = context.loc;

    final pageController = usePageController();

    final controllers = [
      for (int i = 0; i < wordSeedFieldsCount; i++) useTextEditingController()
    ];

    // State to track validation for each field
    final validationStates = [
      for (int i = 0; i < wordSeedFieldsCount; i++) useState(false)
    ];

    // Calculate number of pages (4 controllers per page which is maxNumberOfSeedWordsPerPage)
    final numberOfPages =
        (wordSeedFieldsCount / maxNumberOfSeedWordsPerPage).ceil();

    bool isValidSeedWord(String word) {
      return testSeedWords.contains(word.trim().toLowerCase());
    }

    // Single useEffect to handle all validations
    useEffect(() {
      void updateValidation() {
        for (int i = 0; i < controllers.length; i++) {
          validationStates[i].value = isValidSeedWord(controllers[i].text);
        }
      }

      // Add listeners to all controllers
      for (final controller in controllers) {
        controller.addListener(updateValidation);
      }

      return () {
        // Remove listeners on disposal
        for (final controller in controllers) {
          controller.removeListener(updateValidation);
        }
      };
    }, controllers);

    // Dynamic validation for each page
    // This checks from mock data that is also used for showing suggested seed words
    final pageValidations = useMemoized(() {
      final validations = <bool>[];
      for (int pageIndex = 0; pageIndex < numberOfPages; pageIndex++) {
        final startIndex = pageIndex * maxNumberOfSeedWordsPerPage;
        final endIndex =
            (startIndex + maxNumberOfSeedWordsPerPage > wordSeedFieldsCount)
                ? wordSeedFieldsCount
                : startIndex + maxNumberOfSeedWordsPerPage;

        final pageValid = validationStates
            .sublist(startIndex, endIndex)
            .every((state) => state.value);
        validations.add(pageValid);
      }
      return validations;
    }, validationStates.map((state) => state.value).toList());

    // Check if all pages are valid (for final page)
    final allPagesValid = useMemoized(() {
      return pageValidations.every((isValid) => isValid);
    }, [pageValidations]);

    return Material(
      color: aquaColors.surfaceBackground,
      child: Padding(
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
              height: onboardingContentHeight,
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (int pageIndex = 0;
                      pageIndex < numberOfPages;
                      pageIndex++)
                    () {
                      final startIndex =
                          pageIndex * maxNumberOfSeedWordsPerPage;
                      final endIndex =
                          (startIndex + maxNumberOfSeedWordsPerPage >
                                  wordSeedFieldsCount)
                              ? wordSeedFieldsCount
                              : startIndex + maxNumberOfSeedWordsPerPage;

                      final pageControllers =
                          controllers.sublist(startIndex, endIndex);
                      final pageValidationStates =
                          validationStates.sublist(startIndex, endIndex);
                      final isLastPage = pageIndex == numberOfPages - 1;

                      return SeedWordOnboardingContent(
                        loc: loc,
                        pageIndex: pageIndex,
                        controllers: pageControllers,
                        aquaColors: aquaColors,
                        validationStates: pageValidationStates,
                        allValid: isLastPage
                            ? allPagesValid
                            : pageValidations[pageIndex],
                        hints: testSeedWords,
                        pageController: pageController,
                        isLastPage: isLastPage,
                        startingFieldNumber:
                            startIndex + 1, // For display purposes (1-based),
                      );
                    }(),
                ],
              ),
            ),

            ///TODO: Take version from package/hook/riverpod
            const AquaText.caption1(text: 'App Version 0.2.7 (160)'),
          ],
        ),
      ),
    );
  }
}
