import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class SeedWordOnboardingContent extends HookWidget {
  const SeedWordOnboardingContent({
    super.key,
    required this.loc,
    required this.controllers,
    required this.aquaColors,
    required this.validationStates,
    required this.allValid,
    required this.hints,
    required this.pageIndex,
    required this.pageController,
    this.isLastPage = false,
    this.startingFieldNumber = 1,
  });

  final AppLocalizations loc;
  final List<TextEditingController> controllers;
  final AquaColors aquaColors;
  final List<ValueNotifier<bool>> validationStates;
  final bool allValid;
  final List<String> hints;
  final int pageIndex;
  final PageController pageController;
  final bool isLastPage;
  final int startingFieldNumber;

  @override
  Widget build(BuildContext context) {
    // State for current search query
    final currentSearchQuery = useState('');

    // Filter hints based on search query
    final filteredHints = useMemoized(() {
      if (currentSearchQuery.value.isEmpty) {
        return hints;
      }

      return hints
          .where((hint) => hint
              .toLowerCase()
              .contains(currentSearchQuery.value.toLowerCase()))
          .toList();
    }, [currentSearchQuery.value, hints]);

    // Calculate dynamic height - single row that shows/hides
    final hintsContainerHeight = useMemoized(() {
      return filteredHints.isNotEmpty ? 50.0 : 0.0;
    }, [filteredHints.length]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AquaText.body1SemiBold(text: loc.enterSeedWords),
        const SizedBox(height: 24),
        ...List.generate(controllers.length, (index) {
          return AquaSeedInputField(
            index: startingFieldNumber + index,
            controller: controllers[index],
            colors: aquaColors,
            validationState: controllers[index].text.isEmpty
                ? SeedWordValidationState.none
                : validationStates[index].value
                    ? SeedWordValidationState.valid
                    : SeedWordValidationState.invalid,
            forceFocus: index == 0,
            onChanged: (value) {
              // Simple query update on change
              currentSearchQuery.value = value.trim();
            },
          );
        }),

        // Single scrollable row for hints
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: hintsContainerHeight,
          margin: EdgeInsets.symmetric(
            vertical: hintsContainerHeight > 0 ? 24 : 12,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: aquaColors.surfaceBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: hintsContainerHeight > 0
              ? Material(
                  color: aquaColors.surfacePrimary,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filteredHints.length,
                    itemBuilder: (context, index) {
                      final hint = filteredHints[index];

                      return InkWell(
                        onTap: () {
                          final firstThatsNotValidated =
                              validationStates.indexWhere((v) => !v.value);
                          controllers[firstThatsNotValidated != -1
                                  ? firstThatsNotValidated
                                  : controllers.length - 1]
                              .text = hint;
                          final lastWithText = controllers.lastWhere(
                            (c) => c.text.isNotEmpty,
                            orElse: () => controllers.first,
                          );
                          lastWithText.text = hint;
                        },
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: WidgetStateProperty.resolveWith((state) {
                          if (state.isHovered) {
                            return Colors.transparent;
                          }
                          return null;
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AquaText.body2SemiBold(text: hint),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => VerticalDivider(
                      width: 0,
                      color: aquaColors.surfaceBorderPrimary,
                    ),
                  ),
                )
              : null,
        ),

        AquaButton.primary(
          text: isLastPage ? loc.restoreWallet : loc.next,
          onPressed: allValid
              ? () async {
                  if (isLastPage) {
                    await showDialog(
                        context: context,
                        builder: (context) => const Dialog.fullscreen(
                              child: LoaderScreenWidget(
                                message: 'Your wallet is being restored.',
                              ),
                            )).then(
                      (value) {
                        context.go(
                          DesktopHomeScreen.routeName,
                          extra: WalletOnboardingDialog.restoreWallet,
                        );
                      },
                    );
                  } else {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              : null,
        ),
        const SizedBox(height: 16),
        AquaButton.secondary(
          text: loc.goBack,
          onPressed: () {
            if (pageIndex == 0) {
              context.pop();
            } else {
              pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ],
    );
  }
}
