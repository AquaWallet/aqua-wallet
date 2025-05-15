import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaTextField extends HookWidget {
  const AquaTextField({
    super.key,
    this.label,
    this.controller,
    this.labelStyle,
    this.textStyle,
    this.trailingIcon,
    this.onTrailingTap,
    this.obscureText = false,
    this.keyboardType,
    this.assistiveText,
    this.assistiveTextStyle,
    this.assistiveTextColor,
    this.labelTextColor,
    this.error = false,
    this.enabled = true,
    this.forceFocus = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.counterStyle,
    this.counterTextColor,
    this.onChanged,
    this.debounceTime = kDefaultDebounceDuration,
  });

  final String? label;
  final TextEditingController? controller;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final Widget? trailingIcon;
  final VoidCallback? onTrailingTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? assistiveText;
  final TextStyle? assistiveTextStyle;
  final Color? labelTextColor;
  final Color? assistiveTextColor;
  final bool error;
  final bool enabled;
  final bool forceFocus;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final TextStyle? counterStyle;
  final Color? counterTextColor;
  final ValueChanged<String>? onChanged;
  final Duration debounceTime;

  static const kLabelAnimationDuration = Duration(milliseconds: 200);
  static const kLineHeight = 24.0;
  static const kPadding = 16.0;
  static const kTextfieldHeight = kLineHeight + (kPadding * 2);
  static const kLabelTopPositionWhenActive = 12.0;
  static const kLabelLeftPosition = 16.0;
  static const kLabelTopPositionMultiline = 16.0;
  static const kLabelOffsetWhenActive = 16.0;
  static const kTrailingIconRightPosition = 16.0;
  static const kContentHorizontalPadding = 16.0;
  static const kContentVerticalPadding = 8.0;
  static const kTrailingIconPadding = 40.0;
  static const kContentTrailingPadding = 12.0;
  static const kAssistiveTextTopPadding = 4.0;
  static const kEstimatedTextWidth = 300.0;
  static const kBorderRadius = 8.0;
  static const kTextMeasurementPadding = 32.0;
  static const kDefaultDebounceDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final isFocused = useState(forceFocus);
    final hasText = useState(controller?.text.isNotEmpty ?? false);
    final currentLength = useState(controller?.text.length ?? 0);
    final currentLines = useState(minLines);
    final isMultiline = maxLines > 1 || minLines > 1;
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

    // Initialize currentLines based on existing text in controller
    useEffect(() {
      if (controller?.text.isNotEmpty == true && isMultiline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateLineCount(
            controller!.text,
            currentLines,
            textStyle ?? AquaTypography.body1,
            minLines,
            maxLines,
            kEstimatedTextWidth,
          );
        });
      }
      return null;
    }, [controller, minLines, maxLines]);

    final labelColor = error && !isMultiline
        ? theme.colorScheme.error
        : labelTextColor ?? theme.hintColor;

    // Calculate additional space needed for the label when active
    final labelOffset = (label != null && (isFocused.value || hasText.value))
        ? kLabelOffsetWhenActive
        : 0.0;

    // Calculate minimum height for multiline inputs
    final multilineMinHeight = isMultiline && minLines == 1
        ? math.max(
            kTextfieldHeight, minLines * kLineHeight + kPadding + labelOffset)
        : minLines * kLineHeight + kPadding + labelOffset;

    // Calculate the container height
    final containerHeight = isMultiline
        ? math.max(
            multilineMinHeight,
            currentLines.value * kLineHeight + kPadding + labelOffset,
          )
        : kTextfieldHeight;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: (focus) {
              if (!forceFocus && enabled) {
                // Only update focus state if not forced and enabled
                isFocused.value = focus;
              }
            },
            child: AnimatedContainer(
              duration: kLabelAnimationDuration,
              height: containerHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(
                  color: error
                      ? theme.colorScheme.error
                      : isFocused.value
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Label
                  if (label != null)
                    AnimatedPositioned(
                      duration: kLabelAnimationDuration,
                      left: kLabelLeftPosition,
                      top: (isFocused.value || hasText.value)
                          ? kLabelTopPositionWhenActive
                          : isMultiline
                              ? kLabelTopPositionMultiline
                              : (kTextfieldHeight - kLineHeight) / 2,
                      child: AnimatedDefaultTextStyle(
                        duration: kLabelAnimationDuration,
                        style: (isFocused.value || hasText.value)
                            ? labelStyle ??
                                AquaTypography.caption2SemiBold.copyWith(
                                  color: labelColor,
                                )
                            : labelStyle ??
                                AquaTypography.body1.copyWith(
                                  color: labelColor,
                                ),
                        child: Text(label!),
                      ),
                    ),

                  // TextField
                  Positioned.fill(
                    top: (label != null && (isFocused.value || hasText.value))
                        ? kLabelOffsetWhenActive
                        : 0,
                    child: LayoutBuilder(
                      builder: (context, constraints) => TextField(
                        controller: controller,
                        cursorColor: theme.colorScheme.primary,
                        style: textStyle ?? AquaTypography.body1,
                        obscureText: obscureText,
                        keyboardType: keyboardType ??
                            (isMultiline ? TextInputType.multiline : null),
                        enabled: enabled,
                        minLines: null,
                        maxLines: null,
                        expands: false,
                        maxLength: maxLength,
                        // Hide the built-in counter
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.fromLTRB(
                            kContentHorizontalPadding,
                            kContentVerticalPadding,
                            trailingIcon != null
                                ? kTrailingIconPadding
                                : kContentTrailingPadding,
                            kContentVerticalPadding,
                          ),
                          isDense: true,
                          labelText: null,
                          isCollapsed: false,
                        ),
                        onChanged: (value) {
                          hasText.value = value.isNotEmpty;
                          currentLength.value = value.length;

                          // Calculate the number of lines based on text content
                          if (isMultiline) {
                            _updateLineCount(
                              value,
                              currentLines,
                              textStyle ?? AquaTypography.body1,
                              minLines,
                              maxLines,
                              constraints.maxWidth - kTextMeasurementPadding,
                            );
                          }

                          debounceTimer.value?.cancel();
                          debounceTimer.value = Timer(
                            debounceTime,
                            () => onChanged?.call(value),
                          );
                        },
                      ),
                    ),
                  ),

                  // Trailing Widget
                  if (trailingIcon != null)
                    Positioned(
                      right: kTrailingIconRightPosition,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: enabled ? onTrailingTap : null,
                          child: trailingIcon,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Assistive Text and Counter
          if (assistiveText != null || showCounter) ...{
            const SizedBox(height: kAssistiveTextTopPadding),
            _AssistiveText(
              error: error,
              maxLength: maxLength,
              currentLength: currentLength,
              assistiveText: assistiveText,
              assistiveTextStyle: assistiveTextStyle,
              assistiveTextColor: assistiveTextColor,
              shouldShowCounter: showCounter,
              counterStyle: counterStyle,
              counterTextColor: counterTextColor,
            ),
          },
        ],
      ),
    );
  }

  /// Helper method to update the line count based on text content
  void _updateLineCount(
    String value,
    ValueNotifier<int> currentLines,
    TextStyle textStyle,
    int minLines,
    int maxLines,
    double availableWidth,
  ) {
    final textSpan = TextSpan(
      text: value,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );

    textPainter.layout(maxWidth: availableWidth);

    // Get the number of lines (minimum of minLines)
    final calculatedLines =
        value.isEmpty ? minLines : textPainter.computeLineMetrics().length;

    final newLines = calculatedLines < minLines
        ? minLines
        : calculatedLines > maxLines
            ? maxLines
            : calculatedLines;

    if (currentLines.value != newLines) {
      currentLines.value = newLines;
    }
  }
}

class _AssistiveText extends StatelessWidget {
  const _AssistiveText({
    required this.assistiveText,
    required this.error,
    required this.assistiveTextStyle,
    required this.assistiveTextColor,
    required this.shouldShowCounter,
    required this.currentLength,
    required this.maxLength,
    required this.counterStyle,
    required this.counterTextColor,
  });

  final String? assistiveText;
  final bool error;
  final Color? assistiveTextColor;
  final TextStyle? assistiveTextStyle;
  final bool shouldShowCounter;
  final ValueNotifier<int> currentLength;
  final int? maxLength;
  final TextStyle? counterStyle;
  final Color? counterTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Assistive Text
        if (assistiveText != null) ...{
          Expanded(
            child: Text(
              assistiveText!,
              style: error
                  ? AquaTypography.caption1Medium.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )
                  : assistiveTextStyle ??
                      AquaTypography.caption1Medium.copyWith(
                        color:
                            assistiveTextColor ?? Theme.of(context).hintColor,
                      ),
            ),
          )
        },
        const Spacer(),
        // Character Counter
        if (shouldShowCounter) ...{
          Text(
            '${currentLength.value}/$maxLength',
            style: counterStyle ??
                AquaTypography.caption1Medium.copyWith(
                  color: counterTextColor ?? Theme.of(context).hintColor,
                ),
          ),
        }
      ],
    );
  }
}
