import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/sliver_grid_delegate.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WalletRestoreInputContent extends HookConsumerWidget {
  const WalletRestoreInputContent({
    super.key,
    required this.error,
  });

  final ValueNotifier<bool> error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = useFocusScopeNode();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final focusedIndex = useState(0);
    final mnemonicComplete = ref.watch(walletRestoreInputCompleteProvider);
    const devMnemonic = String.fromEnvironment('DEV_WALLET_MNEMONIC');

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

    //ANCHOR - Force status bar colors
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).transparentWithKeyboard();
      });
      return null;
    }, []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //ANCHOR - Header
        WalletRestoreHeader(error: error.value),
        //ANCHOR - Mnemonic Word Fields
        Expanded(
          child: Center(
            child: _MnemonicInputGrid(
              formKey: formKey,
              node: node,
              focusedIndex: focusedIndex,
              onKeyboardInput: kDebugMode
                  ? (key) => ref
                      .read(mnemonicWordInputStateProvider(focusedIndex.value)
                          .notifier)
                      .onKeyPressed(key)
                  : null,
            ),
          ),
        ),
        //ANCHOR - Restore Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: 28.w),
          child: AquaElevatedButton(
            onPressed: mnemonicComplete
                ? () => ref.watch(walletRestoreProvider.notifier).restore()
                : null,
            child: Text(context.loc.restoreInputButton),
          ),
        ),
        SizedBox(height: 24.h),
        SizedBox(
          height: 254.h,
          child: Column(
            children: [
              //ANCHOR - Mnemonic Suggestions
              WalletMnemonicSuggestions(
                suggestions: ref
                    .watch(walletInputHintsProvider(focusedIndex.value))
                    .options,
                onSuggestionSelected: (suggestion) => ref
                    .read(mnemonicWordInputStateProvider(focusedIndex.value)
                        .notifier)
                    .update(text: suggestion, isSuggestion: true),
              ),
              //ANCHOR - Virtual Keyboard
              Expanded(
                child: WalletRestoreInputKeyboard(
                  onKeyPressed: (key) => ref
                      .read(mnemonicWordInputStateProvider(focusedIndex.value)
                          .notifier)
                      .onKeyPressed(key),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MnemonicInputGrid extends StatelessWidget {
  const _MnemonicInputGrid({
    required this.formKey,
    required this.node,
    required this.focusedIndex,
    this.onKeyboardInput,
  });

  final GlobalKey<FormState> formKey;
  final FocusScopeNode node;
  final ValueNotifier<int> focusedIndex;
  final Function(MnemonicKeyboardKey key)? onKeyboardInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      margin: EdgeInsets.only(top: 42.h),
      child: Form(
        key: formKey,
        child: FocusScope(
          node: node,
          child: GridView.builder(
            shrinkWrap: true,
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
              onKeyboardInput: onKeyboardInput,
              focusedIndex: focusedIndex,
            ),
          ),
        ),
      ),
    );
  }
}
