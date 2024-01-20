import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class AddressInputView extends HookConsumerWidget {
  const AddressInputView({
    super.key,
    required this.hintText,
    this.disabled = false,
    required this.controller,
    required this.onPressed,
  });

  final bool disabled;
  final TextEditingController controller;
  final String hintText;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(children: [
      Expanded(
        child: Container(
          decoration: Theme.of(context).solidBorderDecoration,
          //ANCHOR - Address Input
          child: TextField(
            enabled: !disabled,
            controller: controller,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 24.sp,
                ),
            decoration: Theme.of(context).inputDecoration.copyWith(
                  hintText: hintText,
                  hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colors.hintTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                ),
          ),
        ),
      ),
      SizedBox(width: 10.w),
      //ANCHOR - QR Scan Button
      RoundedIconButton(
        svgAssetName: Svgs.qr,
        size: 68.r,
        radius: 10.r,
        foreground: Theme.of(context).colorScheme.onBackground,
        background: Theme.of(context).colors.inputBackground,
        onPressed: disabled ? null : onPressed,
      ),
    ]);
  }
}
