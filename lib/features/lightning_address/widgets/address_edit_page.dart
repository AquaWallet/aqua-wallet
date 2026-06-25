import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LnAddressEditBottomSheetContent extends HookConsumerWidget {
  const LnAddressEditBottomSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formAsync = ref.watch(lnAddressEditInputProvider);
    final form = formAsync.valueOrNull;
    final controller = useTextEditingController();
    final focusNode = useFocusNode();

    useEffect(() {
      final input = form?.inputUsername ?? '';
      if (input.isNotEmpty && controller.text.isEmpty) {
        controller.text = input;
      }
      return null;
    }, [form?.inputUsername]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
      return null;
    }, const []);

    return Column(
      children: [
        const SizedBox(height: 32),
        AquaText.h4Medium(
          text: context.loc.lnAddressEditTitle,
          size: 24,
          color: context.aquaColors.textPrimary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AquaText.body1(
            text: context.loc.lnAddressEditSubtitle,
            textAlign: TextAlign.center,
            color: context.aquaColors.textSecondary,
            maxLines: 2,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AquaTextField(
            controller: controller,
            focusNode: focusNode,
            forceFocus: true,
            label: context.loc.lnAddressEditYourAddress,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            error: form?.isUnavailable ?? false,
            assistiveText: form?.isUnavailable == true
                ? context.loc.lnAddressEditUnavailable
                : null,
            onChanged: (value) => ref
                .read(lnAddressEditInputProvider.notifier)
                .setUsername(value),
            showClearInputButton: true,
            suffixText: (form?.inputUsername.isNotEmpty ?? false)
                ? kAquaNetDomain
                : null,
            suffixStyle: AquaTypography.body1.copyWith(
              color: context.aquaColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: LnAddressTotalFeesRow(),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AquaButton.primary(
            text: context.loc.next,
            onPressed: (form?.isNextEnabled ?? false)
                ? () {
                    final username = form?.inputUsername ?? '';
                    Navigator.of(context).pop();
                    context.push(
                      LnAddressEditScreen.routeName,
                      extra: LnAddressEditArguments(username: username),
                    );
                  }
                : null,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
