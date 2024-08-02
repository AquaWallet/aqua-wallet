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
    required this.onPressed,
    required this.onChanged,
  });

  final bool disabled;
  final TextEditingController controller;
  final String? hintText;
  final void Function() onPressed;
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
                  color: Theme.of(context).colorScheme.onBackground,
                ),
            decoration: Theme.of(context).inputDecoration.copyWith(
                  filled: false,
                  hintText: hintText,
                  hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colors.hintTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
          ),
        ),
      ),
      SizedBox(width: 14.w),
      //ANCHOR - QR Scan Button
      RoundedIconButton(
        svgAssetName: Svgs.qr,
        size: 68.r,
        radius: 10.r,
        elevation: 0,
        foreground: Theme.of(context).colorScheme.background,
        background:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        onPressed: disabled ? null : onPressed,
      ),
    ]);
  }
}
