import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaAmountTextfield extends StatelessWidget {
  const AquaAmountTextfield({
    super.key,
    required this.focusNode,
    required this.controller,
    this.prefix,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AquaTypography.h3SemiBold,
      cursorColor: Theme.of(context).colorScheme.primary,
      keyboardType: TextInputType.none,
      autofocus: true,
      focusNode: focusNode,
      decoration: InputDecoration(
        border: InputBorder.none,
        filled: false,
        fillColor: Colors.transparent,
        hintText: '0',
        hintStyle: AquaTypography.h3SemiBold,
        prefixText: prefix,
        prefixStyle: AquaTypography.h3SemiBold,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
