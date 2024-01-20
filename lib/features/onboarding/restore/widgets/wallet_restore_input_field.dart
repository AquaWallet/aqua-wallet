import 'package:aqua/config/config.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WalletRestoreInputField extends HookConsumerWidget {
  const WalletRestoreInputField({
    required this.index,
    required this.onFocused,
    required this.onTextChanged,
    Key? key,
  }) : super(key: key);

  final int index;
  final Function(int index) onFocused;
  final Function(String text) onTextChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final textCtrl = useTextEditingController();

    textCtrl.addListener(() {
      onTextChanged(textCtrl.text);
    });

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        onFocused(index);
        textCtrl.clear();
      } else {
        final clear = ref
            .read(walletRestoreItemProvider(index))
            .shouldClear(textCtrl.text);

        if (clear) {
          textCtrl.clear();
        }
      }
    });

    ref.listen(
      fieldValueStreamProvider(index),
      (_, value) {
        textCtrl.text = value?.$1 ?? '';
      },
    );

    return SizedBox(
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
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              controller: textCtrl,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    height: 1.0,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onBackground,
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
                    width: 2.w,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.w,
                  ),
                ),
              ),
              onChanged: (value) =>
                  ref.read(walletRestoreItemProvider(index)).update(value),
            ),
          ),
        ),
      ]),
    );
  }
}
