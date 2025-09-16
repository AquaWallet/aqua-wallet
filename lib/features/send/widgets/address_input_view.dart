import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:coin_cz/features/address_validator/address_utils.dart';
import 'package:flutter_svg/svg.dart';

const visibleCharsLength = 12;
const lengthOfEllipsis = 3;

class AddressInputView extends HookConsumerWidget {
  const AddressInputView({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFocused = useState(false);
    final fullAddress = useState('');
    final internalInputController =
        useTextEditingController(text: controller.text);

    final onUserInput = useCallback((String text) {
      controller.text = text;
      fullAddress.value = text;
      onChanged(text);
    }, []);

    final setCompressedAddressView = useCallback(() {
      if (!isFocused.value) {
        fullAddress.value = controller.value.text;
        internalInputController.text =
            getCompressedAddress(controller.value.text);
      }
    }, [isFocused, controller]);

    final onTap = useCallback(() {
      isFocused.value = true;
      internalInputController.text = fullAddress.value;
    }, [fullAddress]);

    final onTapOutside = useCallback(() {
      isFocused.value = false;
      setCompressedAddressView();
    }, []);

    final onAddressCleared = useCallback(() {
      controller.clear();
      onChanged('');
    }, [controller, onChanged]);

    final onControllerChange = useCallback(() {
      fullAddress.value = controller.text;
      internalInputController.text = isFocused.value
          // when in focus, show full address
          ? controller.text
          // address was scanned/pasted
          : getCompressedAddress(controller.text);
    });

    useEffect(() {
      fullAddress.value = controller.text;
      setCompressedAddressView();
      return;
    }, []);

    useEffect(() {
      controller.addListener(onControllerChange);
      return () => controller.removeListener(onControllerChange);
    }, [controller]);

    return Container(
      decoration: Theme.of(context).solidBorderDecoration.copyWith(
            color:
                Theme.of(context).colors.addressFieldContainerBackgroundColor,
          ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextField(
                enabled: !disabled,
                controller: internalInputController,
                onTapOutside: (_) => onTapOutside(),
                onTap: onTap,
                onChanged: onUserInput,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colors.onBackground,
                    ),
                decoration: Theme.of(context).inputDecoration.copyWith(
                      filled: false,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.text.isNotEmpty && !disabled)
                              ClearInputButton(onTap: onAddressCleared),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: disabled ? null : onScanPressed,
                              child: Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: SvgPicture.asset(
                                  Svgs.walletScan,
                                  width: 20,
                                  height: 20,
                                  color: Theme.of(context).colors.onBackground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      hintText: hintText,
                      hintStyle:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colors.hintTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
