import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    this.backgroundColor,
    this.child,
  });

  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: child,
    );
  }
}
