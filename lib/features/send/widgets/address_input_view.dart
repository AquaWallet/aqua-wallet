import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class AddressInputView extends HookConsumerWidget {
  const AddressInputView({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            controller: controller,
            onChanged: onChanged,
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
