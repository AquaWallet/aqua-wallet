import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// A [TextEditingController] that builds a [TextSpan] with colored integers.
///
/// Use this controller to display text in a [TextField] where integer substrings
/// are highlighted with the theme's primary color. Non-integer text remains unstyled.
///
/// See also:
///   - [getTextSpansWithColoredIntegers], which performs the actual span coloring.
class ColorCodedTextEditingController extends TextEditingController {
  ColorCodedTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = getTextSpansWithColoredIntegers(
      text: text,
      color: Theme.of(context).colorScheme.primary,
    );

    return TextSpan(style: style, children: spans);
  }
}
