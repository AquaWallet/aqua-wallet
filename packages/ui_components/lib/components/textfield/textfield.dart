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
    this.focusNode,
    this.labelStyle,
    this.textStyle = AquaTypography.body1,
    this.trailingIcon,
    this.onTrailingTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.assistiveText,
    this.assistiveTextStyle,
    this.assistiveTextColor,
    this.labelTextColor,
    this.error = false,
    this.enabled = true,
    this.forceFocus = false,
    this.transparentBorder = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.showClearInputButton = false,
    this.counterStyle,
    this.counterTextColor,
    this.onChanged,
    this.debounceTime = kDefaultDebounceDuration,
  });

  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextStyle? labelStyle;
  final TextStyle textStyle;
  final Widget? trailingIcon;
  final bool showClearInputButton;
  final VoidCallback? onTrailingTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? assistiveText;
  final TextStyle? assistiveTextStyle;
  final Color? labelTextColor;
  final Color? assistiveTextColor;
  final bool error;
  final bool enabled;
  final bool forceFocus;
  final bool transparentBorder;
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
    // Track actual measured text height instead of line count for accuracy
    final measuredTextHeight = useState(minLines * kLineHeight);
    final isMultiline = maxLines > 1 || minLines > 1;
    final theme = Theme.of(context);

    // Calculate actual horizontal padding for accurate text measurement
    final rightPadding = switch (null) {
      _ when (trailingIcon != null && showClearInputButton) =>
        kTrailingIconPadding * 2,
      _ when (trailingIcon != null || showClearInputButton) =>
        kTrailingIconPadding,
      _ => kContentTrailingPadding,
    };
    final totalHorizontalPadding = kContentHorizontalPadding + rightPadding;

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

    // Initialize text height based on existing text in controller
    useEffect(() {
      if (controller?.text.isNotEmpty == true && isMultiline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateTextHeight(
            controller!.text,
            measuredTextHeight,
            minLines,
            maxLines,
            (context.size?.width ?? kEstimatedTextWidth) -
                totalHorizontalPadding,
          );
        });
      }
      return null;
    }, [controller?.text, minLines, maxLines]);

    final labelColor = error && !isMultiline
        ? theme.colorScheme.error
        : labelTextColor ?? theme.hintColor;

    // Calculate additional space needed for the label when active
    final hasActiveLabel = label != null && (isFocused.value || hasText.value);
    final labelOffset = hasActiveLabel ? kLabelOffsetWhenActive : 0.0;

    // Calculate minimum height for multiline inputs
    // Use kContentVerticalPadding * 2 for actual content padding (top + bottom)
    final contentPadding = kContentVerticalPadding * 2;
    final minTextHeight = minLines * kLineHeight;
    final multilineMinHeight = isMultiline && minLines == 1
        ? math.max(
            kTextfieldHeight, minTextHeight + contentPadding + labelOffset)
        : minTextHeight + contentPadding + labelOffset;

    // Calculate the container height using actual measured text height
    final containerHeight = isMultiline
        ? math.max(
            multilineMinHeight,
            measuredTextHeight.value + contentPadding + labelOffset,
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
                          ? (transparentBorder
                              ? Colors.transparent
                              : theme.colorScheme.primary)
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
                  //ANCHOR - Label
                  if (label != null) ...{
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
                  },

                  //ANCHOR - TextField
                  Positioned.fill(
                    top: (label != null && (isFocused.value || hasText.value))
                        ? kLabelOffsetWhenActive
                        : 0,
                    child: LayoutBuilder(
                      builder: (context, constraints) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        cursorColor: theme.colorScheme.primary,
                        style: textStyle,
                        obscureText: obscureText,
                        keyboardType: keyboardType ??
                            (isMultiline ? TextInputType.multiline : null),
                        textInputAction: textInputAction,
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
                            switch (null) {
                              _
                                  when (trailingIcon != null &&
                                      showClearInputButton) =>
                                kTrailingIconPadding * 2,
                              _
                                  when (trailingIcon != null ||
                                      showClearInputButton) =>
                                kTrailingIconPadding,
                              _ => kContentTrailingPadding,
                            },
                            kContentVerticalPadding,
                          ),
                          isDense: true,
                          labelText: null,
                          isCollapsed: false,
                        ),
                        onChanged: (value) {
                          hasText.value = value.isNotEmpty;
                          currentLength.value = value.length;

                          // Calculate the actual text height based on content
                          if (isMultiline) {
                            _updateTextHeight(
                              value,
                              measuredTextHeight,
                              minLines,
                              maxLines,
                              constraints.maxWidth - totalHorizontalPadding,
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

                  if (showClearInputButton || trailingIcon != null) ...{
                    Positioned(
                      right: kTrailingIconRightPosition,
                      top: 0,
                      bottom: 0,
                      child: Row(
                        children: [
                          if (showClearInputButton && hasText.value) ...{
                            //ANCHOR - Clear Input Button
                            Center(
                              child: _ClearInputButton(
                                onClearInputTap: () {
                                  controller?.clear();
                                  measuredTextHeight.value =
                                      minLines * kLineHeight;
                                  onChanged?.call('');
                                },
                                theme: theme,
                              ),
                            ),
                          },
                          if (showClearInputButton && trailingIcon != null) ...{
                            const SizedBox(width: 14),
                          },
                          if (trailingIcon != null) ...{
                            //ANCHOR - Trailing Widget
                            Center(
                              child: GestureDetector(
                                onTap: enabled ? onTrailingTap : null,
                                child: trailingIcon,
                              ),
                            ),
                          },
                        ],
                      ),
                    ),
                  },
                ],
              ),
            ),
          ),

          //ANCHOR - Assistive Text and Counter
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

  /// Helper method to update the measured text height based on text content
  void _updateTextHeight(
    String text,
    ValueNotifier<double> measuredTextHeight,
    int minLines,
    int maxLines,
    double availableWidth,
  ) {
    final minHeight = minLines * kLineHeight;

    if (text.isEmpty) {
      if (measuredTextHeight.value != minHeight) {
        measuredTextHeight.value = minHeight;
      }
      return;
    }

    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );

    textPainter.layout(maxWidth: availableWidth);

    // Use actual measured height from TextPainter
    final actualHeight = textPainter.height;

    // Ensure height is at least minHeight
    final newHeight = math.max(minHeight, actualHeight);

    if (measuredTextHeight.value != newHeight) {
      measuredTextHeight.value = newHeight;
    }
  }
}

class _ClearInputButton extends StatelessWidget {
  const _ClearInputButton({
    required this.onClearInputTap,
    required this.theme,
  });

  final VoidCallback? onClearInputTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onClearInputTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onClearInputTap!())
            : null,
        borderRadius: BorderRadius.circular(100),
        splashFactory: InkRipple.splashFactory,
        child: Ink(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: theme.colorScheme.outline,
          ),
          child: SizedBox.square(
            dimension: 14,
            child: AquaIcon.close(
              size: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
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
        //ANCHOR - Assistive Text
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
        //ANCHOR - Character Counter
        if (shouldShowCounter) ...{
          const Spacer(),
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
