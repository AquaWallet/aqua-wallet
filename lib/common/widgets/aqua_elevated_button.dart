import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      height: height ?? 48.h,
      child: ElevatedButton(
        onPressed:
            debounce && onPressed != null ? debouncedOnPressed : onPressed,
        style: style ??
            ElevatedButton.styleFrom(
              textStyle: Theme.of(context).textTheme.titleSmall,
            ),
        child: child,
      ),
    );
  }
}
