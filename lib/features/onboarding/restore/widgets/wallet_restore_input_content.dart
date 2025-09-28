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
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final node = useFocusScopeNode();
    final focusedIndex = useState(0);
    final mnemonicComplete = ref.watch(walletRestoreInputCompleteProvider);
    const devMnemonic = String.fromEnvironment('DEV_WALLET_MNEMONIC');

    ref.listen(focusActionProvider, (_, focusAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        error.value = false;
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
          margin: const EdgeInsets.symmetric(horizontal: 28.0),
          child: AquaElevatedButton(
            onPressed: mnemonicComplete
                ? () => ref.watch(walletRestoreProvider.notifier).restore()
                : null,
            height: context.adaptiveDouble(mobile: 52.0, smallMobile: 32.0),
            child: Text(context.loc.restoreInputButton),
          ),
        ),
        SizedBox(
            height: context.adaptiveDouble(mobile: 24.0, smallMobile: 5.0)),
        SizedBox(
          height: context.adaptiveDouble(mobile: 254.0, smallMobile: 204.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      margin: EdgeInsets.only(
        top: context.adaptiveDouble(mobile: 42.0, smallMobile: 12.0),
      ),
      child: Form(
        key: formKey,
        child: FocusScope(
          node: node,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
              crossAxisCount: 3,
              mainAxisSpacing: 14.0,
              crossAxisSpacing: 10.0,
              height: 48.0,
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
