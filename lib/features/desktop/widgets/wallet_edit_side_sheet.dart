import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class WalletEditSideSheet extends HookConsumerWidget {
  const WalletEditSideSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final aquaColors = context.aquaColors;
    final centerOfScreenForModelSheet = MediaQuery.sizeOf(context).height / 3;
    final textController = useTextEditingController();
    final currentWallet = ref.watch(currentWalletProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AquaIcon.chevronLeft(
                  color: aquaColors.textPrimary,
                  onTap: () => Navigator.of(context).pop(),
                ),
                AquaText.subtitleSemiBold(text: loc.editWallet),
                AquaIcon.trash(
                  color: aquaColors.textPrimary,
                  onTap: () => AquaModalSheet.show(
                    context,
                    colors: aquaColors,
                    icon: AquaIcon.danger(),
                    title: loc.areYouSure,
                    message: loc.deleteWalletWarning(currentWallet!.name),
                    messageTertiary: loc.thisActionIsPermanent,
                    primaryButtonText: loc.deleteWallet,
                    secondaryButtonText: loc.cancel,
                    primaryButtonVariant: AquaButtonVariant.error,
                    iconVariant: AquaRingedIconVariant.danger,
                    bottomPadding: centerOfScreenForModelSheet,
                    onPrimaryButtonTap: () {
                      debugPrint('Remove wallet');
                      Navigator.of(context).pop();
                    },
                    onSecondaryButtonTap: () => Navigator.of(context).pop(),
                    copiedToClipboardText: loc.copiedToClipboard,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 16),
            child: Divider(
              height: 1,
              color: context.aquaColors.surfaceBorderSecondary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  AquaTextField(
                    label: loc.walletName,
                    enabled: true,
                    // forceFocus: true,
                    assistiveText: loc.max23Characters,
                    controller: textController,
                    maxLength: 23,
                  ),
                  const Spacer(),
                  AquaButton.primary(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    text: loc.save,
                    isLoading: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
