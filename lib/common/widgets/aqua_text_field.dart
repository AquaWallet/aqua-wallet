import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AquaTextField extends TextField {
  const AquaTextField._({
    required super.autofocus,
    required TextInputType super.keyboardType,
    required TextInputAction super.textInputAction,
    super.controller,
    super.style,
    super.decoration = null,
    super.onChanged,
    super.onSubmitted,
    super.maxLines = null,
    super.inputFormatters,
  });

  factory AquaTextField.defaultStyled({
    required BuildContext context,
    bool autocorrect = false,
    String? text,
    String? hintText,
    TextStyle? hintTextStyle,
    EdgeInsetsGeometry? contentPadding,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    Widget? suffixIcon,
    BoxConstraints? suffixIconConstraints,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool autofocus = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.visiblePassword,
    TextInputAction textInputAction = TextInputAction.done,
    List<TextInputFormatter>? inputFormatters,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final internalController = controller ?? TextEditingController();
    internalController.text = text ?? '';
    onChanged?.call(text ?? '');

    return AquaTextField._(
      controller: internalController,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        contentPadding: contentPadding,
        prefixIcon: prefixIcon,
        prefixIconConstraints: prefixIconConstraints,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIconConstraints,
        filled: true,
        fillColor:
            backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.0,
            color:
                borderColor ?? Theme.of(context).colorScheme.primaryContainer,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.0,
            color: backgroundColor ??
                Theme.of(context).colorScheme.primaryContainer,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        hintText: hintText,
        hintStyle: hintTextStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
    );
  }
}
