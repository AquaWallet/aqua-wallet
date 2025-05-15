import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaSeedInputField extends HookWidget {
  const AquaSeedInputField({
    super.key,
    required this.index,
    this.controller,
    this.error = false,
    this.enabled = true,
    this.forceFocus = false,
    this.isValidWord = false,
    this.onChanged,
    this.debounceTime = kDefaultDebounceDuration,
    this.colors,
  });

  final int index;
  final TextEditingController? controller;
  final bool error;
  final bool enabled;
  final bool forceFocus;
  final ValueChanged<String>? onChanged;
  final Duration debounceTime;
  final AquaColors? colors;
  final bool isValidWord;

  static const kLabelAnimationDuration = Duration(milliseconds: 200);
  static const kDefaultDebounceDuration = Duration(milliseconds: 500);

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

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Focus(
        onFocusChange: (focus) {
          if (!forceFocus && enabled) {
            // Only update focus state if not forced and enabled
            isFocused.value = focus;
          }
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          color: theme.colorScheme.surface,
          child: AnimatedContainer(
            duration: kLabelAnimationDuration,
            padding: const EdgeInsetsDirectional.only(
              start: 20,
              end: 12,
              top: 7,
              bottom: 7,
            ),
            decoration: BoxDecoration(
              color: isFocused.value ? colors?.surfaceSelected : null,
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
              builder: (context, _) => TextField(
                controller: controller,
                style: AquaTypography.body1Medium,
                keyboardType: TextInputType.text,
                enabled: enabled,
                minLines: 1,
                maxLines: 1,
                expands: false,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                  labelText: null,
                  isCollapsed: false,
                  hintText: '...',
                  hintStyle: AquaTypography.body1Medium.copyWith(
                    color: colors?.textSecondary,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                  ),
                  prefixIcon: AquaText.body2Medium(
                    text: '$index',
                    color: colors?.textTertiary,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 18,
                    maxWidth: 18,
                    minHeight: 18,
                  ),
                  suffixIcon: isValidWord
                      ? AquaIcon.check(
                          size: 18,
                          color: colors?.accentBrand,
                        )
                      : null,
                ),
                onChanged: (value) {
                  hasText.value = value.isNotEmpty;
                  currentLength.value = value.length;
                  debounceTimer.value?.cancel();
                  debounceTimer.value = Timer(
                    debounceTime,
                    () => onChanged?.call(value),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
