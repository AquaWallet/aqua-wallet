import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class EditWalletScreen extends HookConsumerWidget with AuthGuardMixin {
  const EditWalletScreen({
    super.key,
    this.wallet,
  });

  final StoredWallet? wallet;

  static const routeName = '/editWalletScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final controller = useTextEditingController(text: wallet?.name);
    final inputState = ref.watch(walletNameInputProvider(wallet));

    final onSave = useCallback(() async {
      if (wallet == null) {
        context.pop(controller.text);
      } else {
        ref.read(walletNameInputProvider(wallet).notifier).save();
        if (context.mounted) {
          context.pop();
        }
      }
    }, [wallet?.id]);

    final isValidInput = inputState.maybeWhen(
      data: (text) => text.isNotEmpty,
      orElse: () => false,
    );

    final hasError = inputState.hasError;
    final error = inputState.error;
    final errorMessage = error is WalletNameValidationException
        ? error.toLocalizedString(context)
        : null;

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
        Future.microtask(() {
          ref.read(systemOverlayColorProvider(context)).themeBased();
        });
      });
      return null;
    }, const []);

    useEffect(() {
      void listener() => ref
          .read(walletNameInputProvider(wallet).notifier)
          .updateText(controller.text);

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    return DesignRevampScaffold(
      resizeToAvoidBottomInset: true,
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: wallet == null
            ? context.loc.storedWalletsNameYourWallet
            : context.loc.editWallet,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  children: [
                    AquaTextField(
                      maxLength: kMaxWalletNameLength,
                      key: OnboardingScreenKeys.walletNameInput,
                      label: context.loc.walletName,
                      controller: controller,
                      focusNode: focusNode,
                      error: hasError,
                      assistiveText:
                          errorMessage ?? context.loc.max23Characters,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(AquaRegex.newlines),
                      ],
                    ),
                    if (wallet?.samRockAppLink != null) ...[
                      const SizedBox(height: 24),
                      AquaListItem(
                        colors: context.aquaColors,
                        title: context.loc.samRockEditWalletScreenHostLabel,
                        subtitleTrailing:
                            Uri.parse(wallet!.samRockAppLink!.uploadUrl).host,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AquaButton.primary(
                key: OnboardingScreenKeys.walletNameSaveButton,
                text: context.loc.save,
                isLoading: ref.watch(storedWalletsProvider).isLoading,
                onPressed: isValidInput ? onSave : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
