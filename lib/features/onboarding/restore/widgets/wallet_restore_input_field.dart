import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WalletRestoreInputField extends HookConsumerWidget {
  const WalletRestoreInputField({
    required this.index,
    required this.onFocused,
    this.onKeyboardInput,
    super.key,
    required this.focusedIndex,
  });

  final int index;
  final Function(int index) onFocused;
  final Function(MnemonicKeyboardKey key)? onKeyboardInput;
  final ValueNotifier<int> focusedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = useMemoized(GlobalKey.new);
    final keyboardFocusNode = useFocusNode();
    final textFieldFocusNode = useFocusNode();
    final textController = useTextEditingController();
    final isFocused =
        textFieldFocusNode.hasFocus || focusedIndex.value == index;

    useListenable(focusedIndex);

    ref.listen(focusActionProvider, (_, focusAction) {
      if (focusedIndex.value == index) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusAction is FocusActionNext && index < 11) {
            // Move focus to the next field directly
            focusedIndex.value = index + 1;
            textFieldFocusNode.unfocus();
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

    //NOTE - Clear text field when focused (util feature to simplify correction)
    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus && focusedIndex.value != index) {
        onFocused(index);
        textController.clear();
        ref.read(mnemonicWordInputStateProvider(index).notifier).clear();
      } else {
        final isRecognizedWord = ref
            .read(walletInputHintsProvider(index))
            .options
            .contains(textController.text.toLowerCase());
        if (!isRecognizedWord) {
          textController.clear();
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

    return KeyboardListener(
      key: key,
      focusNode: keyboardFocusNode,
      onKeyEvent: (e) {
        if (e is KeyUpEvent) {
          final label = e.logicalKey.keyLabel;
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
        }
      },
      child: SizedBox(
        width: double.maxFinite,
        child: Row(children: [
          SizedBox(
            width: 21.0,
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colors.onBackground,
                    fontSize: 14.0,
                  ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Center(
              child: TextFormField(
                focusNode: textFieldFocusNode,
                autofocus: index == 0,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.none,
                textInputAction: TextInputAction.next,
                showCursor: true,
                readOnly: true,
                enableInteractiveSelection: true,
                controller: textController,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      height: 1.0,
                      fontWeight: FontWeight.w400,
                      color: isFocused
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colors.onBackground,
                    ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AquaColors.chineseSilver.withOpacity(.1),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: isFocused
                          ? Theme.of(context).colorScheme.primary
                          : AquaColors.chineseSilver,
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: isFocused
                          ? Theme.of(context).colorScheme.primary
                          : AquaColors.chineseSilver,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
