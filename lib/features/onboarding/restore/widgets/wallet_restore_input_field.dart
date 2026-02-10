import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart' hide MnemonicKeyboardKey;

class WalletRestoreInputField extends HookConsumerWidget {
  const WalletRestoreInputField({
    required this.index,
    required this.onFocused,
    this.onKeyboardInput,
    super.key,
    required this.focusedIndex,
    required this.currentPage,
  });

  final int index;
  final Function(int index) onFocused;
  final Function(MnemonicKeyboardKey key)? onKeyboardInput;
  final ValueNotifier<int> focusedIndex;
  final int currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = useMemoized(GlobalKey.new);
    final keyboardFocusNode = useFocusNode();
    final textFieldFocusNode = useFocusNode();

    // Initialize text controller with current value to prevent placeholder flash
    final currentState = ref.watch(mnemonicWordInputStateProvider(index));
    final textController = useTextEditingController(text: currentState.text);
    const itemsPerPage = 4;

    // Calculate border radius and bottom border based on position within the page
    final borderRadius = useMemoized(() {
      final positionInPage = index % itemsPerPage;
      final isFirstInPage = positionInPage == 0;
      final isLastInPage = positionInPage == itemsPerPage - 1;

      final borderRadius = BorderRadius.only(
        topLeft: isFirstInPage ? const Radius.circular(12.0) : Radius.zero,
        topRight: isFirstInPage ? const Radius.circular(12.0) : Radius.zero,
        bottomLeft: isLastInPage ? const Radius.circular(12.0) : Radius.zero,
        bottomRight: isLastInPage ? const Radius.circular(12.0) : Radius.zero,
      );

      return (borderRadius);
    }, [index]);

    final shouldShowBottomBorder = useMemoized(() {
      final positionInPage = index % itemsPerPage;
      return positionInPage != itemsPerPage - 1;
    }, [index]);

    useListenable(focusedIndex);

    ref.listen(focusActionProvider, (_, focusAction) {
      if (focusedIndex.value == index) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusAction is FocusActionNext) {
            // Focus movement is handled by the parent component
            keyboardFocusNode.unfocus();
          } else if (focusAction is FocusActionClear) {
            textFieldFocusNode.unfocus();
          }
        });
      }
    });

    //NOTE - Auto-focus when this field becomes the focused index
    useEffect(() {
      if (focusedIndex.value == index && !textFieldFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            textFieldFocusNode.requestFocus();
          }
        });
      }
      return null;
    }, [focusedIndex.value]);

    //NOTE - Ensure first field gets focus on initial load with cursor visible
    useEffect(() {
      if (index == 0) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (context.mounted && !textFieldFocusNode.hasFocus) {
            textFieldFocusNode.requestFocus();
          }
        });
      }
      return null;
    }, []);

    //NOTE - Connect keyboard focus to text field focus for cursor visibility
    keyboardFocusNode.addListener(() {
      if (keyboardFocusNode.hasFocus && !textFieldFocusNode.hasFocus) {
        textFieldFocusNode.requestFocus();
      }
    });

    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        if (focusedIndex.value != index) {
          onFocused(index);
        } else {
          final isRecognizedWord = ref
              .read(walletInputHintsProvider(index))
              .options
              .contains(textController.text.toLowerCase());

          if (textController.text.isNotEmpty && !isRecognizedWord) {
            textController.clear();
            ref.read(mnemonicWordInputStateProvider(index).notifier).clear();
          }
        }
      }
    });

    //NOTE - Manually set the text field value from input state
    ref.listen(mnemonicWordInputStateProvider(index), (_, value) {
      textController.text = value.text;
      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length),
      );
    });

    // Get current text value
    final currentText = useValueListenable(textController);

    // Calculate initial validation state
    final initialState = useMemoized(() {
      final text = textController.text.toLowerCase();
      if (text.isEmpty) {
        return SeedWordValidationState.none;
      }
      final validWords = ref.read(walletInputHintsProvider(index)).options;
      return validWords.contains(text)
          ? SeedWordValidationState.valid
          : SeedWordValidationState.invalid;
    }, []);

    // Store validation state (only debounce invalid states)
    final validationState = useState(initialState);

    useEffect(() {
      final text = currentText.text.toLowerCase();

      // Calculate immediate validation state
      SeedWordValidationState immediateState;
      if (text.isEmpty) {
        immediateState = SeedWordValidationState.none;
      } else {
        final validWords = ref.read(walletInputHintsProvider(index)).options;
        immediateState = validWords.contains(text)
            ? SeedWordValidationState.valid
            : SeedWordValidationState.invalid;
      }

      // If valid or none, show immediately
      if (immediateState != SeedWordValidationState.invalid) {
        validationState.value = immediateState;
        return null;
      }

      // If invalid, debounce it
      final timer = Timer(const Duration(milliseconds: 500), () {
        validationState.value = immediateState;
      });
      return timer.cancel;
    }, [currentText.text]);

    return Container(
      key: key,
      width: double.maxFinite,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: context.aquaColors.surfacePrimary,
        borderRadius: borderRadius,
        border: shouldShowBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: context.aquaColors.textTertiary.withOpacity(0.2),
                  width: 1.0,
                ),
              )
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: AquaSeedInputField.defaultField(
          index: index + 1,
          controller: textController,
          focusNode: textFieldFocusNode,
          cursorColor: context.aquaColors.accentBrand,
          keyboardFocusNode: keyboardFocusNode,
          onKeyboardInput: (label) {
            if (label.toLowerCase() == 'tab') {
              keyboardFocusNode.nextFocus();
              return;
            }
            final key = MnemonicKeyboardKey.fromRawValue(label);
            if (!key.isBackspaceKey) {
              //NOTE - The reason we don't want to pass backspace key is because
              // when you are using hardware keyboard, the OS handles it by itself
              // Which means there will be double backspace if we pass it here
              onKeyboardInput?.call(key);
            }
          },
          keyboardType: TextInputType.none,
          textInputAction: TextInputAction.next,
          autofocus: index == 0,
          autocorrect: false,
          enableSuggestions: false,
          validationState: validationState.value,
          colors: context.aquaColors,
          onChanged: (value) => ref
              .read(mnemonicWordInputStateProvider(index).notifier)
              .update(text: value),
        ),
      ),
    );
  }
}
