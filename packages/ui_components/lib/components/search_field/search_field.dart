import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaSearchField extends HookWidget {
  const AquaSearchField({
    super.key,
    this.controller,
    this.hint,
    this.hintTextColor,
    this.forceFocus = false,
    this.onChanged,
    this.onSubmitted,
    this.debounceTime = kDefaultDebounceDuration,
  });

  final String? hint;
  final TextEditingController? controller;
  final Color? hintTextColor;
  final bool forceFocus;
  final ValueChanged<String>? onChanged;
  final Function(String)? onSubmitted;
  final Duration debounceTime;

  static const kBorderRadius = 8.0;
  static const kFieldHeight = 48.0;
  static const kIconSize = 24.0;
  static const kIconHorizontalPadding = 16.0;
  static const kIconVerticalPadding = 12.0;
  static const kDefaultDebounceDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusNode = useFocusNode();
    final debounceTimer = useRef<Timer?>(null);

    useEffect(() {
      if (forceFocus) {
        focusNode.requestFocus();
      }
      return null;
    }, [forceFocus]);

    useEffect(() {
      return () {
        debounceTimer.value?.cancel();
      };
    }, const []);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: AquaTypography.body1,
        onSubmitted: onSubmitted,
        onChanged: (value) {
          debounceTimer.value?.cancel();
          debounceTimer.value = Timer(
            debounceTime,
            () => onChanged?.call(value),
          );
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          constraints: const BoxConstraints(
            minHeight: kFieldHeight,
            maxHeight: kFieldHeight,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                const BorderRadius.all(Radius.circular(kBorderRadius)),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
            ),
          ),
          prefixIcon: AquaIcon.search(
            color: theme.hintColor,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: kIconSize + kIconHorizontalPadding * 2,
            maxWidth: kIconSize + kIconHorizontalPadding * 2,
            maxHeight: kIconSize,
          ),
          hintText: hint ?? 'Search...',
          hintStyle: AquaTypography.body1.copyWith(
            color: hintTextColor ?? theme.hintColor,
          ),
        ),
      ),
    );
  }
}
