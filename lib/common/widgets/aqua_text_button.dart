import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AquaTextButton extends StatelessWidget {
  const AquaTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.height,
    this.style,
    this.debounce = false,
    this.debounceMilliseconds = 300,
  });

  final Widget child;
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
      height: 48.h,
      child: TextButton(
        onPressed:
            debounce && onPressed != null ? debouncedOnPressed : onPressed,
        style: style ??
            ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              textStyle: context.textTheme.titleSmall,
              foregroundColor: context.colorScheme.primary,
            ),
        child: child,
      ),
    );
  }
}
