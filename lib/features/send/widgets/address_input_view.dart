import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const visibleCharsLength = 12;
const lengthOfEllipsis = 3;

class AddressInputView extends HookConsumerWidget {
  AddressInputView({
    super.key,
    this.hintText,
    this.disabled = false,
    required this.controller,
    required this.onScanPressed,
    required this.onChanged,
  });

  final bool disabled;
  final TextEditingController controller;
  final String? hintText;
  final void Function() onScanPressed;
  final void Function(String) onChanged;
  late final internalInputController =
      useTextEditingController(text: controller.text);

  void onChangedAdapter(text) {
    controller.text = internalInputController.value.text;
    onChanged(text);
  }

  void setCompressedAddressView() {
    internalInputController.text = getCompressedAddress(controller.value.text);
  }

  void onTap() {
    internalInputController.text = controller.value.text;
  }

  getCompressedAddress(String address) {
    const compressedAddressLength = visibleCharsLength +
        lengthOfEllipsis +
        visibleCharsLength; // bc1pjhsdgsad...asdhjgsadhjsdj

    if (address.length > compressedAddressLength) {
      return '${address.substring(0, visibleCharsLength)}${'.' * lengthOfEllipsis}${address.substring(address.length - visibleCharsLength)}';
    }
    return address;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      controller.addListener(setCompressedAddressView);
      return (() {
        controller.removeListener(setCompressedAddressView);
      });
    }, []);
    final onAddressCleared = useCallback(() {
      controller.clear();
      onChanged('');
    });
    return Row(children: [
      Expanded(
        child: Container(
          decoration: Theme.of(context).solidBorderDecoration.copyWith(
                color: Theme.of(context)
                    .colors
                    .addressFieldContainerBackgroundColor,
              ),
          //ANCHOR - Address Input
          child: TextField(
            enabled: !disabled,
            controller: internalInputController,
            onTapOutside: (_) => setCompressedAddressView(),
            onTap: onTap,
            onChanged: onChangedAdapter,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colors.onBackground,
                ),
            decoration: Theme.of(context).inputDecoration.copyWith(
                  filled: false,
                  suffixIcon: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: controller.text.isNotEmpty && !disabled
                          ? ClearInputButton(onTap: onAddressCleared)
                          : null),
                  hintText: hintText,
                  hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colors.hintTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
          ),
        ),
      ),
      const SizedBox(width: 14.0),
      //ANCHOR - QR Scan Button
      RoundedIconButton(
        svgAssetName: Svgs.qr,
        size: 68.0,
        radius: 10.0,
        elevation: 0,
        foreground: Theme.of(context).colors.background,
        background:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        onPressed: disabled ? null : onScanPressed,
      ),
    ]);
  }
}
