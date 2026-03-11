import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

enum SeedWordValidationState {
  valid,
  invalid,
  none,
}

class AquaSeedInputField extends HookWidget {
  const AquaSeedInputField({
    super.key,
    required this.index,
    this.controller,
    this.error = false,
    this.enabled = true,
    this.forceFocus = false,
    this.validationState = SeedWordValidationState.none,
    this.onChanged,
    this.debounceTime = kDefaultDebounceDuration,
    this.colors,
    this.focusNode,
    this.keyboardFocusNode,
    this.onKeyboardInput,
    this.keyboardType = TextInputType.text,
    this.cursorColor,
    this.textInputAction,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final int index;
  final TextEditingController? controller;
  final bool error;
  final bool enabled;
  final bool forceFocus;
  final ValueChanged<String>? onChanged;
  final Duration debounceTime;
  final AquaColors? colors;
  final SeedWordValidationState validationState;
  final FocusNode? focusNode;
  final FocusNode? keyboardFocusNode;
  final Function(String)? onKeyboardInput;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final Color? cursorColor;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;

  static const kLabelAnimationDuration = Duration(milliseconds: 200);
  static const kDefaultDebounceDuration = Duration(milliseconds: 500);

  /// Factory constructor for a default interactive seed input field
  factory AquaSeedInputField.defaultField({
    required int index,
    TextEditingController? controller,
    bool error = false,
    bool enabled = true,
    bool forceFocus = false,
    SeedWordValidationState validationState = SeedWordValidationState.none,
    ValueChanged<String>? onChanged,
    Duration debounceTime = kDefaultDebounceDuration,
    AquaColors? colors,
    FocusNode? focusNode,
    FocusNode? keyboardFocusNode,
    Function(String)? onKeyboardInput,
    TextInputType keyboardType = TextInputType.text,
    Color? cursorColor,
    TextInputAction? textInputAction,
    bool autofocus = false,
    bool autocorrect = true,
    bool enableSuggestions = true,
  }) {
    return AquaSeedInputField(
      index: index,
      controller: controller,
      error: error,
      enabled: enabled,
      forceFocus: forceFocus,
      validationState: validationState,
      onChanged: onChanged,
      debounceTime: debounceTime,
      colors: colors,
      focusNode: focusNode,
      keyboardFocusNode: keyboardFocusNode,
      onKeyboardInput: onKeyboardInput,
      keyboardType: keyboardType,
      cursorColor: cursorColor,
      textInputAction: textInputAction,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
    );
  }

  /// Factory constructor for a read-only seed input field (display only)
  factory AquaSeedInputField.readOnly({
    required int index,
    required String text,
    AquaColors? colors,
    SeedWordValidationState validationState = SeedWordValidationState.none,
  }) {
    return AquaSeedInputField(
      index: index,
      controller: TextEditingController(text: text),
      enabled: false,
      validationState: validationState,
      colors: colors,
      keyboardType: TextInputType.none,
      autocorrect: false,
      enableSuggestions: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = useState(forceFocus);
    final hasText = useState(controller?.text.isNotEmpty ?? false);
    final currentLength = useState(controller?.text.length ?? 0);
    final theme = Theme.of(context);

    final debounceTimer = useRef<Timer?>(null);
    useEffect(() {
      return () {
        debounceTimer.value?.cancel();
      };
    }, const []);

    // Update focus state when forceFocus changes
    useEffect(() {
      isFocused.value = forceFocus;
      return null;
    }, [forceFocus]);

    // Update hasText and currentLength when controller changes
    useEffect(() {
      void listener() {
        hasText.value = controller?.text.isNotEmpty ?? false;
        currentLength.value = controller?.text.length ?? 0;
      }

      controller?.addListener(listener);
      return () => controller?.removeListener(listener);
    }, [controller]);

    // Connect keyboard focus to text field focus for cursor visibility
    if (keyboardFocusNode != null && focusNode != null) {
      useEffect(() {
        void listener() {
          if (keyboardFocusNode!.hasFocus && !focusNode!.hasFocus) {
            focusNode!.requestFocus();
          }
        }

        keyboardFocusNode!.addListener(listener);
        return () => keyboardFocusNode!.removeListener(listener);
      }, [keyboardFocusNode, focusNode]);
    }

    // Listen to focus changes from the provided focusNode
    if (focusNode != null) {
      useEffect(() {
        void listener() {
          if (!forceFocus && enabled) {
            isFocused.value = focusNode!.hasFocus;
          }
        }

        focusNode!.addListener(listener);
        return () => focusNode!.removeListener(listener);
      }, [focusNode]);
    }

    Widget textField = TextField(
      controller: controller,
      focusNode: focusNode,
      style: AquaTypography.body1Medium.copyWith(
        color: enabled ? null : colors?.textPrimary,
      ),
      cursorColor: cursorColor,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      minLines: 1,
      maxLines: 1,
      expands: false,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
        labelText: null,
        isCollapsed: false,
        filled: isFocused.value,
        fillColor: isFocused.value ? Colors.transparent : null,
        hintText: enabled ? '...' : null,
        hintStyle: enabled
            ? AquaTypography.body1Medium.copyWith(
                color: colors?.textSecondary,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Text(
            '$index',
            textAlign: TextAlign.right,
            style: AquaTypography.body2Medium.copyWith(
              color: colors?.textTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 18,
          maxWidth: 18,
          minHeight: 18,
        ),
        suffixIcon: switch (validationState) {
          SeedWordValidationState.valid => AquaIcon.check(
              size: 18,
              color: colors?.accentBrand,
            ),
          SeedWordValidationState.invalid => AquaIcon.close(
              size: 18,
              color: colors?.accentDanger,
            ),
          SeedWordValidationState.none => null,
        },
      ),
      onChanged: enabled
          ? (value) {
              hasText.value = value.isNotEmpty;
              currentLength.value = value.length;
              debounceTimer.value?.cancel();
              debounceTimer.value = Timer(
                debounceTime,
                () => onChanged?.call(value),
              );
            }
          : null,
    );

    // Wrap with KeyboardListener if keyboardFocusNode is provided
    if (keyboardFocusNode != null) {
      textField = KeyboardListener(
        focusNode: keyboardFocusNode!,
        onKeyEvent: (e) {
          if (e is KeyUpEvent && onKeyboardInput != null) {
            final label = e.logicalKey.keyLabel;
            if (label.toLowerCase() == 'tab') {
              keyboardFocusNode!.nextFocus();
              return;
            }
            onKeyboardInput!(label);
          }
        },
        child: textField,
      );
    }

    return Container(
      color: theme.colorScheme.surface,
      child: AnimatedContainer(
        duration: kLabelAnimationDuration,
        padding: const EdgeInsetsDirectional.only(
          start: 20,
          end: 12,
        ),
        decoration: BoxDecoration(
          color: isFocused.value
              ? colors?.surfaceSelected
              : colors?.surfacePrimary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: error
                ? theme.colorScheme.error
                : isFocused.value
                    ? colors?.surfaceBorderSelected ?? Colors.transparent
                    : colors?.surfacePrimary ?? Colors.transparent,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, _) => textField,
        ),
      ),
    );
  }
}
