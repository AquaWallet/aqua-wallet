import 'package:flutter/material.dart';

class AquaColoredText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final ColoredTextEnum colorType;

  const AquaColoredText({
    super.key,
    required this.text,
    this.style,
    this.colorType = ColoredTextEnum.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (colorType) {
      case ColoredTextEnum.defaultColor:
        return Text(text, style: style);
      case ColoredTextEnum.coloredIntegers:
        return _ColoredIntegers(text: text, style: style);
    }
  }
}

class _ColoredIntegers extends StatelessWidget {
  const _ColoredIntegers({
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final RegExp numberPattern = RegExp(r'\d+');
    final List<TextSpan> spans = [];
    int lastEnd = 0;

    for (Match m in numberPattern.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: style,
        ));
      }
      spans.add(
        TextSpan(
          text: m.group(0),
          style: (style ?? const TextStyle()).copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }
    return RichText(text: TextSpan(children: spans, style: style));
  }
}

enum ColoredTextEnum {
  defaultColor,
  coloredIntegers,
}
