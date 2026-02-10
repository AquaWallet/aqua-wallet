import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaColoredText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final ColoredTextEnum colorType;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool shouldWrap;

  const AquaColoredText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.colorType = ColoredTextEnum.defaultColor,
    this.textAlign = TextAlign.start,
    this.shouldWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return switch (colorType) {
      ColoredTextEnum.defaultColor => _buildDefaultColorText(),
      ColoredTextEnum.coloredIntegers => _buildColoredText(context),
    };
  }

  Widget _buildDefaultColorText() {
    if (shouldWrap) {
      // Lightning text - limit to 3 lines
      return RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(text: text, style: style),
        textAlign: textAlign ?? TextAlign.start,
      );
    } else {
      // Regular text - show everything without wrapping
      return RichText(
        maxLines: null,
        overflow: TextOverflow.visible,
        text: TextSpan(text: text, style: style),
        textAlign: textAlign ?? TextAlign.start,
      );
    }
  }

  Widget _buildColoredText(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final spans = getTextSpansWithColoredIntegers(
      text: text,
      color: color,
    );

    if (shouldWrap) {
      // Lightning text - limit to 3 lines with middle truncation
      return LayoutBuilder(
        builder: (context, constraints) {
          return _buildTruncatedText(constraints, color);
        },
      );
    } else {
      // Regular text - show everything without wrapping
      return RichText(
        maxLines: null,
        overflow: TextOverflow.visible,
        text: TextSpan(children: spans, style: style),
        textAlign: textAlign ?? TextAlign.start,
      );
    }
  }

  bool _textFitsInConstraints(TextSpan textSpan, BoxConstraints constraints) {
    final painter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxLines ?? 1,
    );
    painter.layout(maxWidth: constraints.maxWidth);
    return !painter.didExceedMaxLines;
  }

  Widget _buildTruncatedText(BoxConstraints constraints, Color color) {
    const ellipsis = '…';

    // First, try to show the full text
    if (_textFitsInWidth(text, color, constraints.maxWidth, 3)) {
      final spans = getTextSpansWithColoredIntegers(text: text, color: color);
      return RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(children: spans, style: style),
        textAlign: textAlign ?? TextAlign.start,
      );
    }

    // If it doesn't fit, show beginning and end with ellipsis in middle
    // Start with more characters to show more content
    int bestPrefixLength = 0;
    for (int length = 20; length <= text.length ~/ 2; length += 5) {
      final prefix = text.substring(0, length);
      final suffix = text.substring(text.length - length);
      final testText = '$prefix$ellipsis$suffix';

      if (_textFitsInWidth(testText, color, constraints.maxWidth, 3)) {
        bestPrefixLength = length;
      } else {
        break;
      }
    }

    if (bestPrefixLength == 0) {
      // Fallback: try with smaller increments
      for (int length = 10; length <= text.length ~/ 2; length += 2) {
        final prefix = text.substring(0, length);
        final suffix = text.substring(text.length - length);
        final testText = '$prefix$ellipsis$suffix';

        if (_textFitsInWidth(testText, color, constraints.maxWidth, 3)) {
          bestPrefixLength = length;
        } else {
          break;
        }
      }
    }

    if (bestPrefixLength == 0) {
      return RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(text: ellipsis, style: style),
        textAlign: textAlign ?? TextAlign.start,
      );
    }

    final prefix = text.substring(0, bestPrefixLength);
    final suffix = text.substring(text.length - bestPrefixLength);
    final truncatedText = '$prefix$ellipsis$suffix';
    final spans =
        getTextSpansWithColoredIntegers(text: truncatedText, color: color);

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans, style: style),
      textAlign: textAlign ?? TextAlign.start,
    );
  }

  bool _textFitsInWidth(
      String testText, Color color, double maxWidth, int maxLines) {
    final spans = getTextSpansWithColoredIntegers(
      text: testText,
      color: color,
    );

    final painter = TextPainter(
      text: TextSpan(children: spans, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );
    painter.layout(maxWidth: maxWidth);

    return !painter.didExceedMaxLines && painter.width <= maxWidth;
  }
}

enum ColoredTextEnum {
  defaultColor,
  coloredIntegers,
}
