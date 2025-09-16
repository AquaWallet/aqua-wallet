import 'package:coin_cz/gen/fonts.gen.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/material.dart';

class AquaElevatedButton extends StatelessWidget {
  const AquaElevatedButton({
    super.key,
    this.child,
    this.onPressed,
    this.height,
    this.style,
    this.debounce = false,
    this.debounceMilliseconds = 300,
  });

  final Widget? child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final double? height;
  final bool debounce;
  final int debounceMilliseconds;

  @override
  Widget build(BuildContext context) {
    final debouncer = Debouncer(milliseconds: debounceMilliseconds);

    void debouncedOnPressed() {
      if (onPressed != null) {
        debouncer.run(onPressed!);
      }
    }

    return SizedBox(
      width: double.maxFinite,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed:
            debounce && onPressed != null ? debouncedOnPressed : onPressed,
        style: style ??
            ElevatedButton.styleFrom(
              textStyle: TextStyle(
                fontSize: 20,
                color: context.colorScheme.onPrimary,
                fontFamily: UiFontFamily.inter,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
        child: child,
      ),
    );
  }
}
