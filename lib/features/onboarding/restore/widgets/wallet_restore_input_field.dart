import 'package:aqua/config/config.dart';
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
    final focusNode = useFocusNode();
    final textController = useTextEditingController();
    //NOTE - Clear text field when focused (util feature to simplify correction)
    focusNode.addListener(() {
      if (focusNode.hasFocus && focusedIndex.value != index) {
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
      focusNode: focusNode,
      onKeyEvent: (e) {
        if (e is KeyUpEvent) {
          final label = e.logicalKey.keyLabel;
          if (label.toLowerCase() == 'tab') {
            focusNode.nextFocus();
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
            width: 21.w,
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 14.sp,
                  ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Center(
              child: TextFormField(
                autofocus: index == 0,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.none,
                textInputAction: TextInputAction.next,
                controller: textController,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      height: 1.0,
                      fontWeight: FontWeight.w400,
                      color: focusNode.hasFocus
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onBackground,
                    ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AquaColors.chineseSilver.withOpacity(.1),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 8.h,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AquaColors.chineseSilver,
                      width: 1.w,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.w,
                    ),
                  ),
                ),
                onChanged: (value) => ref
                    .read(mnemonicWordInputStateProvider(index).notifier)
                    .update(text: value),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
