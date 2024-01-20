import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/sliver_grid_delegate.dart';
import 'package:aqua/data/models/focus_action.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class WalletRestoreInputContent extends HookConsumerWidget {
  const WalletRestoreInputContent({
    Key? key,
    required this.error,
  }) : super(key: key);

  final ValueNotifier<bool> error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = useFocusScopeNode();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final focusedIndex = useState(0);
    final focusedInputText = useState('');
    final mnemonicComplete = ref.watch(walletRestoreInputCompleteProvider);

    ref.listen(
      focusActionProvider,
      (context, focusAction) {
        error.value = false;
        if (focusAction is FocusActionNext) {
          node.nextFocus();
        } else if (focusAction is FocusActionClear) {
          node.unfocus();
        }
      },
    );

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) => LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.maxHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WalletRestoreHeader(error: error.value),
                Expanded(
                  child: Container(
                    height: 230.h,
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    margin: EdgeInsets.only(top: 42.h),
                    child: Form(
                      key: formKey,
                      child: FocusScope(
                        node: node,
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                            crossAxisCount: 3,
                            mainAxisSpacing: 14.w,
                            crossAxisSpacing: 10.w,
                            height: 48.h,
                          ),
                          itemCount: 12,
                          itemBuilder: (_, index) => WalletRestoreInputField(
                            index: index,
                            onFocused: (index) => focusedIndex.value = index,
                            onTextChanged: (s) => focusedInputText.value = s,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 28.w),
                  child: AquaElevatedButton(
                    onPressed: mnemonicComplete
                        ? () =>
                            ref.read(walletRestoreProcessingProvider).restore()
                        : null,
                    child:
                        Text(AppLocalizations.of(context)!.restoreInputButton),
                  ),
                ),
                SizedBox(height: 24.h),
                if (isKeyboardVisible) ...{
                  WalletMnemonicSuggestions(
                    suggestions: ref
                        .read(walletRestoreItemProvider(focusedIndex.value))
                        .options(focusedInputText.value)
                        .toList(),
                    onSuggestionSelected: (suggestion) => ref
                        .read(walletRestoreItemProvider(focusedIndex.value))
                        .select(suggestion),
                  ),
                }
              ],
            ),
          ),
        ),
      ),
    );
  }
}
