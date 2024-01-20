import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AquaTextButton extends StatelessWidget {
  const AquaTextButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.style,
  }) : super(key: key);

  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 48.h,
      child: TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}
