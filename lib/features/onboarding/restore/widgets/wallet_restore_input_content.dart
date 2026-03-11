import 'package:aqua/data/data.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart' hide MnemonicKeyboardKey;

class WalletRestoreInputContent extends HookConsumerWidget {
  const WalletRestoreInputContent({
    super.key,
    required this.error,
    required this.currentPage,
    required this.focusedIndex,
  });

  final ValueNotifier<bool> error;
  final ValueNotifier<int> currentPage;
  final ValueNotifier<int> focusedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const itemsPerPage = 4;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final node = useFocusScopeNode();
    final mnemonicComplete = ref.watch(walletRestoreInputCompleteProvider);
    const devMnemonic = String.fromEnvironment('DEV_WALLET_MNEMONIC');

    ref.listen(focusActionProvider, (_, focusAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        error.value = false;

        // Handle focus actions
        if (focusAction is FocusActionNext) {
          final isLastFieldInPage =
              (focusedIndex.value + 1) % itemsPerPage == 0;

          if (!isLastFieldInPage) {
            // Move to next field only if not the last field in page
            focusedIndex.value = focusedIndex.value + 1;
          }
        }
      });
    });

    //ANCHOR - Fill mnemonic input fields with dev mnemonic
    useEffect(() {
      if (kDebugMode && devMnemonic.isNotEmpty) {
        Future.microtask(() {
          devMnemonic.split(' ').forEachIndexed((index, word) {
            ref
                .read(mnemonicWordInputStateProvider(index).notifier)
                .update(text: word);
          });
        });
      }
      return null;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //ANCHOR - Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                //ANCHOR - Header
                WalletRestoreHeader(error: error.value),
                const SizedBox(height: 16.0),
                //ANCHOR - Mnemonic Word Fields
                Center(
                  child: _MnemonicInputList(
                    formKey: formKey,
                    node: node,
                    focusedIndex: focusedIndex,
                    currentPage: currentPage,
                    onKeyboardInput: kDebugMode
                        ? (key) {
                            final currentFocusedIndex = focusedIndex.value;
                            ref
                                .read(mnemonicWordInputStateProvider(
                                        currentFocusedIndex)
                                    .notifier)
                                .onKeyPressed(key);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        //ANCHOR - Restore Button (fixed above keyboard)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _RestoreButton(
            currentPage: currentPage,
            focusedIndex: focusedIndex,
            mnemonicComplete: mnemonicComplete,
          ),
        ),
        const SizedBox(height: 16.0),
        //ANCHOR - Mnemonic Suggestions (fixed at bottom)
        WalletMnemonicSuggestions(
          suggestions:
              ref.watch(walletInputHintsProvider(focusedIndex.value)).options,
          onSuggestionSelected: (suggestion) => ref
              .read(mnemonicWordInputStateProvider(focusedIndex.value).notifier)
              .update(text: suggestion, isSuggestion: true),
        ),
        //ANCHOR - Virtual Keyboard (fixed at bottom)
        SizedBox(
          height: 200,
          child: WalletRestoreInputKeyboard(
            onKeyPressed: (key) {
              final currentFocusedIndex = focusedIndex.value;
              ref
                  .read(mnemonicWordInputStateProvider(currentFocusedIndex)
                      .notifier)
                  .onKeyPressed(key);
            },
          ),
        ),
      ],
    );
  }
}

class _MnemonicInputList extends HookConsumerWidget {
  const _MnemonicInputList({
    required this.formKey,
    required this.node,
    required this.focusedIndex,
    required this.currentPage,
    this.onKeyboardInput,
  });

  static const lastWordFromSeed = 12;
  final GlobalKey<FormState> formKey;
  final FocusScopeNode node;
  final ValueNotifier<int> focusedIndex;
  final ValueNotifier<int> currentPage;
  final Function(MnemonicKeyboardKey key)? onKeyboardInput;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const itemsPerPage = 4;

    // Listen to currentPage changes to ensure rebuild
    useListenable(currentPage);

    return Form(
      key: formKey,
      child: FocusScope(
        node: node,
        child: ListView.builder(
          key: ValueKey(currentPage.value),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemsPerPage,
          itemBuilder: (_, listIndex) {
            final actualIndex = currentPage.value * itemsPerPage + listIndex;
            if (actualIndex >= lastWordFromSeed) {
              return const SizedBox.shrink();
            }

            return WalletRestoreInputField(
              index: actualIndex,
              onFocused: (index) => focusedIndex.value = index,
              onKeyboardInput: onKeyboardInput,
              focusedIndex: focusedIndex,
              currentPage: currentPage.value,
            );
          },
        ),
      ),
    );
  }
}

class _RestoreButton extends HookConsumerWidget {
  const _RestoreButton({
    required this.currentPage,
    required this.focusedIndex,
    required this.mnemonicComplete,
  });

  final ValueNotifier<int> currentPage;
  final ValueNotifier<int> focusedIndex;
  final bool mnemonicComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const itemsPerPage = 4;
    final totalPages = (kMnemonicLength / itemsPerPage).ceil();
    final isLastPage = currentPage.value == totalPages - 1;

    // Watch all word states on current page to make button reactive
    final currentPageWordStates = List.generate(itemsPerPage, (i) {
      final actualIndex = currentPage.value * itemsPerPage + i;
      return actualIndex < kMnemonicLength
          ? ref.watch(mnemonicWordInputStateProvider(actualIndex))
          : null;
    });

    final buttonConfig = useMemoized(() {
      if (isLastPage) {
        // Final page: show "Next" and enable only when mnemonic is complete
        return (
          text: context.loc.next,
          isEnabled: mnemonicComplete,
        );
      } else {
        // Check if all 4 words on current page are complete AND valid
        final startIndex = currentPage.value * itemsPerPage;
        final endIndex = (startIndex + itemsPerPage).clamp(0, kMnemonicLength);

        bool allCompleteAndValid = true;
        for (int i = startIndex; i < endIndex; i++) {
          final wordState = ref.watch(mnemonicWordInputStateProvider(i));
          final validWords = ref.watch(walletInputHintsProvider(i)).options;
          final isValid = validWords.contains(wordState.text.toLowerCase());

          if (wordState.text.isEmpty || !isValid) {
            allCompleteAndValid = false;
            break;
          }
        }

        return (
          text: context.loc.next,
          isEnabled: allCompleteAndValid,
        );
      }
    }, [
      isLastPage,
      mnemonicComplete,
      currentPage.value,
      ...currentPageWordStates.map((s) => s?.text ?? ''),
    ]);

    final buttonText = buttonConfig.text;
    final isEnabled = buttonConfig.isEnabled;

    return AquaButton.primary(
      key: OnboardingScreenKeys.restoreNextButton,
      text: buttonText,
      onPressed: isEnabled
          ? () async {
              if (isLastPage) {
                // Navigate to review screen
                await context.push(WalletRestoreReviewScreen.routeName);
              } else {
                // Advance to next page and auto-focus first field
                currentPage.value = currentPage.value + 1;
                final firstFieldIndex = currentPage.value * itemsPerPage;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  focusedIndex.value = firstFieldIndex;
                });
              }
            }
          : null,
    );
  }
}
