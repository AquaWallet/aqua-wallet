import 'package:flutter/material.dart';

/// Utility functions for working with [TextSpan]s, especially for
/// highlighting specific patterns (e.g., integers) within a string.
/// Specifically, in AQUA it is used to color code addresses.
List<TextSpan> getTextSpansWithColoredIntegers({
  required String text,
  required Color color,
}) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'\d+');
  var lastEnd = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(0),
        style: TextStyle(color: color),
      ),
    );
    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(TextSpan(text: text.substring(lastEnd)));
  }

  return spans;
}
